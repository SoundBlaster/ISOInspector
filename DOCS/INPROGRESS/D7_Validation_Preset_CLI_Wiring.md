# D7 — Validation Preset CLI Wiring

## 🎯 Objective
Enable ISOInspectorCLI consumers to choose bundled validation presets or override individual rules so command invocations drive the shared `ValidationConfiguration` pipeline without hand-editing configuration files.

## 🧩 Context
- Phase D of the execution workplan identifies D7 as the follow-up to the CLI streaming commands (D2) now that the configuration layer exists from task B7, calling for preset selection flags and alias affordances for structural-only runs.
- The validation toggle PRD defines the required ergonomics (`--preset`, `--disable-rule`, alias flags) and audit metadata that must flow into CLI help, structured exports, and downstream tooling.
- Detailed backlog item E7 keeps the broader validation toggle initiative open until CLI wiring lands, ensuring parity between the existing app settings UI and command-line workflows.

## ✅ Success Criteria
- `isoinspector validate` and related commands accept `--preset <identifier>` along with `--enable-rule` / `--disable-rule` flags that populate a `ValidationConfiguration` sent to the inspection pipeline.
- CLI help text enumerates available preset identifiers plus shorthand aliases (for example, `--structural-only`) sourced from the bundled manifest so users can discover options without consulting documentation.
- When presets or per-rule overrides are supplied, CLI output and JSON exports annotate the active preset and any disabled rule IDs, matching the configuration persistence semantics delivered in task B7.
- New and updated tests cover flag parsing, preset alias resolution, and integration with the existing validation execution path to ensure regressions are caught by `swift test`.

## 🔧 Implementation Notes
- Extend `ISOInspectorCommand.GlobalOptions` in `Sources/ISOInspectorCLI/ISOInspectorCommand.swift` to declare the new flags and surface preset metadata pulled from `ValidationPresetRegistry` or equivalent helpers introduced in task B7.
- Ensure the command context (`ISOInspectorCommandContext` and `ISOInspectorCommandContextStore`) receives the effective `ValidationConfiguration` so downstream command handlers reuse the same configuration regardless of entry point.
- Reconcile new flags with existing global options like logging/telemetry toggles to avoid conflicting short names and keep help formatting consistent with Swift ArgumentParser conventions.
- Update CLI documentation (`Documentation/ISOInspector.docc/Manuals/CLI.md`) once behavior stabilizes so usage examples reflect preset aliases and per-rule overrides.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`13_Validation_Rule_Toggle_Presets_PRD.md`](../AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md)
- [`DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration`](../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md)
