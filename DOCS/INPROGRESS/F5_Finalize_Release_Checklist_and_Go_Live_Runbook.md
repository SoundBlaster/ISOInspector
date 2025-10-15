# F5 — Finalize Release Checklist and Go-Live Runbook

## 🎯 Objective

Document a repeatable release checklist and go-live runbook that covers QA gates, documentation updates, and
distribution packaging so the team can publish ISOInspector builds confidently.

## 🧩 Context

- [Execution workplan task F5](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md) schedules the release checklist
  after distribution setup (E4) and performance benchmarking (F2).
- Recent distribution work introduced shared metadata, notarization tooling, and entitlement configurations that the
  runbook must reference.【F:DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/Summary_of_Work.md†L5-L24】
- Performance benchmarks exist for CLI and UI pipelines, with macOS Combine measurements pending hardware access; the
  runbook should capture the required evidence
  trail.【F:DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md†L14-L19】【F:DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md†L6-L30】

## ✅ Success Criteria

- Checklist enumerates pre-release validation steps (tests, benchmarks, linting, DocC generation) with clear owners and
  tooling references.
- Runbook spells out packaging steps for notarized DMG/TestFlight builds using the shared distribution metadata and
  scripts.
- Documentation deliverables (README, manuals, changelog) have an explicit update checklist tied to release versioning.
- Go/no-go sign-off captures required evidence, including outstanding macOS benchmark runs or entitlements reviews.

## 🔧 Implementation Notes

- Reference `DistributionMetadata.json`, `Project.swift`, and `scripts/notarize_app.sh` so release engineers reuse the established configuration paths.【F:DOCS/TASK_ARCHIVE/55_E4_Prepare_App_Distribution_Configuration/Summary_of_Work.md†L7-L21】
- Incorporate QA signals from the performance benchmarks and UI automation suites, noting current macOS hardware
  blockers and mitigation
  steps.【F:DOCS/TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/Summary_of_Work.md†L14-L19】【F:DOCS/TASK_ARCHIVE/48_macOS_SwiftUI_Automation_Streaming_Default_Selection/48_macOS_SwiftUI_Automation_Streaming_Default_Selection.md†L5-L20】
- Call out release artifact storage expectations (CI DocC archives, CLI binaries) and where to publish summary notes for
  stakeholders.
- Include a post-release checklist for updating `todo.md`, backlog statuses, and task archives to mark the release effort complete.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
