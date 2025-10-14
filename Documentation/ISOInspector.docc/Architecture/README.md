# ISOInspector Architecture Overview

This document tracks the evolving system architecture as we progress through the phases outlined in `DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md` and the execution workplan in `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`.

## Current State
- **Packages**: `ISOInspectorKit` (core library), `ISOInspectorCLI` (command-line interface), `ISOInspectorApp` (SwiftUI shell).
- **Documentation**: DocC catalog stub at `Documentation/ISOInspector.docc` and Markdown guides within `/Docs`.
- **Testing**: XCTest suites confirm the shared welcome messaging used by each target.

## Near-Term Evolution
1. Implement IO foundations (Tasks A1–A4).
2. Define box parsing core (Tasks B1–B4).
3. Expand CLI commands per D1–D4, backed by the parsing engine.
4. Flesh out the SwiftUI interface according to Phase C requirements.
