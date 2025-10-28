# Next Tasks

- 🚧 **T3.7 — Integrity Navigation Filters** _(In Progress — see `DOCS/INPROGRESS/T3_7_Integrity_Navigation_Filters.md`)_:
  - Resolve the `#T36-001` through `#T36-003` TODO markers in the Integrity summary and explorer views as part of the navigation and sorting polish.
  - Track implementation alongside the tolerance parsing roadmap so the remaining UI corruption milestone ships with the expected filters and shortcuts.

- 🚧 **#4 Integrate the `ResearchLogMonitor` audit with SwiftUI previews** _(Active — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md`)_:
  - Ensure preview scenarios invoke `ResearchLogMonitor.audit` for VR-006 fixtures and surface schema/missing-data diagnostics during design-time validation.
  - Thread `ResearchLogPreviewProvider` snapshots through preview compositions so diagnostics appear alongside sample payloads.
  - Back previews with canonical VR-006 fixtures plus mismatch/missing variants for regression visibility, and document the refresh workflow when schemas change.
