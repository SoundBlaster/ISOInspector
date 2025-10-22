# Corrupted Media Tolerance PRD

## Revision History
- **Author:** ChatGPT (OpenAI assistant)
- **Created:** 2025-10-22
- **Status:** Draft

## Context
ISO Inspector is positioned as a forensic-grade analyzer for ISO BMFF (MP4/QuickTime) assets. Current behaviour aborts parsing when `BoxHeaderDecoder` detects structural inconsistencies (for example, `BoxHeaderDecodingError.exceedsParent`). This conservative approach protects users from inaccurate trees but prevents the primary user goal: examining damaged or partially downloaded media.

Stakeholders (video engineers, post-production QC operators, and streaming delivery SREs) have stated that their top priority is extracting as much structural information as possible from malformed files. Competitive tools such as `ffprobe` continue scanning despite malformed NAL units, annotating warnings instead of failing hard. We must match or exceed this resiliency while preserving clear signalling of questionable data.

## Problem Statement
Users cannot inspect corrupted media in ISO Inspector because the app halts on the first parsing error. As a result, they fall back to hex editors or command-line utilities that provide partial insight. This gap blocks adoption and undermines the product's value proposition of «разобрать каждый элемент, молекулу и атом» (inspect every element, molecule, and atom).

## Goals
1. **Best-effort structural inspection:** Continue parsing MP4/QuickTime files even after encountering recoverable corruption, surfacing as much of the box tree, sample tables, and metadata as technically feasible.
2. **Explicit corruption signalling:** Clearly flag unreliable regions so users understand which nodes, samples, or payloads may be inaccurate.
3. **Actionable diagnostics:** Provide guidance (warnings, error summaries, exportable logs) that pinpoints corruption type, offset, and potential remediation steps.
4. **No catastrophic failures:** The UI must remain responsive; the pipeline should isolate parsing faults, preventing crashes or hangs even on severely damaged inputs.

## Non-Goals
- Performing automatic file repair or rewriting damaged segments.
- Supporting container formats outside ISO BMFF scope (e.g., Matroska).
- Guaranteeing correctness of payload-level codecs (e.g., decoding AVC bitstreams beyond structural validation).
- Building a full hex editor inside the app.

## Target Users and Scenarios
### Personas
- **QC Operator:** Verifies delivery packages before broadcast. Needs to understand which segments fail integrity checks and why.
- **Streaming SRE:** Investigates customer-reported playback failures. Requires quick insight into truncated uploads or CDN corruption.
- **Video Engineer:** Debugs muxing pipelines. Compares expected vs. actual box layouts and sample metadata.

### Critical Scenarios
1. **Truncated upload:** File ends mid-`mdat`. Tool should display all successfully parsed boxes, flag the truncated `mdat`, and continue rendering sample tables up to the available data.
2. **Invalid size fields:** A `trak` child declares a size exceeding its parent. Parser should warn, clamp traversal to the parent boundary, and mark the offending node as corrupt while continuing with siblings.
3. **Corrupted sample table entry:** `stsz` contains negative or zero sizes. UI should highlight the rows, continue showing valid rows, and add a diagnostic summary.
4. **Broken chunk offsets:** `stco` references data beyond file end. Parser should annotate the affected samples, but still surface accessible samples.
5. **Malformed edit list:** Non-monotonic edit segments. UI should render the edit list with validation warnings instead of aborting.

## User Experience Requirements
- **Banner vs. inspector:** Replace the blocking load-failure banner with a non-modal warning ribbon summarizing corruption counts while still opening the document view.
- **Corruption badges:** Tree view nodes show an icon (e.g., warning triangle) with tooltip detailing the issue and byte range.
- **Details pane:** When selecting a corrupt node, the inspector panel displays a "Corruption" section containing:
  - Error code and message.
  - Byte offsets and affected range length.
  - Suggested follow-up actions.
- **Global summary:** Provide an "Integrity" tab aggregating all findings, sortable by severity, with export to text/JSON.
- **Copyable diagnostics:** Ensure all warning texts are selectable and copyable.

## Functional Requirements
1. **Parsing Pipeline Resiliency**
   - Introduce configurable tolerance levels (e.g., strict, lenient). Default to lenient for interactive app.
   - Catch `BoxHeaderDecodingError` and related validation faults; attach them to the current traversal context while continuing to the next sibling/child when safe.
   - Maintain traversal state even if a node's payload is skipped due to invalid size; propagate context to downstream consumers.
2. **Corruption Recording**
   - Extend parse events to include severity (`error`, `warning`, `info`), byte offsets, and reason codes.
   - Persist events in `ParseTreeStore`, keyed by node identifier, with optional attachment to ranges in binary payload.
   - Aggregate metrics (count per severity, deepest affected depth) for UI summaries.
3. **UI Representation**
   - Display partial trees with corruption badges; differentiate between "partial" and "omitted" children.
   - Provide filters to show/hide corrupt nodes or jump between them.
   - Update status bar with real-time progress and corruption count during parsing.
4. **Diagnostics Export**
   - Support exporting all corruption events to JSON and plaintext via the Share menu.
   - Include file metadata (size, hash, analysis timestamp) in exports.
5. **Performance & Reliability**
   - Ensure lenient parsing does not degrade performance by more than 20% on healthy files (baseline: current strict mode).
   - Guarantee that catastrophic corruption (e.g., random data) does not cause infinite loops or unbounded memory usage; impose traversal guards.
6. **Testing & Tooling**
   - Add fixture corpus with known corrupt patterns (truncated boxes, overlapping boxes, invalid tables).
   - Provide regression tests verifying continued traversal, warning generation, and UI rendering of corrupt nodes.
   - Include golden-file expectations for diagnostics exports.

## Technical Considerations
- **Configuration Surface:** Add `ParsePipeline.Options` with toggles for `abortOnStructuralError`, `maxCorruptionEvents`, and `payloadValidationLevel`.
- **Error Propagation:** Convert thrown errors into structured `ParseIssue` objects. For unrecoverable errors (e.g., I/O failures), retain existing abort behaviour.
- **Tree Model Changes:** `ParseTreeNode` should store `issues: [ParseIssue]` and a `status: enum { valid, partial, corrupt, skipped }`.
- **Binary Reader Guards:** When sizes exceed parent boundaries, clamp reads to available bytes, record a `truncatedPayload` issue, and seek to `parentEnd` before continuing.
- **UI Architecture:** Update SwiftUI views to observe new `ParseIssueStore`, using environment objects or bindings already present in `AppShellView`.
- **Logging:** Emit structured logs mirroring UI issues for CLI/Console diagnostics.

## Dependencies & Risks
- **Regression Risk:** Altering traversal logic could hide genuine inconsistencies if tolerance is overly permissive. Mitigate via default warning severity and explicit metadata on clamped reads.
- **Complexity:** Handling every corruption path increases code complexity; modularize issue handling helpers to avoid duplicated logic.
- **User Trust:** Must avoid presenting corrupt data as valid. UI needs unmistakable affordances (color, icons, text) to communicate uncertainty.
- **Performance:** Additional bookkeeping may slow parsing. Profile with large, valid files to ensure acceptable overhead.

## Success Metrics
- **Coverage:** Percentage of corrupt fixtures where parsing completes and displays partial tree (target ≥ 95%).
- **User Satisfaction:** Post-release survey rating ≥ 4/5 on "ability to inspect damaged files".
- **Crash-Free Sessions:** Maintain 99.9% crash-free rate across corrupt fixture test suite.
- **Performance:** Lenient mode parsing time ≤ 1.2× strict mode on 1 GB reference file.

## Rollout Plan
1. **Prototype (Sprint 1-2):** Implement lenient pipeline path behind feature flag, run against fixture corpus, gather metrics.
2. **Alpha (Sprint 3):** Enable in internal builds, collect feedback from QC stakeholders, iterate on UI signals.
3. **Beta (Sprint 4-5):** Ship to select power users with toggle in preferences; monitor logs for regressions.
4. **General Availability (Sprint 6):** Make lenient mode default, keep strict mode accessible via advanced preferences.
5. **Post-Launch:** Gather telemetry (opt-in) on corruption event frequency; refine heuristics and diagnostics catalog.

## Open Questions
- How should we prioritise nested corruption events (e.g., dozens of invalid samples) without overwhelming the UI? Consider grouping or collapsing repeated issues.
- What terminology resonates most with target users? "Partial", "Corrupt", or localized equivalents may need UX research.
- Should exports include binary snippets around corrupt offsets for offline analysis? Security implications must be reviewed.
- Do we need CLI parity (e.g., `iso-inspector-cli --tolerant`)? If yes, add requirements for command-line UX.

