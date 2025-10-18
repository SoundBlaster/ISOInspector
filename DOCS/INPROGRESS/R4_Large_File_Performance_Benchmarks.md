# R4 — Large File Performance Benchmarks

## 🎯 Objective

Define a repeatable benchmarking protocol for exercising ISOInspector against 20GB-class media so performance budgets
stay credible ahead of release and hardware validation.

## 🧩 Context

- The master PRD commits the product to parsing and validating files up to 20GB while sustaining low-latency updates, so

  large-file performance scenarios must be captured before final release.

- Phase F of the execution workplan highlights benchmark governance as a quality gate, and existing XCTest Metric

  harnesses need guidance for scaling to macOS hardware runners once available.

- The research backlog identifies unanswered questions around fixture creation, virtualization, and instrumentation for

  these workloads, requiring deeper investigation before implementation tasks proceed.

## ✅ Success Criteria

- Benchmark plan documents target scenarios (CLI validation and UI streaming) including file sizes, expected runtime

  ceilings, and memory guardrails.

- Fixture acquisition strategy enumerates concrete approaches for generating or sourcing 20GB-class assets with

  licensing and storage notes.

- Tooling and instrumentation matrix covers required utilities (ffprobe, MP4Box, mp4dump, signposts, XCTest Metrics) and

  clarifies macOS-specific dependencies.

- Risk assessment outlines fallback options when macOS runners are unavailable, including degraded Linux smoke runs and

  manual validation slots.

- Research outputs are archived under `DOCS/INPROGRESS/` with clear linkage back to F2 implementation requirements.

## 🔧 Implementation Notes

- Survey open-source references (Bento4, FFmpeg, GPAC) for existing benchmarking practices that can inform workload

  mixes.

- Capture automation constraints for notarized macOS runners so release readiness rehearsal can reuse the same

  infrastructure.

- Propose data generation recipes (e.g., Bento4 `mp4fragment`, `mp4mux`, or synthetic fillers) and define storage footprint expectations for CI caches.
- Detail how to extend current XCTest Metric configurations to operate against oversized fixtures without exceeding CI

  timeouts.

- Document observability hooks—logging categories, signposts, or telemetry toggles—that must be enabled during

  performance sweeps.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`05_Research_Gaps.md`](../AI/ISOInspector_Execution_Guide/05_Research_Gaps.md)
- [`02_ISOInspector_AI_Source_Guide.md`](../AI/02_ISOInspector_AI_Source_Guide.md)
- [`44_F2_Configure_Performance_Benchmarks.md`](../TASK_ARCHIVE/44_F2_Configure_Performance_Benchmarks/44_F2_Configure_Performance_Benchmarks.md)
