# Distribution: Apple Events Automation Assessment

## 🎯 Objective

Determine whether ISOInspector's notarized build process requires Apple Events automation and document any entitlement
or tooling adjustments needed to keep distribution workflows compliant.

## 🧩 Context

- Distribution entitlements currently omit Apple Events capabilities and include a TODO to revisit automation
  requirements for notarized builds.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L14】
- The execution workplan now tracks follow-up task **E4a** to evaluate automation needs around notarization after the
  base distribution scaffolding completed.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L41-L47】
- Packaging and release backlog items call out distribution tasks, including this new Apple Events evaluation, to
  prepare for shipping ISOInspector builds.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L244-L252】

## ✅ Success Criteria

- Document whether notarization flows rely on Apple Events automation (e.g., driving Finder/archive steps) or can remain purely `notarytool`-based.
- Update entitlements and documentation if Apple Events access is required, or confirm current entitlements are
  sufficient.
- Outline any CI or manual steps needed so future packaging work (release notes, theming, TestFlight/DMG distribution)
  can proceed without blocking dependencies.

## 🔧 Implementation Notes

- Review existing notarization tooling (`scripts/notarize_app.sh`) and distribution metadata to understand the current manual/automated process and where Apple Events might be invoked.【F:scripts/notarize_app.sh†L1-L62】
- Coordinate changes with sandboxing requirements; only add Apple Events entitlements if necessary and ensure
  documentation captures rationale for security review.
- Capture decision outcomes and next actions in this document; archive once implementation or confirmation is complete.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
