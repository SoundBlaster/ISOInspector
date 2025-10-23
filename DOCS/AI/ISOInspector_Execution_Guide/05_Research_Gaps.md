# ISOInspector Research & Investigation Tasks

This log enumerates knowledge gaps and research activities required to ensure comprehensive coverage. Assign these tasks to investigation agents prior to implementation if prerequisites are missing.

## Open Research Tasks
| Task ID | Topic | Objective | Priority | Effort (days) | Dependencies | Research Approach | Acceptance Criteria |
|---------|-------|-----------|----------|---------------|--------------|-------------------|---------------------|
| R5 | Export Schema Standardization | Research industry-standard JSON schemas for MP4 inspection reports. | Medium | 1.5 | B6 | Survey existing tools (Bento4, ffprobe) for report formats; evaluate compatibility. | ✅ Recommendation archived in `DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/R5_Export_Schema_Standardization.md`, with summary and verification follow-ups noted in `DOCS/TASK_ARCHIVE/151_R5_Export_Schema_Standardization/Summary_of_Work.md`. |
| R6 | Annotation Persistence Strategy | Evaluate CoreData vs. JSON for cross-platform annotation storage. | Low | 1 | C4 | Review storage requirements, conflict resolution needs, and iCloud sync options. | Decision record outlining chosen storage mechanism with rationale. | ✅ CoreData selected; see `DOCS/INPROGRESS/C4_CoreData_Annotation_Persistence.md` |
| R7 | CLI Distribution | Investigate best practices for distributing signed CLI binaries for macOS and Linux. _(In Progress — see `DOCS/INPROGRESS/R7_CLI_Distribution_Strategy.md`.)_ | Low | 1.5 | D3 | Review notarization, Homebrew tap creation, and Linux package formats. | Distribution plan covering signing, packaging, and update strategy. |

> **Completed:** R4 – Large File Performance Benchmarks. See `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/R4_Large_File_Performance_Benchmarks.md` for the benchmark charter and fixture protocol.

## Completed Research

- **R4 — Large File Performance Benchmarks (2025-10-20):** Documented large-file benchmark scenarios, fixture acquisition strategy, tooling matrix, and mitigation plan in `DOCS/TASK_ARCHIVE/93_R4_Large_File_Performance_Benchmarks/R4_Large_File_Performance_Benchmarks.md`; follow-up macOS hardware runs remain blocked.
- **R3 — Accessibility Guidelines (2025-10-19):** Consolidated VoiceOver, Dynamic Type, and keyboard navigation guidance for tree, detail, and hex surfaces. Reference <doc:AccessibilityGuidelines> and the archival summary in `DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md` for verification notes and follow-up puzzles.
- **R2 — Fixture Acquisition (2025-10-18):** Cataloged public and vendor MP4 sources with licensing, storage sizing, and ingestion workflow captured in `DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/R2_Fixture_Acquisition.md`; outcome summarized in `DOCS/TASK_ARCHIVE/84_R2_Fixture_Acquisition/Summary_of_Work.md`.
- **R1 — MP4RA Synchronization (2025-10-06):** Automated the MP4RA registry refresh via the new `MP4RACatalogRefresher` and `isoinspect mp4ra refresh` command, with workflow guidance captured in `Docs/Guides/MP4RARefreshGuide.md` and summary notes in `DOCS/INPROGRESS/07_R1_MP4RA_Catalog_Refresh.md`.
- **R6 — Annotation Persistence Strategy (2025-10-10):** CoreData chosen over JSON based on R6 analysis. Implementation captured in `DOCS/INPROGRESS/C4_CoreData_Annotation_Persistence.md`; the production store lives in `Sources/ISOInspectorApp/Annotations/CoreDataAnnotationBookmarkStore.swift`.

## Tracking & Reporting
- Update this table as research completes or new gaps are discovered.
- Reference associated implementation tasks by Task ID from `04_TODO_Workplan.md` to maintain traceability.
- Archive research summaries in project documentation once finalized.
