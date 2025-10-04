# ISOInspector Product Requirements

## Feature Overview & Rationale
ISOInspector enables engineers and media technologists to introspect ISO BMFF (MP4/QuickTime) files through automated parsing, validation, and visualization. The system improves debugging velocity, ensures compliance with ISO/IEC 14496-12, and exposes extended box metadata via the MP4RA registry. Delivering both CLI and GUI interfaces ensures compatibility with automated workflows and manual inspection sessions.

## Functional Requirements
| ID | Component | Requirement | Acceptance Criteria |
|----|-----------|-------------|---------------------|
| FR-CORE-001 | ISOInspectorCore | Parse MP4 files via streaming I/O without loading entire file into memory. | Parsing 20 GB test fixture completes with peak memory <100 MB; event stream delivered incrementally. |
| FR-CORE-002 | ISOInspectorCore | Validate box structure, size fields, and hierarchical relationships according to ISO/IEC 14496-12. | Malformed fixtures produce error reports identifying offending box offsets and reasons. |
| FR-CORE-003 | ISOInspectorCore | Catalog recognized atom types using MP4RA registry metadata. | Known box types include name, description, version, and flags; unknown types flagged for research. |
| FR-CORE-004 | ISOInspectorCore | Export parse results as JSON and binary capture for reproducibility. | CLI/UI trigger exports; resulting files round-trip with re-import verification. |
| FR-UI-001 | ISOInspectorUI | Display hierarchical tree of boxes with search, filter, and expand/collapse controls. | Tree view updates in <200 ms upon new event; filter reduces nodes accordingly. |
| FR-UI-002 | ISOInspectorUI | Provide detail pane with field-level metadata, hex viewer, and validation status. | Selecting a box populates metadata and hex window with highlighted ranges. |
| FR-UI-003 | ISOInspectorUI | Support session bookmarking and annotations stored per file. | Users can add notes per box; data persists between launches via CoreData/JSON. |
| FR-CLI-001 | ISOInspectorCLI | Offer commands `inspect`, `validate`, `export-json`, `export-report`. | Commands documented via `--help`; exit codes 0 success, >0 failure. |
| FR-CLI-002 | ISOInspectorCLI | Support batch mode for inspecting multiple files with aggregated summary. | Provide table summarizing file size, box count, error count; output saved to CSV. |
| FR-APP-001 | ISOInspectorApp | Integrate document browser, recent files, and workspace persistence. | App relaunch shows last session, including open files and notes. |
| FR-DOC-001 | Documentation Suite | Provide onboarding guide, API reference, and troubleshooting steps. | README, DocC catalog, and FAQ published with cross-links. |

## Non-Functional Requirements
| ID | Category | Requirement | Validation |
|----|----------|-------------|-----------|
| NFR-PERF-001 | Performance | UI updates within 200 ms of parser event receipt. | Instrumentation using signposts verifies latency on reference hardware. |
| NFR-PERF-002 | Performance | CLI completes validation of 4 GB reference file in <45 seconds on M2 Mac mini. | Automated performance test with benchmark fixture. |
| NFR-RELI-001 | Reliability | Parser handles truncated or corrupted input without crashing. | Fuzz tests and malformed fixture suite run in CI. |
| NFR-USAB-001 | Usability | UI supports VoiceOver and Dynamic Type accessibility. | Audit with Accessibility Inspector; automated UI tests verify labels. |
| NFR-SEC-001 | Security | No network access required; sandboxed file access only. | Static analysis ensures absence of network calls; App Sandbox entitlements configured. |
| NFR-MAINT-001 | Maintainability | 90% unit test code coverage across core modules. | CI coverage report threshold enforced. |
| NFR-DOC-001 | Documentation | Docs updated with every release. | CI check ensures versioned docs changed when public API changes detected. |

## User Interaction Flows
### Flow 1 — GUI Inspection Session
1. User launches ISOInspectorApp.
2. App presents onboarding or recent files list.
3. User selects or imports MP4 file via file picker.
4. ISOInspectorCore streams parse events to ISOInspectorUI.
5. Tree view populates incrementally; status banner indicates progress.
6. User selects a box to view metadata and hex payload.
7. User adds annotations, bookmarks boxes, or exports JSON report.
8. Session metadata persists automatically for next launch.

### Flow 2 — CLI Batch Validation
1. User runs `isoinspector validate --input /path/*.mp4 --report summary.csv`.
2. CLI expands glob, sequentially parses each file using core library.
3. Validation results aggregated; summary table printed and stored.
4. Exit code reflects aggregate success/failure for CI integration.

### Flow 3 — Developer Extends Box Metadata
1. Developer consults MP4RA registry ([link](https://mp4ra.org/registered-types/boxes)) for new atom types.
2. Developer updates box catalog definitions in core module.
3. Unit tests verify parser recognizes new type and populates metadata.
4. Documentation updated to list new box support.

## Edge Cases & Failure Scenarios
| Scenario | Expected Handling |
|----------|------------------|
| File truncated mid-box | Parser emits error event with byte offset; UI highlights offending node; CLI exits with code 2. |
| Box size field smaller than header | Parser reports malformed size, skips to next sync boundary, continues with warning. |
| Unknown extended type | Parser registers entry under "Unknown" with raw type code; TODO created in `05_Research_Gaps.md`. |
| Encrypted payload boxes | Parser records presence but does not attempt decryption; UI indicates restricted payload. |
| Multi-gigabyte `mdat` box | Streaming chunk reader bypasses loading entire payload; UI exposes summary instead of raw hex. |
| Concurrent file analysis sessions | Core library supports multiple parser instances with isolated state; UI displays progress per session. |

## Compliance & Accessibility
- Conform to ISO/IEC 14496-12 structural definitions and validation invariants.
- Provide localization-ready strings with base English resources.
- Ensure CLI output uses ASCII-compatible formatting for CI logs.
- Enable keyboard navigation for all interactive UI components.
