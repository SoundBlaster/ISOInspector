# I3 App Theming

## 🎯 Objective

Deliver a branded ISOInspector visual identity by supplying production-ready app icons and accent colors that respect
both light and dark appearances across macOS, iPadOS, and iOS builds.

## 🧩 Context

- Phase I of the execution workplan schedules Task I3 to finalize app theming so shipped binaries match the documented

  branding expectations for iconography and color palettes.

- The PRD TODO backlog lists I3 as the outstanding packaging item to supply icon/light–dark assets for the universal

  SwiftUI app, signalling this as the remaining release-readiness gap in Phase I.

## ✅ Success Criteria

- App icon sets include all required idioms and scales for macOS, iOS, and iPadOS targets, packaged inside an asset

  catalog referenced by the Xcode project.

- Accent colors and theming resources render correctly in both light and dark modes, with SwiftUI previews or

  screenshots confirming contrast and accessibility compliance.

- Updated theming assets are reflected in distribution artifacts (TestFlight/DMG) with documentation/screenshots

  refreshed as needed.

## 🔧 Implementation Notes

- Populate `Sources/ISOInspectorApp/Resources/` with an `Assets.xcassets` catalog that contains `AppIcon.appiconset` entries covering platform-specific size requirements.
- Define shared accent colors within the asset catalog and apply them through SwiftUI `AccentColor` or environment modifiers inside `ISOInspectorApp` scene declarations.
- Update marketing captures (DocC manuals or README imagery) if iconography or primary colors change to preserve

  alignment across docs and product surfaces.

- Coordinate with distribution tooling (`Distribution/` scripts and project settings) to ensure new assets flow through notarization and packaging workflows without additional manual steps.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived theming context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

---

## 📈 Progress — 2025-10-17

- Added a shared brand palette (`ISOInspectorBrandPalette`) with WCAG-checked contrast tests.
- Introduced an `Assets.xcassets` catalog containing accent and surface colors with light/dark variants.
- Applied the SwiftUI tint/theme modifier to the app shell so primary actions pick up the brand accent.
- Follow-up: generate production icon PNGs from vector artwork and connect them to `AppIcon.appiconset` (`@todo` PDD:45m / `todo.md`).
