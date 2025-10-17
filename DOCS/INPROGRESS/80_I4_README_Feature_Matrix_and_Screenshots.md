# I4 — README Feature Matrix & Screenshots

## 🎯 Objective

Deliver a release-ready README that highlights ISOInspector’s CLI, app, and library capabilities with a concise feature
matrix, enumerates supported box categories, and embeds representative UI captures for prospective users.

## 🧩 Context

- Workplan Phase I identifies Task I4 as the next packaging milestone now that product definitions and entitlements are
  complete.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L89-L103】
- The PRD backlog tracks I4 as outstanding alongside related release collateral such as the theming and release-notes
  follow-ups.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L256-L263】
- Existing manuals document the UI and CLI experiences that should feed the README feature matrix and
  screenshots.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L114】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L91】

## ✅ Success Criteria

- README gains a “Feature Matrix” table covering ISOInspectorKit, ISOInspectorApp, and the `isoinspect` CLI with their flagship capabilities (streaming parse, validation, export, bookmarks, automation flags).【F:Documentation/ISOInspector.docc/Manuals/App.md†L15-L114】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L91】
- README lists supported platforms, file types, and major box families (e.g., container, metadata, streaming) aligned
  with the existing documentation and code
  registries.【F:Documentation/ISOInspector.docc/Manuals/App.md†L7-L34】【F:Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift†L1-L146】
- README embeds at least one current UI screenshot illustrating the tree/detail/hex workflow, sourced from the latest
  DocC or simulator capture and stored in the repo’s documentation assets
  hierarchy.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L114】
- README cross-links to the DocC manuals and guides so readers can dive deeper without navigating the repo tree
  manually.【F:Documentation/ISOInspector.docc/Manuals/App.md†L111-L114】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L83-L91】

## 🔧 Implementation Notes

- Reuse the CLI and app manuals as canonical descriptions when composing the feature matrix to ensure wording matches
  the shipped
  experience.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L114】【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L91】
- Reference the container and media code enums for supported box lists so the README stays aligned with `ISOInspectorKit` internals.【F:Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift†L1-L146】【F:Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift†L1-L154】
- Capture fresh UI screenshots from the macOS build (or DocC tutorials) and store them under `Documentation/Assets/` or an equivalent tracked location referenced in DocC.【F:Documentation/ISOInspector.docc/Manuals/App.md†L1-L114】
- Run `scripts/fix_markdown.py README.md` after editing to keep formatting consistent with repository conventions.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`Documentation/ISOInspector.docc/Manuals/App.md`](../Documentation/ISOInspector.docc/Manuals/App.md)
- [`Documentation/ISOInspector.docc/Manuals/CLI.md`](../Documentation/ISOInspector.docc/Manuals/CLI.md)
- [`Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift`](../Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift)
- [`Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift`](../Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift)
