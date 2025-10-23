# J2 — Persist Security-Scoped Bookmarks

## 🎯 Objective
Finalize the FilesystemAccessKit bookmark ledger so ISOInspector restores previously authorized files across sessions, heals stale entries, and keeps audit logging aligned with zero-trust policies.

## 🧩 Context
- FilesystemAccess ideology requires a single entry point that manages security-scoped URLs, persists consent, and records hashed audit events for every lifecycle transition.【DOCS/AI/ISOInspector_Execution_Guide/11_FilesystemAccess_Ideology_and_PRD.md†L1-L65】
- The FilesystemAccessKit PRD outlines async APIs, bookmark persistence goals, and logging constraints that must remain satisfied while the session controller evolves.【DOCS/AI/ISOInspector_Execution_Guide/09_FilesystemAccessKit_PRD.md†L1-L63】
- Execution workplan notes J2 as the active follow-up to re-align bookmark storage with the refreshed session flow and diagnostics coverage.【DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L134-L149】

## ✅ Success Criteria
- Session restoration uses FilesystemAccessKit to resolve stored bookmarks, reopening prior documents without manual re-authorization when files remain available.
- Stale or invalid bookmarks trigger deterministic cleanup and user prompts; remediation is logged with hashed identifiers and covered by regression tests.
- Recent-files lists and CLI automation guides document the refreshed workflow, including how to export/import bookmark data safely for headless scenarios.
- Automated tests (unit/UI) confirm scopes are activated and revoked exactly once per access and that audit events mirror CLI coverage.

## 🔧 Implementation Notes
- Review current `BookmarkStore` persistence (CoreData/JSON) to ensure records map to the session controller without duplicating scope ownership.
- Add migration steps for legacy recents entries so they reference bookmark IDs; implement backfill scripts if older data lacks audit metadata.
- Extend FilesystemAccessKit error handling to classify stale bookmark resolution failures, surface actionable recovery in the UI, and emit structured diagnostics.
- Update documentation (DocC + CLI guides) to explain bookmark rotation, revocation, and headless authorization flows; coordinate with distribution packaging if new sandbox profiles are needed.
- Expand test coverage: unit tests for ledger edge cases, UI tests for reopen flows, and integration tests verifying hashed logging output.

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
