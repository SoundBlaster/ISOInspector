# Validation Rule Toggle & Preset Controls

## Overview
- Introduce a configuration layer that lets analysts enable or disable individual validation rules without recompiling the core engine. All rules remain active by default so historical behavior and automated regression coverage stay intact.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L32-L78】
- Provide first-class preset groupings (e.g., “Structural Only”, “Advisory”, “All Checks”) so the CLI and app can switch between curated rule bundles tuned for debugging, ingest triage, or lightweight smoke runs.【F:DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Validation_Rule_15_Sample_Table_Correlation.md†L1-L31】【F:DOCS/TASK_ARCHIVE/142_E3_Warn_on_Unusual_Top_Level_Ordering/E3_Warn_on_Unusual_Top_Level_Ordering.md†L9-L24】
- Surface these controls through CLI flags, project configuration, and UI settings panes to maintain parity across workflows documented in the execution plan and PRD backlog.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12-L120】【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L223-L266】

## Motivation
- Validation scope has steadily expanded (VR-001…VR-015), and upcoming correlation checks continue to increase runtime cost.【F:DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Summary_of_Work.md†L5-L22】【F:DOCS/TASK_ARCHIVE/144_E5_Basic_stbl_Coherence_Checks/E5_Basic_stbl_Coherence_Checks.md†L1-L24】
- Analysts often want to suppress advisory warnings (VR-005, VR-006) while focusing on structural blockers; conversely, QA smoke tests may only need catastrophic failures to bubble up.【F:DOCS/TASK_ARCHIVE/89_Close_TODO_3/89_Close_TODO_3.md†L1-L24】
- Execution guide roadmaps already assume future knobs for streaming diagnostics, so providing validation toggles now aligns with our configuration strategy and reduces ad-hoc forked builds.【F:DOCS/TASK_ARCHIVE/49_CLI_Global_Logging_and_Telemetry_Toggles/Summary_of_Work.md†L8-L15】【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L92-L96】

## Goals
1. Ship a `ValidationConfiguration` API that maps rule identifiers to on/off state and exposes immutable preset descriptors.
2. Persist the active preset and custom overrides in both CLI invocations (flags/config files) and UI sessions (workspace settings) with layered global defaults stored alongside other user data and per-document overrides that can be reset, while defaulting to “All Checks”.
3. Maintain reporting fidelity by annotating validation output with the active preset so exports and logs remain auditable, listing disabled rules as `skipped` in structured payloads while omitting them from final human-readable reports.
4. Ensure regression tests cover preset selection, per-rule overrides, and default fallbacks across ISOInspectorKit, CLI, and SwiftUI surfaces.

## Non-Goals
- Redesigning the validation rule engine or severity taxonomy (errors vs warnings) — existing classifications remain authoritative.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L56-L78】
- Persisting organization-wide policy profiles; this iteration focuses on per-run/session configuration only.
- Shipping remote management or workspace sync for validation settings.

## User Journeys
- **CLI Automation:** A CI pipeline invokes `isoinspector validate --preset structural --disable VR-006 file.mp4` to ignore advisory research logging while preserving hard failures. Exit codes and summaries reflect the active preset.
- **App Analyst:** A media engineer opens the Settings pane, selects the “Advisory + Structural” preset, then disables VR-005 for a streaming ingest session. The sidebar badges refresh to reflect filtered warnings, and the choice persists for that document workspace.
- **Preset Authoring:** A developer adds a new VR-016. The configuration registry exposes it automatically, and presets opt-in explicitly so release notes document the change.

## Requirements
### Core / ISOInspectorKit
- Create `ValidationRuleID` metadata and ship a registry enumerating available rules for presentation layers.
- Bundle default preset metadata as JSON resources in the app/CLI targets and load user-authored presets from the Application Support domain so local customizations persist with other user data.
- Provide `ValidationConfiguration` and `ValidationPreset` types with Codable conformance so settings can be serialized for CLI config files or UI persistence.
- Default configuration enables every registered rule; unset values inherit from the active preset.
- Emit preset metadata alongside validation summaries (e.g., CLI header, JSON export metadata node) for traceability.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L1-L120】

### CLI
- Extend `ISOInspectorCommand.GlobalOptions` with flags:
  - `--preset <name>` selects a named preset.
  - `--enable-rule` / `--disable-rule` accept repeated rule IDs.
  - Provide short help text enumerating available presets and rule identifiers.
- Ship ergonomic alias flags (e.g., `--structural-only`, `--advisory-only`) that map directly to bundled presets for quick invocation.
- Persist CLI presets via optional config file (e.g., `$ISOINSPECTOR_HOME/validation.json`) or environment variable overrides for automation.
- Document flag precedence: explicit per-rule flags override preset defaults for the invocation.

### UI / App
- Add a Validation Settings sheet or inspector section that lists available presets and per-rule toggles grouped by severity/category.
- Maintain layered persistence so global app-level defaults live with other user settings while individual documents/workspaces remember overrides; expose a “Reset to Global” affordance that wipes the per-file layer.
- Persist selections per workspace/session; when absent, fall back to the default preset shipped by the core configuration.
- Ensure list virtualization handles >15 rules without layout thrash; integrate with existing badge/filter architecture so toggling a rule immediately updates the tree and validation list.【F:DOCS/TASK_ARCHIVE/19_C2_Tree_View_Virtualization/Summary_of_Work.md†L6-L16】

## Preset Concepts (Initial Draft)
- **All Checks (default):** Enables every rule (status quo).
- **Structural Only:** VR-001, VR-002, containment/overlap rules, edit list duration checks, sample table coherence. Disables advisory metadata and research logging warnings.
- **Advisory Focus:** Enables warnings/info (VR-005, VR-006, unusual ordering, research log) while allowing structural checks to be toggled individually for experimentation.
- **Custom:** Placeholder name used when users modify preset defaults; surfaces diff between preset and overrides for quick reset.

## Dependencies & Interactions
- Relies on ongoing validation expansion efforts (E1 containment, E5 table coherence) so new rules register with the configuration API once they land.【F:DOCS/INPROGRESS/next_tasks.md†L1-L10】
- Must align with CLI logging/telemetry toggles to avoid conflicting global option parsing semantics.【F:DOCS/TASK_ARCHIVE/49_CLI_Global_Logging_and_Telemetry_Toggles/49_CLI_Global_Logging_and_Telemetry_Toggles.md†L10-L19】
- UI implementation should reuse design system tokens for toggles/presets to avoid duplicating styling logic.【F:DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md†L92-L132】

## Decisions
1. Default presets ship as bundled JSON manifests; user-defined presets persist in Application Support alongside other ISOInspector data so local overrides survive upgrades.
2. Configuration persistence layers global app-level defaults with per-document/workspace overrides that can be cleared from the UI to fall back to the global choice set.
3. Structured exports include disabled rule identifiers annotated with a `skipped` status while narrative summaries omit those rules entirely, keeping reports concise without losing audit metadata.
4. CLI ergonomics include shorthand flags (for example, `--structural-only`) that resolve to the corresponding preset in addition to the generic `--preset <name>` selector.

## Risks
- Misconfigured presets could hide critical validation issues if defaults are changed without audit logging; we mitigate by logging active presets in CLI output and UI session metadata.
- UI complexity may overwhelm users; grouping toggles by severity/category and providing presets reduces the cognitive load.
- Introducing configuration state increases test matrix size; automation must cover default, preset, and override combinations.

## References
- `ISOInspector Technical Specification` — validation architecture and rule catalog.【F:DOCS/AI/ISOInspector_Execution_Guide/03_Technical_Spec.md†L32-L96】
- `Validation Rule #15 — Sample Table Correlation` — demonstrates multi-rule coordination benefiting from presets.【F:DOCS/TASK_ARCHIVE/130_VR15_Sample_Table_Correlation/Validation_Rule_15_Sample_Table_Correlation.md†L1-L31】
- `E5 — Basic stbl Coherence Checks` — highlights ongoing validation expansion motivating configuration.【F:DOCS/TASK_ARCHIVE/144_E5_Basic_stbl_Coherence_Checks/E5_Basic_stbl_Coherence_Checks.md†L1-L24】
- `ISOInspector PRD TODO (Phase E)` — validation backlog requiring cohesive configuration strategy.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L223-L266】
