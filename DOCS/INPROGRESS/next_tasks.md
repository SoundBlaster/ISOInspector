# Next Tasks

- 🚧 **T3.6 — Integrity Summary Tab** _(In Progress — see `DOCS/INPROGRESS/T3_6_Integrity_Summary_Tab.md`)_:
  - Wire the Integrity tab layout so aggregated `ParseIssue` rows support severity sorting, filtering, and node focus.
  - Connect Share menu actions to the refreshed plaintext and JSON exporters without diverging from ribbon and detail pane counts.
- 🚧 **T4.4 — Sanitize Tolerant Parsing Issue Exports** _(In Progress — see `DOCS/INPROGRESS/195_T4_4_Sanitize_Issue_Exports.md`)_:
  - Audit JSON and plaintext issue exporters to ensure they never embed raw payload data.
  - Add regression tests and documentation updates covering the sanitisation guarantee for shared diagnostics.
- 🚧 **#4 Integrate ResearchLogMonitor Audit Into SwiftUI Previews** _(In Progress — see `DOCS/INPROGRESS/194_ResearchLogMonitor_SwiftUIPreviews.md`)_:
  - Ensure preview scenarios invoke `ResearchLogMonitor.audit` for VR-006 fixtures and surface schema/missing-data diagnostics during design-time validation.
