# Next Tasks

- 🧭 **Scope follow-up to the Integrity Summary tab release** _(Backlog alignment)_:
  - Review the outstanding `@todo` markers (`#T36-001` through `#T36-003`) recorded in `Sources/ISOInspectorApp/Integrity` during the T3.6 wrap-up archived under `DOCS/TASK_ARCHIVE/196_T3_6_Integrity_Summary_Tab/`.
  - Compare those refinements with the roadmap in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` so the next UI milestone (e.g., T3.7 navigation filters) enters planning with the correct scope.
  - Draft a fresh PRD stub in `DOCS/INPROGRESS/` once the next Integrity-focused milestone is selected.

- 🚧 **#4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews** _(Active — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md`)_:
  - Ensure preview scenarios invoke `ResearchLogMonitor.audit` for VR-006 fixtures and surface schema/missing-data diagnostics during design-time validation.
  - Thread `ResearchLogPreviewProvider` snapshots through preview compositions so diagnostics appear alongside sample payloads.
  - Back previews with canonical VR-006 fixtures plus mismatch/missing variants for regression visibility, and document the refresh workflow when schemas change.
