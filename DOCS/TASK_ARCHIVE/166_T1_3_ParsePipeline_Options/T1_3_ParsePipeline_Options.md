# T1.3 ParsePipeline Options

## 🎯 Objective
Define a configurable `ParsePipeline.Options` structure that lets the parser toggle between strict and tolerant execution modes while exposing limits for corruption reporting and payload validation depth.

## 🧩 Context
- Tolerance parsing initiative Phase T1 requires runtime switches that distinguish strict CLI runs from lenient UI sessions.
- Existing validation configuration (Task B7) already surfaces rule presets; this task complements that work by adding parser-level controls noted in the tolerance parsing workplan.
- Current pipeline behavior aborts on structural errors; introducing options is the prerequisite for continuing after corrupt headers and recording `ParseIssue` metadata.

## ✅ Success Criteria
- `ParsePipeline.Options` (or equivalent) type exists in `ISOInspectorKit` with documented properties: `abortOnStructuralError`, `maxCorruptionEvents`, and `payloadValidationLevel` (enum covering strict vs. limited payload parsing).
- Default options selected for each client: CLI defaults to strict (`abortOnStructuralError == true`), app/SDK defaults to tolerant (`false`) with sensible corruption/event caps.
- Unit tests cover serialization or initialization defaults and verify that pipeline components receive the options via dependency injection.
- Public API documentation updated where necessary so downstream callers understand new configuration entry points.

## 🔧 Implementation Notes
- Audit `ParsePipeline` initialization (likely in `Sources/ISOInspectorKit/Parsing/`) and thread the new options through constructors or builder methods.
- Consider namespacing `payloadValidationLevel` via a dedicated enum (e.g., `.full`, `.structureOnly`) with room for expansion highlighted in the tolerance PRD.
- Update CLI/app wiring to pass explicit options; for now stubs may live near `ISOInspectorKit+Configuration.swift` and `ISOInspectorApp` document controllers.
- Coordinate with upcoming T1.4 refactors so options plumbing does not conflict with the Result-based decoder work.
- Capture decision notes on maximum corruption events (initial recommendation: 500 before halting) and document rationale for future tuning.

## 🧠 Source References
- [`DOCS/AI/Tolerance_Parsing/TODO.md`](../AI/Tolerance_Parsing/TODO.md)
- [`DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md`](../../Documentation/ISOInspector.docc/Guides/ReleaseReadinessRunbook.md)
