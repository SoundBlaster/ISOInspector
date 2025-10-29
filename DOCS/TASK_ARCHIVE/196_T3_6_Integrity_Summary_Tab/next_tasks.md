# Next Tasks

- 🚧 **T3.6 — Integrity Summary Tab** _(In Progress — see `DOCS/INPROGRESS/T3_6_Integrity_Summary_Tab.md`)_:
  - Build the Integrity tab surface with sortable/severity-filterable `ParseIssue` rows synchronized with ribbon metrics.
  - Route row selection through `DocumentSessionController` so focusing a row re-centers the outline and detail panes.
  - Hook Share/Export actions to the refreshed plaintext and JSON exporters and extend UI/export tests to verify count parity.
- ✅ **#4 Integrate ResearchLogMonitor Audit Into SwiftUI Previews** _(Completed — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md` for closure notes)_:
  - SwiftUI preview scenarios now invoke the audit helper and surface VR-006 diagnostics alongside bundled fixtures.
