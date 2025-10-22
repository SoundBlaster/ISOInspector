# B7 — Validation Rule Preset Configuration

## 🎯 Objective
Establish the shared validation configuration layer that introduces preset registries and per-rule toggles for ISOInspectorKit, enabling downstream CLI (D7) and SwiftUI (C19) surfaces to consume a consistent API.

## 🧩 Context
- Phase B task B7 in the execution workplan is the foundational slice of the broader validation preset initiative spanning B7, D7, and C19.
- The preset PRD outlines how configuration types, bundled JSON manifests, and persistence tiers must behave, covering CLI aliases and Application Support storage.
- PRD backlog item E7 tracks cross-surface delivery expectations so the CLI and UI match the configuration behavior.

## ✅ Success Criteria
- `ValidationConfiguration` and `ValidationPreset` types enumerate rule identifiers, load bundled presets, and default to all rules enabled with Codable support for persistence.
- Application Support storage persists user-authored presets alongside global defaults, and per-document overrides inherit from the active preset.
- Validation output metadata (CLI headers, JSON exports, session state) records the active preset and lists disabled rules as `skipped` for audit trails.
- Tests cover preset selection, per-rule overrides, and default fallbacks in ISOInspectorKit so downstream consumers can rely on deterministic behavior.

## 🔧 Implementation Notes
- Catalog existing validation rule identifiers (VR-001…VR-015) so presets stay synchronized with the rule registry.
- Define preset manifest schema (name, description, default rule states) and bundle starter manifests alongside resource loading helpers.
- Provide hooks for downstream layers: expose preset listings, change notifications, and serialization helpers that the CLI and app will adopt in D7/C19.
- Coordinate with ongoing validation work (E1 containment, D6 encryption placeholders) to ensure new rules are registered automatically when they land.

## ✅ Current Iteration — 2025-10-22
- Added `ValidationRuleIdentifier`, `ValidationPreset`, and `ValidationConfiguration` types to ISOInspectorKit with Codable support for persistence and runtime toggles.
- Bundled `ValidationPresets.json` manifest containing the "All Checks Enabled" default and a "Structural Focus" preset with advisory rules disabled.
- Introduced `ValidationConfigurationTests` verifying manifest loading, override behavior, and identifier coverage (`swift test`).

### 🔜 Follow-up Focus
- Surface the preset registry through ISOInspectorCLI (task D7) so CLI callers can select presets and specify per-rule overrides.
- Thread the configuration through ISOInspectorApp settings (task C19), persisting user-authored presets in Application Support.
- Extend validation metadata exports to include the active preset identifier and any disabled rule IDs.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
- [`13_Validation_Rule_Toggle_Presets_PRD.md`](../AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md)
