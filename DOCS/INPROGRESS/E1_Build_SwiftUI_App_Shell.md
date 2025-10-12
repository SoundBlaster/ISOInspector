# E1 — Build SwiftUI App Shell

## 🎯 Objective

Deliver the initial ISOInspectorApp shell that lets users browse MP4/QuickTime files and open them into the existing
streaming UI. Persist a recents list so the groundwork for full session restoration is in place.

## 🧩 Context

- FR-APP-001 maps out document browsing, recents, and workspace persistence needs for

  ISOInspectorApp.【F:DOCS/AI/ISOInspector_Execution_Guide/02_Product_Requirements.md†L12-L33】

- The workplan schedules E1 after C1 so the Combine stores power the shell while recents stay durable across

  launches.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L39-L44】

- Backlog item G1 captures the cross-platform importer behaviors needed for the document browser

  component.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L108-L124】

- FR-APP-001 crosswalk notes align this work with streaming and persistence standards to support session

  restoration.【F:DOCS/AI/ISOInspector_Execution_Guide/06_Task_Source_Crosswalk.md†L58-L74】

## ✅ Success Criteria

- Users see onboarding or recent files immediately upon launch, backed by persisted entries.
- Opening files via the browser or picker streams events into tree/detail/hex views without hurting responsiveness

  goals.

- Successfully opened files land in a recents model (security-scoped bookmarks/CoreData) that reloads on relaunch.
- Analytics toggles stay disabled to retain CLI parity while leaving hooks for later instrumentation tasks.

## 🔧 Implementation Notes

- Integrate the ParsePipeline and Combine stores into a DocumentSessionController.
- Ensure parsing stays off the main actor while that controller feeds SwiftUI state.
- Adopt platform pickers (DocumentGroup on macOS/iPadOS, `.fileImporter` on iOS) to cover the required MP4/QuickTime UTTypes.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L108-L124】
- Persist recents using security-scoped bookmarks or CoreData scaffolding.
- Expose the data so Task E3 can extend the store to full workspace restoration.
- Centralize future streaming metrics toggles in the shell.
- Keep them disabled to mirror CLI behavior tracked in the PDD follow-ups.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
