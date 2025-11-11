# T5.5 — Tolerant Parsing Fuzzing Harness

## 🎯 Objective
Build an automated fuzzing harness that exercises tolerant parsing against 100+ synthetically corrupted MP4 fixtures and demonstrates a 99.9% crash-free completion rate so lenient mode can ship with confidence.

## 🧩 Context
- Phase T5 focuses on hardening tolerant parsing; Task **T5.5** remains outstanding after the corrupt fixture corpus (**T5.1**) and regression suite (**T5.2**) landed.【F:DOCS/AI/Tolerance_Parsing/TODO.md†L98-L125】
- Crash-free execution is a gating risk called out in the tolerance parsing integration summary checklist.【F:DOCS/AI/Tolerance_Parsing/IntegrationSummary.md†L613-L687】
- Existing fixtures cover specific corruptions, but we still lack randomized mutation coverage to stress traversal guards and validation rules beyond deterministic cases.

## ✅ Success Criteria
- An XCTest-driven fuzz suite generates or mutates ≥100 corrupt payloads per run and feeds them through the tolerant parsing pipeline.
- Harness reports aggregate completion statistics and asserts that all cases complete without crashes or unexpected fatal errors (≥99.9% success for the batch).
- Failures capture reproduction artifacts (seed, mutation description, minimal repro payload) for archival under `Documentation/CorruptedFixtures/` when encountered.
- CI configuration executes the fuzz suite on Linux runners without timeouts, keeping total runtime within the existing benchmark budget.

## 🔧 Implementation Notes
- Reuse the `CorruptFixtureBuilder` utilities from Task T5.1 archives to seed base payloads, then apply deterministic mutations (e.g., header truncation, overlapping ranges, bogus sizes) driven by seeded `RandomNumberGenerator`s so failures are reproducible.
- Introduce a dedicated test target module (e.g., `TolerantParsingFuzzTests`) that iterates over generated cases inside a single XCTest, recording completion counts and measuring guard coverage.
- Integrate with `ParsePipeline.Options` to force tolerant mode and clamp issue budgets so runaway corruption still terminates; assert strict mode remains unaffected by running a small control sample.
- Emit structured diagnostics (seed, mutation kind, offsets) via `XCTAttachment` for any failure and optionally persist the offending payload using the existing fixture manifest helpers.
- Update documentation trackers (`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`, `DOCS/AI/Tolerance_Parsing/TODO.md`) once the harness lands so stakeholders know crash-free validation is covered.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/AI/Tolerance_Parsing/IntegrationSummary.md`](../AI/Tolerance_Parsing/IntegrationSummary.md)
- [`DOCS/TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus/Summary_of_Work.md`](../TASK_ARCHIVE/201_T5_1_Corrupt_Fixture_Corpus/Summary_of_Work.md)
- [`DOCS/TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/Summary_of_Work.md`](../TASK_ARCHIVE/203_T5_2_Regression_Tests_for_Tolerant_Traversal/Summary_of_Work.md)
