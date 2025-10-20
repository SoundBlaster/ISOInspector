# C17 — `mdat` Box Parser

## 🎯 Objective

Implement a parser that records the media data (`mdat`) box's byte range so the UI and CLI can display payload boundaries without materializing large media blobs.

## 🧩 Context

- Phase C backlog flags the `mdat` parser as a remaining baseline deliverable that must capture offsets and sizes while skipping the payload to avoid memory pressure.
- The technical spec requires `mdat` handling to skip payload data while still tracking metadata for downstream consumers.
- Product requirements call out multi-gigabyte `mdat` boxes as a critical streaming scenario, reinforcing the need for efficient offset bookkeeping instead of loading raw bytes.

## ✅ Success Criteria

- Register an `mdat` parser in `BoxParserRegistry` that emits a structured payload containing the header start offset, total size, and payload length while seeking past the media bytes.
- Ensure the streaming reader advances using `seek`/`skip` semantics so even multi-gigabyte payloads do not allocate buffers.
- Extend unit tests and JSON export baselines to prove offsets and sizes are reported for regular and large-size `mdat` fixtures without impacting existing validation rules (e.g., VR-005 ordering checks).

## 🔧 Implementation Notes

- Reuse the shared chunked reader helpers to compute start offsets and to jump over payload bytes for both 32-bit and
  large-size headers.
- Surface the recorded metadata through existing detail/hex view models and CLI export structures so downstream
  components can surface payload boundaries without reading the media data.
- Verify interactions with validation logging, ensuring that the parser cooperates with existing VR-005 handling when `mdat` precedes `moov` in streaming files.

## 🧠 Source References

- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`03_Technical_Spec.md`](../AI/ISOInspector_Execution_Guide/03_Technical_Spec.md)
- [`02_Product_Requirements.md`](../AI/ISOInspector_Execution_Guide/02_Product_Requirements.md)
- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`DOCS/RULES`](../RULES)
- Relevant research archives under [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
