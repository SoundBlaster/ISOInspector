# Traversal Guard Requirements (T1.7)

## Purpose

Define the forward-progress and depth-guard rules that keep the tolerant parse
pipeline from hanging or exhausting resources while still surfacing as much box
structure as possible. These requirements extend the binary reader clamps from
T1.6 so lenient traversal can recover from corrupt size fields, overlapping
ranges, and adversarial fixtures without regressing strict-mode behaviour.

## Guard Catalogue

### 1. Forward Progress Budget

- **Minimum advance per iteration:** each loop over `StreamingBoxWalker` must
  increase the active frame cursor by **≥ 4 bytes** (the smallest legal MP4 box
  header) or by the remaining range if fewer than four bytes remain. When the
  decoder cannot advance by this budget, record a `ParseIssue` and apply the
  recovery action below.
- **Stalled-iteration threshold:** tolerate up to **3 stalled iterations per
  frame** to accommodate a single corrupt header retry (e.g., fuzzed `uuid`
  types). On the third stall, emit `guard.no_progress` and seek to the frame's
  upper bound before continuing with the parent.
- **Recovery action:** when a stall is detected, advance the cursor to the next
  byte after the attempted header start if enough space remains; otherwise jump
  to `frame.range.upperBound` to prevent loops. Traversal then resumes at the
  parent scope.

### 2. Zero-Length Box Handling

- **Definition:** treat a box as "zero-length" when `header.range.count ==
  header.headerLength` and it does not expose children.
- **Retry limit:** allow up to **2 zero-length boxes per parent** to preserve
  compatibility with known malformed fixtures that pad trailing sentinels.
  After the second event, emit `guard.zero_size_loop`, skip the node's payload,
  and continue at the parent cursor.
- **Reasoning:** corrupted streams that duplicate zero-size atoms (observed in
  the tolerant parsing spike) otherwise cause endless replays of the same
  offset. The limit aligns with fixture expectations for duplicated `free`
  padding blocks while blocking adversarial floods.

### 3. Recursion Depth Cap

- **Maximum depth:** cap the traversal stack at **64 levels**. If decoding a new
  box would exceed this depth, emit `guard.recursion_depth_exceeded`, close the
  current frame, and resume at its parent.
- **Rationale:** healthy ISO BMFF hierarchies remain under 12 levels (e.g.,
  `moov → trak → mdia → minf → stbl`). A 64-level cap leaves 5× headroom for
  pathological but finite trees while preventing stack blowups triggered by
  cyclic offsets or fuzzed headers.

### 4. Cursor Backtracking Fence

- **Rule:** forbid child headers from starting before the current frame cursor.
  When `decodedHeader.startOffset < frame.cursor`, emit
  `guard.cursor_regression`, clamp to the cursor, and skip the payload.
- **Purpose:** overlapping child ranges observed during fuzz testing previously
  caused sibling cycles. The guard ensures monotonic traversal and preserves the
  invariant enforced by E2 progress detection.

### 5. Corruption Burst Budget

- **Per-frame allowance:** tolerate up to **256 emitted issues per frame**
  before triggering `guard.issue_budget_exceeded`. When the budget is exceeded,
  mark the node as corrupt, skip remaining bytes, and resume with the parent.
- **Justification:** prevents attacker-controlled files from allocating
  unbounded `ParseIssue` arrays while still capturing representative diagnostics
  for downstream consumers.

## ParseIssue Contract

| Code                            | Severity | Trigger                                           | Metadata                                                         |
|---------------------------------|----------|---------------------------------------------------|------------------------------------------------------------------|
| `guard.no_progress`             | error    | Cursor failed to advance by ≥4 bytes after 3 tries | `byteRange` = attempted header slice; `affectedNodeIDs` = parent. |
| `guard.zero_size_loop`          | warning  | More than two zero-length boxes under one parent   | `byteRange` = offending header; attaches to parent node.         |
| `guard.recursion_depth_exceeded`| error    | Depth would exceed 64 levels                       | `byteRange` = frame range; `affectedNodeIDs` = ancestor chain.   |
| `guard.cursor_regression`       | error    | Child header started before current cursor         | `byteRange` = overlapping range; `affectedNodeIDs` = parent node.|
| `guard.issue_budget_exceeded`   | warning  | >256 issues emitted for a single frame             | `byteRange` = residual frame bytes; marks node as `partial`.     |

- **Message format:** Follow "actionable first" guidance, e.g.,
  "Traversal stalled at offset 0x1A2C: forcing jump to parent boundary." Include
  hex-formatted offsets and mention recovery behaviour.
- **Aggregation:** `ParsePipeline` must surface guard violations alongside
  decoder issues so CLI/UI consumers display them in summaries and detail views.
- **Options surface:** extend `ParsePipeline.Options` with:
  - `maxTraversalDepth: Int = 64`
  - `maxStalledIterationsPerFrame: Int = 3`
  - `maxZeroLengthBoxesPerParent: Int = 2`
  - `maxIssuesPerFrame: Int = 256`
  Downstream callers can override values for fuzzing but the defaults ship above.

## Acceptance Plan

| Scenario | Fixture / Harness | Expectation |
|----------|-------------------|-------------|
| Zero-size flood | Synthetic fixture `zero-size-loop.mp4` (to be added under `Fixtures/Corrupt/`) | Lenient parse completes; emits exactly two `guard.zero_size_loop` issues; traversal continues with siblings. |
| Overlapping children | `overlapping-boxes.mp4` corrupt sample (existing tolerant spike asset) | Parse emits `guard.cursor_regression`, skips offending payload, and resumes without hang. |
| Depth overflow | Fuzz harness generating nested `uuid` containers | Third-party fuzz run triggers `guard.recursion_depth_exceeded`; traversal finishes with parent tree intact. |
| Issue budget exhaustion | CLI fuzz harness injecting thousands of invalid samples per node | `guard.issue_budget_exceeded` fires once per saturated node; total runtime < 2× strict baseline. |
| Regression | `swift test --filter StreamingBoxWalkerTests` plus new guard-focused cases | Tests assert cursor never regresses, tolerant mode stays responsive, and strict mode still traps on first error. |

Additional verification:

1. Extend tolerant parsing integration tests to assert `ParseTreeNode.status`
   transitions to `.partial` when guard issues fire.
2. Add CLI snapshot covering a guard-triggered parse so summaries show guard
   counts in the corruption ribbon.
3. Record guard activations via debug logging (category `TraversalGuard`) so
   telemetry can later track frequency without requiring reproduction.

## Follow-Up Tasks

- Implement guard logic inside `StreamingBoxWalker` respecting the thresholds
  above and ensure strict mode remains unchanged.
- Generate corrupt fixtures (`zero-size-loop.mp4`, nested `uuid` corpus) and add
  them to `Tests/ISOInspectorKitTests/Fixtures/catalog.json`.
- Extend CLI/app issue renderers to map new guard codes to localized copy and
  badge icons.
- Wire traversal guard metrics into the tolerant parsing dashboard documented in
  `IntegrationSummary.md` so QA can track guard hit rates across fuzz runs.
