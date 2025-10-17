# I3 — App Icon Rasterization

## 🎯 Objective

Generate production-quality raster assets for the ISOInspector app icon across all required Apple platform sizes so the branding work from Task I3 ships in notarized builds with light and dark appearance fidelity.

## 🧩 Context

- Task I3 in the execution workplan covers complete app theming once distribution scaffolding (Task E4) is in place.
- Accent palette and SwiftUI tint wiring are already archived in `DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming/`.
- Remaining scope focuses on transforming the approved vector source into platform-specific raster outputs referenced by `AppIcon.appiconset`.

## ✅ Success Criteria

- Rasterized icon assets exist for every slot required by the multiplatform asset catalog (macOS, iOS, iPadOS) with correct pixel dimensions and idiom metadata.
- Light and dark appearance variants render without color banding or clipped safe zones when previewed in Xcode asset inspector.
- Updated asset catalog integrates into both SwiftUI previews and notarized archive builds without triggering missing asset warnings or placeholder fallbacks.
- Documentation sources (`todo.md`, workplan, PRD backlog) reflect Task I3 as in progress until assets merge into main.

## 🔧 Implementation Notes

- Source vector artwork lives alongside the theming archive; export PNGs at 1x/2x/3x as required, ensuring the macOS 1024×1024 master is lossless.
- Use Xcode asset catalog templates or `actool` to validate slot coverage; add dark appearance variants if branding requires.
- Update `Assets.xcassets/AppIcon.appiconset/Contents.json` metadata once files are generated, keeping naming consistent with prior accent palette changes.
- Run `scripts/fix_markdown.py` after documentation updates; run `swift build` if asset catalog integration touches build settings.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming`](../TASK_ARCHIVE/80_Summary_of_Work_2025-10-17_App_Theming)
