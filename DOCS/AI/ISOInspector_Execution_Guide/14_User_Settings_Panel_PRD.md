# 14 — Floating User Settings Panel PRD

## Background & Motivation
The desktop and tablet builds of ISOInspector already expose validation presets inside the macOS Settings scene (Task C19), but users still have to navigate away from the inspection canvas to tweak preferences, and iPad/iOS builds never gained a comparable affordance. Recent operator feedback requests a consolidated user settings surface that can float above the current workspace or appear as a modal sheet without forcing a context switch. The panel also needs to differentiate between **permanent** preferences (persisted across launches in the global `ValidationPreferences` store alongside other app-wide defaults) and **session-scoped** overrides that only affect the currently open document or workspace snapshot maintained by `DocumentSessionController`.

Delivering this feature keeps the UI aligned with product requirement FR-UI-004 while extending it to additional preference families (streaming, UI chrome, telemetry, logging) and honors previous investments in layered persistence from Tasks B7 (configuration layer), C19 (settings UI), E3 (session persistence), G2 (bookmark/bookmark diff reconciliation), and the diagnostics logging path captured in `DOCS/TASK_ARCHIVE/68_E6_Emit_Persistence_Diagnostics/Summary_of_Work.md`.

## Goals
1. Present a floating or modal settings surface that can be summoned from anywhere in the app without leaving the current parse session.
2. Clearly separate permanent vs. session-only settings groups while surfacing contextual help for each control.
3. Reuse FoundationUI components (Inspector pattern, cards, badges) so the panel inherits the design system roadmap tracked in `DOCS/INPROGRESS/FoundationUI_Integration_Strategy.md`.
4. Persist permanent choices immediately to the global preferences store and queue session-only changes through `DocumentSessionController` so workspace snapshots, diagnostics logging, and export metadata stay in sync.
5. Provide reset affordances: one action to restore permanent defaults (`ValidationPreferences.reset()`) and another to clear only the current session overrides (mirroring the "Reset to Global" behavior shipped with C19).

## Non-Goals
- Cross-device synchronization of preferences (iCloud/CloudKit) — still out of scope per `03_Technical_Spec.md`.
- Replacing the existing macOS Settings scene; the floating panel supplements it for rapid changes.
- Introducing new validation rules or presets beyond what `13_Validation_Rule_Toggle_Presets_PRD.md` already enumerates.

## Requirements
### Platform & Presentation
- macOS: expose the panel as an `NSPanel`-style floating window anchored to the current document window, with optional detents for compact and expanded views.
- iPadOS/iOS: present a FoundationUI-styled modal sheet (detent-based on iPad, full-screen card on iPhone) with drag-to-dismiss and keyboard shortcut support (`⌘,`).
- Keyboard shortcuts toggle the panel open/closed, and VoiceOver focus starts on the first control in the previously active group.
- Panel remembers its last size/position per window session.

### Settings Taxonomy
1. **Permanent Settings**
   - Validation preset selection and per-rule toggles (reuse `ValidationSettingsViewModel`).
   - Telemetry/logging verbosity, FoundationUI experimental flags, and accessibility tweaks (e.g., Reduce Motion override) that must persist under `Application Support/ISOInspector/UserPreferences.json`.
   - Each change triggers an optimistic write through `ValidationPreferencesStore` (global) with diagnostics on failure, following the patterns from Task E6.
2. **Session Settings**
   - Active workspace scope (per document vs. shared), pane layout toggles, recently opened tabs, and temporary validation overrides that must serialize with the session snapshot per Task E3.
   - Updates go through `DocumentSessionController` so CoreData and JSON fallback stores remain consistent; a `SessionSettingsPayload` blob will be added to the session schema if missing.
   - Closing a workspace discards session-only changes unless they were promoted to permanent defaults.

### Interactions & UX
- Left sidebar lists sections (Permanent, Session, Advanced); selecting a section scrolls content on the right.
- Each section uses FoundationUI cards with inline descriptions, help buttons linking to DocC articles, and badges showing whether the value deviates from global defaults.
- Apply button should stay disabled until the user makes changes; Cancel reverts unpersisted edits (session-only changes revert by reloading the snapshot; permanent changes rely on a temp copy of the decoded preferences struct).
- Panel supports search/filter input to find a specific toggle quickly.

### Data Flow & Persistence
1. Panel opens → view model fetches the latest permanent preferences and session snapshot asynchronously.
2. User changes a permanent toggle → view model mutates `UserPreferencesModel`, writes via `UserPreferencesStore.persist()`, emits success/failure.
3. User changes session setting → view model mutates `SessionSettingsPayload`, calls `DocumentSessionController.updateSessionSettings(for:documentID:)`.
4. Closing panel publishes a `SettingsPanelDidDismiss` event for automation tests (mirrors existing diagnostics events).
5. Reset buttons call into shared helpers that nuke either the permanent file or the session payload before reloading UI state.

## Dependencies & Related Work
- **B7 / `ValidationConfiguration`** — supplies rule metadata, default presets, and serialization format for permanent validation controls.
- **C19 `ValidationSettingsView`** — existing macOS settings panes provide UI/UX references and a model layer to reuse.
- **E3 Session Persistence + C7 Bookmark Diff Reconciliation** — ensures session overrides save to CoreData + JSON snapshots and remain compatible with bookmark diff linkage.
- **E6 Diagnostics** — captures persistence failures for both permanent and session writes.
- **FoundationUI Integration Plan** — panel should live under Phase 1/2 migration to reduce duplicated styling work.

## Risks & Mitigations
- **State Divergence:** Separate stores for permanent/session values risk drifting. Mitigation: share a single `SettingsBridge` actor that issues updates and publishes diffs to both view models.
- **Platform Inconsistency:** macOS floating window vs. iPad sheet may diverge. Mitigation: keep shared SwiftUI scene with conditional modifiers (detents vs. panel chrome) and parity snapshot tests.
- **Performance:** Loading preferences on every toggle may stutter. Mitigation: keep decoded models in-memory and throttle writes with Combine's `debounce` for bursty updates while ensuring final state is persisted.

## Acceptance Criteria
1. `SettingsPanelView` renders both permanent and session sections with FoundationUI styling and contextual help copy.
2. macOS builds show a floating window or detached panel; iPad/iOS builds present a modal sheet following Human Interface Guidelines.
3. Permanent changes persist across relaunch (validated by unit + UI tests) and log failures via diagnostics hooks.
4. Session changes survive workspace reloads but do **not** leak into other sessions; "Reset Session" clears only the current workspace payload.
5. Automation/UI tests cover keyboard shortcut invocation, VoiceOver focus order, and state synchronization across reopen events.
6. Documentation (Product Requirements, Technical Spec, Workplan, and `DOCS/INPROGRESS/next_tasks.md`) references this PRD and describes execution steps.

## Open Questions
- Should the CLI also expose session vs. permanent toggles via a unified config file? (Deferred; capture follow-up in future CLI backlog.)
- Do we need telemetry gating for the floating panel (e.g., to collect anonymized usage)? Current stance: no data collection; instrumentation limited to diagnostics logs.
- Should permanent settings live in a single `UserPreferences` file or reuse multiple domain-specific files (`ValidationPreferences`, `TelemetryPreferences`)? Initial implementation can wrap existing files under a shared aggregator, but future refactors may split by domain again if warranted.

## Next Steps
1. Add workplan entries C21 (panel shell) and C22 (persistence plumbing) under Phase C.
2. Update `03_Technical_Spec.md` with architecture details (panel presentation, stores, concurrency model).
3. Queue actionable subtasks in `DOCS/INPROGRESS/next_tasks.md` with acceptance checkpoints.
4. Coordinate with FoundationUI integration timeline to reuse patterns/components and avoid duplicate styling work.
