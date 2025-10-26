# Corrupted Media Tolerance — Integration Summary

## Purpose

This document catalogs how **Corrupted Media Tolerance** integrates with ISOInspector's existing architecture, detailing component modifications, interface contracts, and migration strategies to ensure a smooth rollout without regressing current functionality.

**Target Audience:** Implementation engineers, code reviewers, release managers
**Last Updated:** 2025-10-23

---

## Integration Overview

Corrupted Media Tolerance introduces **lenient parsing mode** alongside the existing **strict mode**, requiring changes across the parse pipeline, validation layer, UI, CLI, and export modules. The integration strategy prioritizes:

1. **Backward Compatibility:** Strict mode behavior unchanged; lenient mode opt-in.
2. **Incremental Delivery:** Feature flag guards experimental paths until GA.
3. **Minimal Surface Area:** Extend existing types rather than duplicating logic.

---

## Component Integration Map

### Core Parsing Pipeline

#### 1. `BoxHeaderDecoder`

**Location:** `Sources/ISOInspectorKit/Core/BoxHeaderDecoder.swift`

**Current Behavior:**
```swift
func decode(at offset: Int64, reader: RandomAccessReader) throws -> BoxHeader
```
Throws `BoxHeaderDecodingError` on:
- `invalidSize`
- `exceedsParent`
- `ioError`

**Tolerance Integration:**
```swift
func decode(at offset: Int64, reader: RandomAccessReader) -> Result<BoxHeader, BoxHeaderDecodingError>
```

**Migration Strategy:**
- Refactor to return `Result` instead of throwing (T1.4).
- Update all callsites in `StreamingBoxWalker.walk(_:cancellationCheck:onEvent:onFinish:)` to handle `.failure` case.
- In **strict mode**: unwrap result with `try result.get()` (preserves existing behavior).
- In **lenient mode**: match on `.failure`, attach `ParseIssue`, skip to next sibling.

**Verification:**
- Unit tests for decoder covering all error cases.
- Integration test: strict mode still throws; lenient mode continues.

**Risk:** Medium — requires refactoring all decoder callsites. Mitigation: compiler enforces exhaustive handling.

---

#### 2. `StreamingBoxWalker.walk`

**Location:** `Sources/ISOInspectorKit/ISO/StreamingBoxWalker.swift`

**Current Behavior:**
```swift
func walk(reader: RandomAccessReader, cancellationCheck: CancellationCheck, onEvent: EventHandler, onFinish: FinishHandler) throws
```
Iterates children; throws on first decoder error; halts parsing.

**Tolerance Integration:**
```swift
func walk(reader: RandomAccessReader, cancellationCheck: CancellationCheck, options: ParsePipeline.Options, onEvent: EventHandler, onIssue: (ParseIssue) -> Void, onFinish: FinishHandler) throws
```

**Changes:**
1. Accept `options` parameter to check `abortOnStructuralError`.
2. Track `currentOffset` and `furthestOffset` to detect progress loops (integrates E2 guards).
3. On decoder `.failure`:
   - If **strict mode**: throw error (existing behavior).
   - If **lenient mode**:
     - Create `ParseIssue` with byte range and reason code via `onIssue`.
     - Seek to `currentOffset + estimatedSkipSize` or `parentRange.upperBound` (whichever is closer).
     - Continue iteration to next sibling.
4. Enforce `maxCorruptionEvents` cap; stop emitting issues beyond threshold (log warning).

**Verification:**
- Regression test: strict mode on corrupt fixture throws as before.
- New test: lenient mode on same fixture completes; returns partial tree + issues.

**Risk:** High — core logic change. Mitigation: extensive fuzzing (T5.5), golden-file tests (T5.2).

---

#### 3. `ParseTreeNode`

**Location:** `Sources/ISOInspectorKit/Models/ParseTreeNode.swift`

**Current Schema:**
```swift
struct ParseTreeNode: Codable {
    let header: BoxHeader
    let children: [ParseTreeNode]
    let payload: BoxPayload?
}
```

**Tolerance Integration:**
```swift
struct ParseTreeNode: Codable {
    let header: BoxHeader
    let children: [ParseTreeNode]
    let payload: BoxPayload?

    // New fields
    let issues: [ParseIssue]        // Empty array if no issues
    let status: NodeStatus          // valid | partial | corrupt | skipped

    enum NodeStatus: String, Codable {
        case valid      // Parsed without issues
        case partial    // Some fields missing/truncated
        case corrupt    // Structural error detected
        case skipped    // Intentionally skipped (e.g., unknown type)
    }
}
```

**Migration Strategy:**
- Add fields as **optional** in initial rollout to maintain JSON schema compatibility.
- Version JSON export schema to `v2` (T4.1); `v1` consumers ignore new fields.
- Default `issues` to empty array, `status` to `.valid` for healthy nodes.

**Verification:**
- JSON export test: `v2` schema includes new fields; `v1` export omits them.
- Decoder test: `v1` JSON imports successfully (ignores unknown keys).

**Risk:** Low — additive change; backward compatible.

---

### Validation Layer

#### 4. Validation Rules (VR-001 to VR-015)

**Location:** `Sources/ISOInspectorKit/Validation/*.swift`

**Current Behavior:**
Each rule throws on validation failure:
```swift
func validate(node: BoxNode, context: ValidationContext) throws
```

**Tolerance Integration:**
Add mode-aware behavior:
```swift
func validate(node: BoxNode, context: ValidationContext) {
    guard checkCondition() else {
        let issue = ParseIssue(
            severity: .error,
            code: "VR-001",
            message: "Box size exceeds parent boundary",
            range: node.header.payloadRange
        )

        if context.options.abortOnStructuralError {
            throw ValidationError(issue: issue)
        } else {
            context.issueStore.record(issue)
        }
        return
    }
}
```

**Changes:**
1. Add `ValidationContext.issueStore: ParseIssueStore` property.
2. Check `context.options.abortOnStructuralError` before throwing.
3. In lenient mode: record issue and return; in strict mode: throw.

**Migration Strategy:**
- Extract shared logic into `ValidationContext.handleIssue(_:)` helper.
- Refactor all 15 rules to use helper (T2.4).

**Verification:**
- Per-rule unit test: strict mode throws; lenient mode records issue.
- Integration test: full parse with all rules enabled in both modes.

**Risk:** Medium — repetitive refactor across 15 rules. Mitigation: helper function + code review.

---

#### 5. `ParseIssueStore`

**Location:** `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift` (new)

**Purpose:** Aggregate corruption events during parsing; provide query APIs.

**Interface:**
```swift
class ParseIssueStore: ObservableObject {
    @Published private(set) var issues: [ParseIssue] = []
    @Published private(set) var metrics: IssueMetrics

    func record(_ issue: ParseIssue)
    func issues(forNode nodeID: String) -> [ParseIssue]
    func issues(inRange range: Range<Int64>) -> [ParseIssue]
    func metricsSnapshot() -> IssueMetrics  // Counts by severity, deepest depth
    func makeIssueSummary() -> IssueSummary // DTO for CLI/UI summaries
}

struct IssueMetrics {
    let countsBySeverity: [ParseIssue.Severity: Int]
    let deepestAffectedDepth: Int
    var totalCount: Int { get }
    func count(for severity: ParseIssue.Severity) -> Int
}

struct IssueSummary {
    let metrics: IssueMetrics
    let totalCount: Int
}
```

**Integration Points:**
- **ParsePipeline:** Passes store to `ValidationContext` during parse.
- **UI (Combine Bridge):** Observes `@Published issues` via `@ObservedObject`.
- **Export:** Queries store to populate JSON `issues` array.

**Verification:**
- Unit test: record issues; query by node/range; verify metrics.
- UI test: trigger parse; confirm SwiftUI view updates on issue emission.

**Risk:** Low — new component; no dependencies on legacy code.

---

### User Interface

#### 6. `AppShellView` (Document Load Flow)

**Location:** `Sources/ISOInspector/Views/AppShellView.swift`

**Current Behavior:**
- On parse failure: displays blocking error banner; no tree rendered.

**Tolerance Integration:**
- On parse completion (even with issues):
  - Render tree view with partial results.
  - Display **non-modal warning ribbon** at top summarizing corruption counts (T3.1).
  - Banner shows: "⚠️ 12 errors, 5 warnings — View Integrity Report" (tappable → jumps to Integrity tab).
  - Banner dismissible; preference to hide on future loads.

**Changes:**
```swift
@StateObject var issueStore: ParseIssueStore

var body: some View {
    VStack(spacing: 0) {
        if issueStore.metrics().errorCount > 0 {
            CorruptionWarningRibbon(metrics: issueStore.metrics())
        }
        // Existing tree/detail/hex layout
    }
}
```

**Verification:**
- SwiftUI preview: render with mock issues; verify ribbon appearance.
- Accessibility audit: VoiceOver announces warning ribbon.

**Risk:** Low — additive UI; existing layout unaffected.

---

#### 7. `OutlineView` (Tree Rendering)

**Location:** `Sources/ISOInspector/Views/OutlineView.swift`

**Current Behavior:**
- Renders tree nodes with fourcc, size, offset.
- Validation warnings shown as yellow badge (existing VR-001 to VR-015 warnings).

**Tolerance Integration:**
- Add **corruption badge** (warning triangle icon) for nodes with `issues.isEmpty == false` (T3.2).
- Badge color-coded by severity: red (error), yellow (warning), blue (info).
- Tooltip on hover shows top issue summary.
- VoiceOver label: "moov box, 1 error: child exceeds parent boundary".

**Changes:**
```swift
HStack {
    Text(node.header.fourcc)
    if !node.issues.isEmpty {
        CorruptionBadge(issues: node.issues)
    }
}
```

**Verification:**
- SwiftUI preview: nodes with issues display badge.
- UI automation test: filter corrupt nodes; verify badge presence.

**Risk:** Low — leverages existing badge system.

---

#### 8. `DetailView` (Inspector Pane)

**Location:** `Sources/ISOInspector/Views/DetailView.swift`

**Current Behavior:**
- Displays parsed fields, validation results.

**Tolerance Integration:**
- Add **"Corruption" section** when `node.issues.isEmpty == false` (T3.3). ✅ Completed — see `DOCS/TASK_ARCHIVE/188_T3_3_Integrity_Detail_Pane/Summary_of_Work.md` for implementation details:
  - List each issue with severity icon, error code, message.
  - Show byte offsets and affected range length.
  - Suggest actions (e.g., "View in hex editor", "Export diagnostics").
  - All text copyable.

**Changes:**
```swift
if !node.issues.isEmpty {
    Section(header: Text("Corruption")) {
        ForEach(node.issues) { issue in
            CorruptionIssueRow(issue: issue, onJumpToHex: { ... })
        }
    }
}
```

**Verification:**
- SwiftUI preview: detail view with corrupt node.
- Accessibility audit: issue rows readable by VoiceOver.

**Risk:** Low — new section; existing sections unchanged.

---

#### 9. Placeholder Nodes (T3.4)

**Purpose:** Render missing required children (e.g., `stbl` absent from `minf`).

**Implementation:**
- During parsing: if container validation detects missing required child, create synthetic `ParseTreeNode`:
  ```swift
  let placeholder = ParseTreeNode(
      header: BoxHeader(type: "stbl", size: 0, offset: -1),
      children: [],
      payload: nil,
      issues: [ParseIssue(severity: .error, code: "MISSING_REQUIRED", message: "Expected but absent")],
      status: .corrupt
  )
  ```
- UI renders placeholder with italic fourcc, grayed-out, badge with issue.

**Verification:**
- Test fixture: `minf` missing `stbl`; verify placeholder appears in tree.
- UI test: selecting placeholder shows "Missing Required Child" message.

**Risk:** Medium — requires parser to know required children. Mitigation: metadata-driven via MP4RA catalog.

---

#### 10. Integrity Summary Tab (T3.6)

**Location:** `Sources/ISOInspector/Views/IntegritySummaryView.swift` (new)

**Purpose:** Aggregate all issues across file; sortable/filterable list.

**Interface:**
- Tab in main view alongside Tree/Detail/Hex.
- Table columns: Severity | Code | Message | Offset | Affected Node | Actions
- Sort by: severity (default), offset, node.
- Filter by: severity level.
- Export button: save as JSON or plaintext.

**Integration:**
- Observes `ParseIssueStore.issues`.
- Selecting row navigates to affected node in tree view.

**Verification:**
- UI automation test: open corrupt file; switch to Integrity tab; verify issue count.
- Export test: export JSON; validate schema.

**Risk:** Low — new view; no dependencies on existing views.

---

### Export Layer

#### 11. JSON Export Schema (T4.1)

**Current Schema (v1):**
```json
{
  "type": "ISOInspector.Tree",
  "version": 1,
  "file": { "name": "example.mp4", "length": 123456 },
  "root": { "fourcc": "root", "children": [...] }
}
```

**Tolerance Schema (v2):**
```json
{
  "type": "ISOInspector.Tree",
  "version": 2,
  "file": {
    "name": "example.mp4",
    "length": 123456,
    "sha256": "abc123...",
    "analysisTimestamp": "2025-10-23T12:34:56Z"
  },
  "root": {
    "fourcc": "root",
    "children": [...],
    "issues": [
      {
        "severity": "error",
        "code": "VR-001",
        "message": "Box size exceeds parent",
        "offset": 1024,
        "length": 512
      }
    ],
    "status": "partial"
  }
}
```

**Migration:**
- Encoder checks `ParsePipeline.Options.exportSchemaVersion`.
- Default to `v2` for new exports; CLI flag `--export-schema v1` for compatibility.

**Verification:**
- Snapshot test: corrupt fixture exports match golden `v2` schema.
- Backward compat test: `v1` export omits new fields.

**Risk:** Low — schema evolution; versioned.

---

#### 12. Plaintext Export (T4.2)

**Purpose:** Human-readable issue report for logs/tickets.

**Format:**
```
ISOInspector Corruption Report
File: corrupted.mp4
Size: 1,234,567 bytes
SHA-256: abc123...
Analyzed: 2025-10-23 12:34:56 UTC

Summary:
  Errors: 12
  Warnings: 5
  Info: 3

Issues:
  [ERROR] VR-001 at offset 0x400 (1024): Box size exceeds parent boundary
    Affected: moov/trak[0]/mdia
    Action: Verify muxer output; check for truncation.

  [WARNING] VR-003 at offset 0x1A00 (6656): Unusual box ordering
    Affected: Root container
    Action: Consider reordering ftyp before moov.
```

**Integration:**
- Share menu: "Export Integrity Report" → saves as `.txt`.
- CLI: `iso-inspector-cli analyze --tolerant --export-issues report.txt`.

**Verification:**
- Golden-file test: compare output against expected plaintext.

**Risk:** Low — new export format; no dependencies.

---

### CLI Integration

#### 13. CLI Argument Parsing (T6.1)

**Current Flags:**
- `--preset <name>` (validation preset)
- `--export <file>` (JSON export)

**New Flags:**
```
--tolerant               Enable lenient parsing (default: strict)
--strict                 Enforce strict mode (halt on first error)
--max-corruption-events  Cap issue count (default: 10000)
--export-issues <file>   Export issue summary (JSON or .txt)
```

**Default Behavior:**
- **Interactive CLI:** lenient mode (better UX for exploratory analysis).
- **CI/Scripting:** strict mode (fail fast for validation pipelines).
- Detection: check if stdout is TTY; override via explicit flag.

**Verification:**
- CLI smoke test: `iso-inspector-cli analyze --tolerant corrupt.mp4` completes with summary.
- Regression test: `iso-inspector-cli analyze --strict corrupt.mp4` exits with error code 1.

**Risk:** Low — additive flags; existing behavior unchanged.

---

#### 14. CLI Output Formatting (T6.2)

**Current Output:**
```
Parsing: example.mp4
Boxes: 42
Duration: 120.5s
Validation: 2 warnings
```

**Tolerance Output:**
```
Parsing: corrupted.mp4 (lenient mode)
Boxes: 38 (4 skipped due to errors)
Duration: 95.2s (partial)
Corruption Summary:
  Errors: 12
  Warnings: 5
  Info: 3
Deepest affected depth: 4

Top Issues:
  [ERROR] VR-001: Box size exceeds parent (moov/trak[0]/mdia)
  [ERROR] MISSING_REQUIRED: stbl box absent (moov/trak[0]/mdia/minf)

Export full report: iso-inspector-cli ... --export-issues report.json
```

**Verification:**
- Snapshot test: CLI output matches expected format.

**Risk:** Low — extends existing formatter.

---

## Configuration & Feature Flags

### Feature Flag Strategy (Sprint 1-5)

**Flag Name:** `TOLERANCE_PARSING_ENABLED`

**Location:** `Sources/ISOInspectorKit/FeatureFlags.swift`
```swift
enum FeatureFlags {
    static let toleranceParsingEnabled = true  // Toggle during development
}
```

**Guarded Code Paths:**
- `ParsePipeline.live(...)`: check flag before enabling lenient mode.
- UI corruption views: hide if flag disabled.

**Removal:** Sprint 6 (GA) — delete flag; lenient mode always available.

---

### User Preferences

**New Settings:**
- **Parsing Mode:** Strict | Lenient (default: Lenient for app, Strict for CLI)
- **Max Corruption Events:** 1000 | 10000 | Unlimited
- **Show Corruption Badges:** On | Off (accessibility toggle)

**Storage:** `UserDefaults` → `ParsePipelinePreferences` Codable struct.

**UI:** macOS Settings scene, iOS/iPadOS in-app settings.

---

## Testing Strategy

### Unit Tests

| Component | Test Coverage | Tools |
|-----------|---------------|-------|
| `ParseIssue` | Initialization, Codable | XCTest |
| `ParseIssueStore` | Record, query, metrics | XCTest |
| `BoxHeaderDecoder` (Result-based) | All error cases in both modes | XCTest |
| Validation rules (dual-mode) | Each rule in strict + lenient | XCTest |

### Integration Tests

| Scenario | Verification | Fixtures |
|----------|--------------|----------|
| Strict mode on corrupt file | Throws as before | `truncated.mp4` |
| Lenient mode on corrupt file | Completes with partial tree + issues | `truncated.mp4`, `overlapping.mp4` |
| JSON export schema v2 | Includes issues and status | All corrupt fixtures |
| CLI tolerant mode | Prints corruption summary | `broken_stco.mp4` |

### UI Tests

| View | Test | Automation |
|------|------|------------|
| Warning ribbon | Appears when issues present | SwiftUI preview |
| Corruption badge | Displayed on affected nodes | UI automation |
| Integrity tab | Lists all issues; export works | UI automation |
| Placeholder nodes | Render with "Missing Required" label | SwiftUI preview |

### Performance Tests (T5.4)

- **Baseline:** `large_file_1GB.mp4` (healthy) in strict mode.
- **Variant:** Same file with injected corruption in lenient mode.
- **Metrics:** Parse time, peak memory, issue count.
- **Pass Criteria:** Lenient ≤ 1.2× baseline; memory delta ≤ 50 MB.

### Fuzzing Tests (T5.5)

- **Corpus:** 100 synthetic corrupt files (random sizes, overlaps, truncations).
- **Runner:** `swift-format` or custom fuzzer.
- **Pass Criteria:** 99.9% complete without crashes; remaining 0.1% log deterministic errors.

---

## Migration & Rollout Plan

### Sprint 1-2: Prototype (Feature Flag ON, Internal Only)

1. Implement T1.1-T1.7 (core parsing resiliency).
2. Add corrupt fixture corpus (T5.1).
3. Run regression tests; verify strict mode unaffected.
4. Internal demo: parse truncated file; show partial tree.

**Exit Criteria:** Lenient pipeline parses ≥5 corrupt fixtures without crashes.

---

### Sprint 3: Alpha (Internal Build, QC Stakeholders)

1. Implement T3.1-T3.7 (UI corruption views).
2. Add T4.1-T4.4 (diagnostics export).
3. Deploy to QC team; gather feedback on UI affordances.

**Exit Criteria:** QC team successfully exports issue report for 3 real-world corrupt files.

---

### Sprint 4-5: Beta (External Beta, Preferences Toggle)

1. Implement T6.1-T6.4 (CLI parity).
2. Add user preference toggle (default: lenient for app, strict for CLI).
3. Deploy to beta testers; monitor logs for regressions.

**Exit Criteria:** No P0 bugs; performance benchmark passes (T5.4).

---

### Sprint 6: GA (Default Lenient, Feature Flag Removed)

1. Make lenient mode default for app; strict mode in advanced preferences.
2. Remove feature flag; delete guarded code paths.
3. Update documentation (user manual, release notes).

**Exit Criteria:** Public release; crash-free sessions ≥99.9%; user satisfaction ≥4/5.

---

### Post-Launch: Telemetry & Iteration

1. Collect opt-in telemetry on corruption event frequency.
2. Refine heuristics for placeholder creation (address open question #2).
3. Iterate on issue labels based on localization feedback (open question #3).

**Cadence:** Quarterly review; issue catalog updates as needed.

---

## Risk Mitigation Checklist

- [ ] Regression test suite covers strict mode on all existing fixtures (no failures).
- [ ] Lenient mode completes ≥95% of corrupt fixtures (T5.2).
- [ ] Performance benchmark gate enforced in CI (T5.4).
- [ ] Fuzzing harness achieves 99.9% crash-free rate (T5.5).
- [ ] UI affordances reviewed by accessibility team (color contrast, VoiceOver labels).
- [ ] JSON schema versioning validated with backward compatibility test.
- [ ] CLI default mode detection (TTY check) tested on macOS/Linux.
- [ ] Privacy audit confirms no payload bytes in exports (T4.4).

---

## Cross-References

- **PRD:** [`CorruptedMediaTolerancePRD.md`](./CorruptedMediaTolerancePRD.md)
- **TODO/Workplan:** [`TODO.md`](./TODO.md)
- **Feature Analysis:** [`FeatureAnalysis.md`](./FeatureAnalysis.md)
- **Main Project TODO:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../ISOViewer/ISOInspector_PRD_TODO.md)
- **Validation Infrastructure:** [`DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`](../../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/)
