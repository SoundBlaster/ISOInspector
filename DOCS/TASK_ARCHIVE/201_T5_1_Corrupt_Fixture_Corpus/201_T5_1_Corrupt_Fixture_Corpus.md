# T5.1_Corrupt_Fixture_Corpus

## 🎯 Objective

Establish a dedicated corrupted media fixture corpus that exercises the tolerant parsing pipeline across diverse failure modes so regression suites and manual QA can validate resilience claims.

## 🧩 Context

- Phase T5 of the Corrupted Media Tolerance roadmap calls for purpose-built fixtures capturing truncated boxes, overlapping ranges, inconsistent sample tables, and related structural faults.
- Existing tolerant parsing features (T1–T4) now surface detailed `ParseIssue` records and UI affordances but rely on ad-hoc malformed samples.
- No current assets satisfy the acceptance criteria of covering at least ten distinct corruption patterns with curated metadata for downstream automation.

## ✅ Success Criteria

- At least ten fixtures representing unique corruption scenarios (e.g., truncated payload, size overflow, overlapping child ranges, invalid sample tables, missing required boxes) live under `Fixtures/Corrupt/` with descriptive filenames.
- Each fixture includes a machine-readable manifest entry describing corruption type, affected boxes, and expected `ParseIssue` codes.
- Automated sanity checks (unit or integration tests) load a subset of the new fixtures to ensure tolerant parsing completes and records the documented issues without crashes.

## 🔧 Implementation Notes

- Inventory existing malformed samples to avoid duplication, then prioritize gaps called out in the tolerance PRD.
- Define a manifest schema (JSON or YAML) for corruption metadata so future tasks (T5.2, T5.3) can consume it programmatically.
- Generate fixtures via scripted manipulations of known-good assets (e.g., truncate bytes, patch headers) to keep creation reproducible; document scripts under `scripts/fixtures/` if needed.
- Validate fixtures manually with the CLI `inspect`/`export-json` commands in tolerant mode before checking in to confirm issues fire as expected.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- Relevant archives in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
