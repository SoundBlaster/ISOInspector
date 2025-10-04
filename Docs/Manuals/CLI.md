# ISOInspector CLI Manual (Draft)

This manual will track the command-line experience for ISOInspector. Current focus areas align with tasks D1–D4 in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` and the execution workplan.

## Current State
- `isoinspect` binary bootstrapped with a lightweight custom runner to avoid external dependencies in restricted environments.
- Default command prints a welcome message sourced from `ISOInspectorKit` to verify wiring.

## Planned Commands
1. `inspect <file>` — Parse and print the box hierarchy.
2. `validate <file>` — Run validation suite and output diagnostics.
3. `export-json <file>` — Emit JSON representation of parsed boxes.
4. `export-report <file>` — Generate summary reports for batches.

Document concrete examples and options as implementation proceeds.
