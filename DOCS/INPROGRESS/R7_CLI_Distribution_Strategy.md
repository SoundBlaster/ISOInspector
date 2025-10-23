# R7 — CLI Distribution Strategy

## 🎯 Objective
Map out a signed distribution plan for the `isoinspect` CLI that keeps parity with the app release cadence, covering notarized macOS binaries, Homebrew-style tap publication, and Linux artifact delivery so release engineering can ship automation-friendly builds alongside GUI releases.

## 🧩 Context
- The release runbook already enumerates required notarization, stapling, and artifact publishing steps for the macOS app and CLI binaries, but it stops short of prescribing distribution channels or packaging formats for long-term maintenance.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L1-L68】【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L82-L118】
- The CLI manual documents command capabilities, sandbox automation guidance, and current build commands that any distribution workflow must preserve.【F:Documentation/ISOInspector.docc/Manuals/CLI.md†L1-L116】
- Workplan research tracks R7 as the remaining open investigation supporting CLI release quality, making this the next unblocker once hardware-bound items are deferred.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L19-L48】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L60-L74】

## ✅ Success Criteria
- Delivery of a decision record outlining macOS notarized ZIP/DMG, Homebrew tap, and Linux packaging recommendations with signing implications.
- Updated release checklist tasks and automation hooks necessary to ship the CLI artifacts in tandem with app releases, including storage locations and checksum policies.
- Risk assessment for each distribution channel (licensing, tooling prerequisites, update cadence) with mitigation steps and owner hand-offs captured in the research output.

## 🔧 Implementation Notes
- Audit current CLI build and notarization steps (`swift build -c release --product ISOInspectorCLI`, `scripts/notarize_app.sh`) and record which portions can be reused or need adjustments for standalone distribution.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L82-L118】
- Evaluate macOS distribution paths (signed ZIP, notarized DMG, Homebrew tap formula) including signing identities, tap hosting, update automation, and verification commands.
- Investigate Linux distribution expectations (static vs. dynamic builds, package managers such as APT/Homebrew on Linux, checksum publication) and document required CI/CD changes or blockers.
- Define artifact naming, storage layout, and checksum publication rules so QA and release engineering can confirm binary provenance during go/no-go reviews.【F:Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md†L119-L160】
- Summarize findings in a research report linked from the release runbook and backlog, highlighting any dependencies on external approvals (e.g., signing certificates, Homebrew tap ownership).

## 🧠 Source References
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`](../../Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md)
- [`Documentation/ISOInspector.docc/Manuals/CLI.md`](../../Documentation/ISOInspector.docc/Manuals/CLI.md)
- Any relevant archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)

