# Corrupted Media Tolerance — Feature Analysis

## Executive Summary

**Corrupted Media Tolerance** represents a paradigm shift in ISOInspector's error handling philosophy: from "detect errors and halt" to "detect, record, and continue." This feature transforms ISOInspector into a forensic-grade tool capable of extracting maximum structural information from damaged media while maintaining explicit corruption signaling.

**Status:** Planning Phase
**Target Release:** Sprint 6 (General Availability)
**Dependencies:** Builds on existing validation infrastructure (VR-001 to VR-015, Task B7)

---

## Relationship to Existing Work

### Foundational Components (Reused)

1. **Validation Rules Infrastructure (VR-001 to VR-015)**
   - **Location:** `Sources/ISOInspectorKit/Validation/`
   - **Current Behavior:** Throws errors on structural violations (strict mode)
   - **Tolerance Integration:** Convert to produce `ParseIssue` objects in lenient mode
   - **Impact:** Low — validation logic remains; only error propagation changes

2. **Validation Configuration (Task B7)**
   - **Archive:** `DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`
   - **Current Behavior:** Enables/disables validation rules via presets
   - **Tolerance Integration:** Add tolerance level (`strict`/`lenient`) as new configuration dimension
   - **Impact:** Medium — extends existing config model; no breaking changes

3. **BoxParser & ParsePipeline**
   - **Location:** `Sources/ISOInspectorKit/Core/BoxParser.swift`
   - **Current Behavior:** Throws on decoder errors; halts parsing
   - **Tolerance Integration:** Refactor decoder to return `Result<BoxHeader, Error>`; handle failures gracefully
   - **Impact:** High — core architectural change requiring extensive testing

4. **JSON Export (Task B6)**
   - **Archive:** `DOCS/TASK_ARCHIVE/28_B6_JSON_and_Binary_Export_Modules/`
   - **Current Behavior:** Exports valid tree structure
   - **Tolerance Integration:** Extend schema to include `issues` and `status` fields per node
   - **Impact:** Medium — schema evolution with backward compatibility

5. **UI State Management (Task G7)**
   - **Archive:** `DOCS/TASK_ARCHIVE/154_G7_State_Management_ViewModels/`
   - **Current Behavior:** Surfaces parse tree and validation results
   - **Tolerance Integration:** Add `ParseIssueStore` observer; render corruption badges and placeholders
   - **Impact:** Medium — new UI components; existing views extend cleanly

### Components NOT Duplicated

| Existing Feature | Overlap? | Decision |
|------------------|----------|----------|
| **E1: Parent Containment Validation** | Detects same errors | **COMPLEMENT** — E1 provides detection; Tolerance adds continuation logic. |
| **E2: Progress Loop Guards** | Prevents hangs | **INTEGRATE** — Guards remain critical in lenient mode to prevent infinite loops on malformed sizes. |
| **VR-006: Research Logging** | Records unknown boxes | **ORTHOGONAL** — VR-006 logs unknowns; Tolerance records structural corruption. Both coexist. |
| **Validation Rule Toggles** | Disables checks | **DISTINCT** — Toggles skip rules; Tolerance runs rules but continues on failure. |

**Conclusion:** No duplication detected. Tolerance Parsing is a **new capability** that enhances existing validation rather than replacing it.

---

## Novelty Assessment

### What Makes This Feature Novel?

1. **Non-Fatal Error Handling:**
   - Existing: Parsing stops at first structural error.
   - New: Parsing continues; errors recorded as `ParseIssue` annotations.

2. **Partial Tree Rendering:**
   - Existing: Failed parse returns empty tree or error banner.
   - New: UI displays partial tree with corruption badges, placeholders for missing children.

3. **Forensic Diagnostics:**
   - Existing: Generic error messages ("failed to parse").
   - New: Detailed issue catalog with byte offsets, severity, suggested actions, exportable reports.

4. **Configurable Tolerance Levels:**
   - Existing: Single strict mode; validation toggles are binary (on/off).
   - New: Lenient mode as separate parsing strategy with bounded resource usage (max depth, max corruption events).

### Competitive Positioning

| Tool | Tolerant Parsing | Corruption Annotations | Export Diagnostics |
|------|------------------|------------------------|---------------------|
| **ffprobe** | ✅ Yes (continues on NAL errors) | ⚠️ Logs only | ⚠️ JSON includes warnings |
| **Bento4 (mp4info)** | ⚠️ Partial (skips `mdat`) | ❌ No structured issues | ❌ No issue export |
| **ISOInspector (current)** | ❌ Halts on errors | ✅ VR-001 to VR-015 | ✅ JSON validation results |
| **ISOInspector (with Tolerance)** | ✅ Lenient mode | ✅ ParseIssue with byte ranges | ✅ JSON/text exports |

**Competitive Gap Closed:** Matches `ffprobe` resilience while exceeding its diagnostics detail.

---

## User Impact Analysis

### Personas & Scenarios (from PRD)

1. **QC Operator (Broadcast Delivery Verification)**
   - **Before:** Cannot inspect truncated uploads; falls back to hex editor.
   - **After:** Opens file in ISOInspector; sees partial tree with "mdat truncated at offset 0x1A4B2000"; exports issue report for delivery team.
   - **Benefit:** Faster triage; actionable diagnostics.

2. **Streaming SRE (CDN Corruption Investigation)**
   - **Before:** `ffprobe` shows warnings but lacks byte-level detail; manual hex analysis required.
   - **After:** ISOInspector displays broken `stco` with "chunk offset 0x9FFFFFFF exceeds file size"; exports JSON for ticket.
   - **Benefit:** Precise root cause; reduced MTTR.

3. **Video Engineer (Muxing Pipeline Debugging)**
   - **Before:** Parser crashes on malformed edit list; no insight into which segment fails.
   - **After:** Sees edit list with "segment 3: media_time -1 (invalid)"; compares expected vs. actual in tree view.
   - **Benefit:** Pinpoints muxer bug; avoids blind trial-and-error.

### UX Requirements Translation

| PRD Requirement | Implementation | Verification |
|-----------------|----------------|--------------|
| Non-modal warning ribbon | `T3.1` (banner with corruption counts) | UI smoke test |
| Corruption badges in tree | `T3.2` (warning triangle icon + tooltip) | SwiftUI preview |
| Details pane "Corruption" section | `T3.3` (error code, offsets, actions) | Accessibility audit |
| Placeholder nodes | `T3.4` (expected fourcc, issue attachment) | Regression test |
| Global integrity summary | `T3.6` (tab with sortable issues) | UI automation test |

---

## Technical Architecture Impact

### New Components

1. **`ParseIssue` Model**
   - **Purpose:** Structured corruption event (severity, offsets, reason codes)
   - **Location:** `Sources/ISOInspectorKit/Validation/ParseIssue.swift`
   - **Dependencies:** None (standalone)
   - **Effort:** 1 day (T1.1)

2. **`ParseIssueStore` Aggregate**
   - **Purpose:** Accumulate and query issues during streaming parse
   - **Location:** `Sources/ISOInspectorKit/Stores/ParseIssueStore.swift`
   - **Dependencies:** `ParseIssue`, Combine (for UI updates)
   - **Effort:** 1.5 days (T2.1)

3. **Corruption UI Components**
   - **Purpose:** Badges, placeholders, integrity tab
   - **Location:** `Sources/ISOInspector/Views/Corruption/`
   - **Dependencies:** SwiftUI, `ParseIssueStore`
   - **Effort:** 7 days (T3.1-T3.7)

### Modified Components

1. **`BoxHeaderDecoder`**
   - **Change:** Return `Result<BoxHeader, Error>` instead of throwing
   - **Impact:** All callsites must handle `.failure` case
   - **Risk:** Medium — requires careful refactor to avoid silent failures
   - **Mitigation:** Comprehensive unit tests (T5.2)

2. **`BoxParser.parseContainer()`**
   - **Change:** Catch decoder errors, attach issues, continue to next sibling
   - **Impact:** Container iteration logic becomes stateful (tracks furthest offset)
   - **Risk:** High — subtle bugs could cause data loss or hangs
   - **Mitigation:** Progress guards (T1.7), fuzzing tests (T5.5)

3. **`ParseTreeNode`**
   - **Change:** Add `issues: [ParseIssue]` and `status: NodeStatus`
   - **Impact:** JSON schema version bump; UI bindings update
   - **Risk:** Low — additive change; backward compatible via optional fields
   - **Mitigation:** Schema versioning (T4.1)

4. **Validation Rules**
   - **Change:** Check `ParsePipeline.Options.abortOnStructuralError`; emit issue vs. throw
   - **Impact:** All 15 validation rules need dual-mode support
   - **Risk:** Medium — inconsistent behavior if some rules forget to check mode
   - **Mitigation:** Shared `ValidationContext` helper (T2.4)

---

## Performance Considerations

### Budget (from PRD)

- **Latency:** Lenient mode ≤ 1.2× strict mode on 1 GB reference file
- **Memory:** No unbounded growth; cap corruption events (`maxCorruptionEvents`)
- **Crash-Free Sessions:** ≥99.9% on corrupt fixture suite

### Overhead Sources

1. **Issue Allocation:** Each corruption event allocates `ParseIssue` struct
   - **Mitigation:** Pool/reuse issues; batch insertions into store

2. **Traversal Backtracking:** Seeking to next sibling after failed parse
   - **Mitigation:** Use parent boundary math; avoid redundant reads

3. **UI Updates:** Corruption badge rendering for large trees
   - **Mitigation:** Lazy rendering; badge icon cached

### Benchmark Plan (T5.4)

- **Baseline:** Current strict mode on `Fixtures/large_file_1GB.mp4`
- **Variant:** Lenient mode on same file (injected with synthetic corruption)
- **Metrics:** Parse time, peak memory, issue count
- **Pass Criteria:** Lenient ≤ 1.2× baseline; memory delta ≤ 50 MB

---

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Regression in strict mode** | Medium | High | Maintain separate code paths; gate with options check; regression test suite. |
| **Silent data loss** | Medium | Critical | Extensive testing with corrupt fixtures; golden-file exports for known patterns. |
| **Infinite loops on malformed input** | Low | Critical | Retain progress/depth guards from E2; fuzz testing (T5.5). |
| **User misinterprets partial tree as valid** | Medium | High | Unmistakable UI affordances (color, badges, warning ribbon); "Corrupted" status label. |
| **Performance degradation on healthy files** | Medium | Medium | Benchmark gate (T5.4); optimize hot paths; cap issue event emission. |
| **Localization issues with labels** | Low | Low | Defer to beta feedback (Sprint 4-5); iterate on labels. |

---

## Integration Summary

### Phase-by-Phase Integration Points

| Phase | Integrates With | Integration Type | Risk |
|-------|-----------------|------------------|------|
| **T1 (Parsing Resiliency)** | `BoxParser`, `BoxHeaderDecoder` | **Refactor** (Result-based errors) | High |
| **T2 (Issue Recording)** | `ParsePipeline`, Combine bridge | **Extend** (new event stream) | Medium |
| **T3 (UI Representation)** | `AppShellView`, `OutlineView`, `DetailView` | **Extend** (new views/badges) | Low |
| **T4 (Diagnostics Export)** | JSON export, Share menu | **Extend** (schema + menu) | Low |
| **T5 (Testing)** | Existing test harness, fixtures | **Augment** (corrupt fixtures) | Low |
| **T6 (CLI Parity)** | CLI argument parser, output formatters | **Extend** (new flag/summary) | Low |

### Backward Compatibility

- **Strict Mode:** Remains default for CLI; lenient mode opt-in via `--tolerant` flag.
- **JSON Schema:** Version bump to `v2`; `v1` consumers ignore new fields (graceful degradation).
- **UI Preferences:** New toggle in advanced preferences; defaults to lenient for app (user override supported).

---

## Success Metrics (from PRD)

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Coverage** | ≥95% of corrupt fixtures parse to completion | Automated test suite (T5.2) |
| **User Satisfaction** | ≥4/5 on "ability to inspect damaged files" | Post-release survey (Sprint 6+) |
| **Crash-Free Sessions** | 99.9% across corrupt fixture suite | Fuzzing harness (T5.5) + telemetry (post-launch) |
| **Performance** | Lenient mode ≤1.2× strict mode on 1 GB file | Benchmark gate (T5.4) |

---

## Open Questions & Resolutions

### From PRD

1. **Batching large corruption clusters:**
   - **Question:** How to summarize thousands of broken samples without hiding detail?
   - **Status:** Open — defer to Sprint 3 QC feedback
   - **Tracking:** `TODO.md` Open Questions section

2. **Placeholder creation heuristics:**
   - **Question:** When to auto-create placeholder nodes vs. grouping missing siblings into parent-level issue?
   - **Status:** Open — prototype in Sprint 2
   - **Tracking:** Implementation note in T3.4

3. **Localization validation:**
   - **Question:** Are issue labels clear for Russian- and English-speaking operators?
   - **Status:** Open — beta feedback in Sprint 4-5
   - **Tracking:** `TODO.md` Open Questions section

4. **Telemetry safeguards:**
   - **Question:** Do offset ranges leak sensitive metadata?
   - **Status:** Resolved — no payload bytes exported (T4.4); only byte ranges and issue codes
   - **Verification:** Privacy audit in Sprint 3

---

## Next Steps

1. **Immediate:** Update main PRD (`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`) to reference Tolerance Parsing TODO.
2. **Sprint 1 Entry:** Begin T1.1 (Define `ParseIssue` model) — kickoff planning session.
3. **Stakeholder Review:** Share this analysis with QC operators for early feedback on UI mockups.
4. **Fixture Acquisition:** Start T5.1 (corrupt fixture corpus) in parallel with core development.

---

## Cross-References

- **PRD:** [`CorruptedMediaTolerancePRD.md`](./CorruptedMediaTolerancePRD.md)
- **TODO/Workplan:** [`TODO.md`](./TODO.md)
- **Main Project TODO:** [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../ISOViewer/ISOInspector_PRD_TODO.md)
- **Related Archives:**
  - E1: [`DOCS/TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/`](../../TASK_ARCHIVE/159_E1_Enforce_Parent_Containment_and_Non_Overlap/)
  - E2: [`DOCS/TASK_ARCHIVE/163_E2_Detect_Progress_Loops/`](../../TASK_ARCHIVE/163_E2_Detect_Progress_Loops/)
  - B7: [`DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/`](../../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/)
