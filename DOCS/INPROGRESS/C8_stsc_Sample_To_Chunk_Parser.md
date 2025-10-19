# C8 — `stsc` Sample-To-Chunk Parser

## 🎯 Objective

Implement a robust parser for the Sample-to-Chunk (`stsc`) box so the pipeline can translate sample table metadata into UI and validation insights without relying on placeholder decoding.

## 🧩 Context

- The detailed backlog marks `C8 — stsc` as a **Critical P0+** deliverable that must ship ahead of other Phase C sample table work. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L186-L200】
- Implementing `stsc` is necessary to complete the movie track metadata surface alongside existing `stsd`, `mdhd`, and `mvhd` parsers described in the execution workplan. 【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L74-L120】
- The parser must align with the master PRD goal of exposing precise sample table structures (`stsc`, `stsz/stz2`, `stco/co64`) used by both the CLI and SwiftUI experiences. 【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L21-L64】

## ✅ Success Criteria

- Decode the `stsc` FullBox header (version, flags) using the shared `FullBoxReader` helper and surface creation of structured fields for UI/CLI consumption.
- Parse `entry_count` followed by every `SampleToChunk` tuple (`first_chunk`, `samples_per_chunk`, `sample_description_index`), capturing byte ranges for hex highlighting.
- Support version 0 semantics per ISO BMFF (future-proof version handling by validating expected field widths and
  gracefully bailing when unknown flags appear).
- Emit validation-friendly detail metadata that downstream rules can use to cross-check related boxes (`stsz`, `stco`).
- Provide placeholder messaging when the payload is truncated or inconsistent so validation can report actionable errors
  instead of crashing.

## 🔧 Implementation Notes

- Reuse `FullBoxReader` and existing numeric helpers from `BoxParserRegistry` to avoid duplicating bounds checks when iterating through entries.
- Consider exposing a typed detail payload (e.g., `ParsedBoxPayload.Detail.sampleToChunk(entries:)`) to support UI table rendering and CLI export formatting.
- Ensure parsing logic is resilient against large `entry_count` values by guarding against integer overflow (`first_chunk` and `samples_per_chunk` are 32-bit unsigned integers).
- Coordinate with upcoming C9/C10 tasks so shared sample table structures (e.g., models in `ISOInspectorKit`) can be reused across multiple parsers.
- Add fixture coverage by extending existing sample files (baseline, fragmented, DASH) and prepare to document expected
  results in the Task Archive after implementation.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- Archived context in [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
