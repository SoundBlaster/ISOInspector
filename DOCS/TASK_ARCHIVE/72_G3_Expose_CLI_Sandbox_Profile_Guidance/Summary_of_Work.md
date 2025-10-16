# Summary of Work — G3 Expose CLI Sandbox Profile Guidance

## Completed Tasks

- Authored the CLI sandbox automation guide documenting how to pair `isoinspector` with signed sandbox profiles, FilesystemAccessKit bookmarks, and the `--open`/`--authorize` workflow for headless execution.【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L1-L124】
- Linked the CLI manual and program documentation back to the new guide so operators can discover sandbox automation requirements alongside existing command help.【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L18-L29】
- Updated workplan, PRD TODO, and next-task trackers to record completion of the sandbox guidance milestone and reference the archived materials.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L70-L74】【F:DOCS/AI/ISOInspector_PRD_TODO.md†L261-L262】【F:DOCS/INPROGRESS/next_tasks.md†L5-L11】

## Implementation Notes

- Guidance highlights existing App Sandbox entitlements, shows a minimal `.sb` allowlist, and maps FilesystemAccessKit APIs (`openFile`, `resolveBookmarkData`) to CLI automation commands so future code changes stay aligned with security expectations.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L15】【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L6-L69】【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L13-L100】
- Troubleshooting and verification checklists call out stale bookmark handling, sandbox profile signing, and the `swift test --disable-sandbox` regression run so QA can reuse the steps when validating headless scenarios.【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L96-L124】

## Verification

- `swift test --disable-sandbox`

## Follow-Up

- Track Task G4 for zero-trust logging and audit trail updates once sandbox automation flows start emitting telemetry.
