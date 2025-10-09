# B4 — Integrate MP4RA Metadata Catalog

## 🎯 Objective

Bundle the MP4 Registration Authority (MP4RA) box metadata with the parser so streaming events include human-readable
names, categories, and structured fallbacks for unknown boxes.

## 🧩 Context

- Execution workplan task **B4** (Phase B — Core Parsing Engine) calls for bundling an MP4RA catalog once the streaming

  pipeline (B3) is in place and for logging unknown types for follow-up
  analysis.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L18-L24】

- The master PRD highlights the need for a rich parsing core that supplies descriptive metadata to the CLI, UI, and app

  components without third-party
  dependencies.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md†L4-L27】

- The PRD backlog emphasizes metadata-rich inspections, including search/filter affordances that rely on semantic box

  data surfaced by the parser.【F:DOCS/AI/ISOViewer/ISOInspector_PRD_TODO.md†L13-L84】

## ✅ Success Criteria

- MP4RA catalog JSON ships inside the Swift package and loads without network access, covering known box types.
- Streaming parse events annotate boxes with names/categories when catalog entries exist and emit structured fallback

  data for unknown entries compatible with the research log pipeline.

- Unit tests cover catalog loading, lookup hits, fallback paths, and ensure streaming performance characteristics remain

  unaffected.

- Documentation (DocC/Markdown) notes how to refresh the catalog and where fallback records appear for follow-up triage.

## 🔧 Implementation Notes

- Normalize the MP4RA dataset into a lightweight JSON resource that can be refreshed via script and bundled for use

  across CLI, UI, and app targets.

- Provide a lightweight `BoxCatalog` service for streaming lookups so metadata

  resolution remains constant time and allocations per box stay minimal.

- Reuse existing research log/fallback infrastructure (e.g., VR-006 logging) so unknown boxes are captured consistently

  for tooling consumers.

- Expose catalog metadata (names, categories, descriptions) through the public API to unblock downstream filters and

  detail panes once UI tasks begin.

## 🧠 Source References

- [`ISOInspector_Master_PRD.md`](../AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [`04_TODO_Workplan.md`](../AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md)
- [`ISOInspector_PRD_TODO.md`](../AI/ISOViewer/ISOInspector_PRD_TODO.md)
- [`DOCS/RULES`](../RULES)
- [`DOCS/TASK_ARCHIVE`](../TASK_ARCHIVE)
