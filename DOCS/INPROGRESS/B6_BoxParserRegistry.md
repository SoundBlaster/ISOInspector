# B6 — Box Parser Registry

## 🎯 Objective

Establish a registry in ISOInspectorCore that maps each known MP4/ISO BMFF box type to its concrete parser so the
streaming pipeline can construct structured payloads instead of opaque blobs, while preserving safe fallbacks for
unknown leaf boxes.

## 🧩 Context

- Phase B of the execution workplan still lists Task B6 (Medium priority) to add JSON and binary export modules once the
  streaming pipeline work from B3 is complete, signalling that structured box payloads are still needed for exporters.
- The detailed backlog highlights `BoxParserRegistry` as the mechanism to associate box identifiers with parser strategies, defaulting to container or opaque leaf behaviors when no specialized handler exists.

## ✅ Success Criteria

- Registry object exposes lookup/registration APIs consumed by the streaming pipeline without breaking existing tests.
- Known box types (ftyp, moov, trak, mdia, etc.) resolve to appropriate parser implementations covering high-priority
  structures listed in the PRD backlog.
- Unknown or unsupported boxes fall back to a safe opaque leaf handler while still emitting metadata for research
  logging.
- Unit tests cover registry defaults, overrides, and integration with at least one specialized parser.

## 🔧 Implementation Notes

- Start from the current streaming parser entry points in `ISOInspectorCore` and thread the registry through existing factories to avoid broad refactors.
- Seed the registry with specialized parsers for high-signal boxes already described in Phase C backlog items (e.g., `ftyp`, `mvhd`, `tkhd`) to align with upcoming UI feature needs.
- Ensure registry configuration remains extensible so CLI/App targets can inject feature flags or experimental parsers
  without re-linking core modules.
- Update exporter scaffolding to consume structured payloads produced via the registry, verifying compatibility with
  existing JSON/binary fixtures.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
