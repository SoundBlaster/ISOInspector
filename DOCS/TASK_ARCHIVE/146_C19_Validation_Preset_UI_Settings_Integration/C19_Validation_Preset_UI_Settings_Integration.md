# C19 — Validation Preset UI Settings Integration

## 🎯 Objective
Deliver a SwiftUI settings experience that lets analysts select validation presets, toggle individual rules, and persist those choices alongside Application Support defaults so ISOInspectorApp mirrors the new validation configuration layer.

## 🧩 Context
- Phase C task C19 in the execution workplan calls for surfacing presets and per-rule toggles in the settings UI with persistence layered across global defaults and per-workspace overrides.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L52-L60】
- The validation configuration core (task B7) already ships preset metadata and storage hooks intended for both CLI wiring (task D7) and this UI integration.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L35-L36】【F:DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md†L4-L31】
- The dedicated validation preset PRD details required presets, alias semantics, and persistence expectations that the UI must honor for parity across surfaces.【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L1-L78】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L103-L150】

## ✅ Success Criteria
- Settings pane lists all bundled presets with descriptions and updates the active configuration immediately after selection.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L52-L60】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L108-L139】
- Per-rule toggles reflect the current preset, allow overrides, and show when the user diverges from preset defaults (e.g., “Custom” state).【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L103-L139】
- Choices persist to Application Support global defaults and optional workspace-specific overrides, including a “Reset to Global” affordance that clears local customizations.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L52-L60】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L132-L150】
- Validation badges, lists, and downstream exports reflect the active preset metadata so the app stays aligned with CLI/JSON outputs.【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L37-L78】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L92-L115】

## 🔧 Implementation Notes
- Reuse `ValidationConfiguration` and `ValidationPreset` APIs from task B7, watching for dependency changes as containment rule (E1) and CLI wiring (D7) land; ensure the UI observes configuration updates for live feedback.【F:DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md†L4-L31】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L151-L180】
- Hook persistence into existing Application Support storage conventions so presets survive upgrades, matching CLI config file expectations for auditability.【F:DOCS/TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md†L20-L31】【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L120-L150】
- Align UI controls with FoundationUI design tokens and accessibility guidance to avoid regressions highlighted in prior research tasks.【F:DOCS/AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md†L140-L150】【F:DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md†L92-L132】【F:DOCS/TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md†L1-L40】

## 🧠 Source References
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`13_Validation_Rule_Toggle_Presets_PRD.md`](../AI/ISOInspector_Execution_Guide/13_Validation_Rule_Toggle_Presets_PRD.md)
- [`B7_Validation_Rule_Preset_Configuration.md`](../TASK_ARCHIVE/145_B7_Validation_Rule_Preset_Configuration/B7_Validation_Rule_Preset_Configuration.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`Design System Guide`](../AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md)
- [`Accessibility Guidelines`](../TASK_ARCHIVE/91_R3_Accessibility_Guidelines/Summary_of_Work.md)
