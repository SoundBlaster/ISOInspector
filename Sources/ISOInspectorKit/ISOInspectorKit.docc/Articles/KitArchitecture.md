# KitArchitecture

ISOInspectorKit organizes its parsing pipeline around a streaming
`ParsePipeline` that reads MP4 boxes from any `RandomAccessReader`. The
pipeline emits structured `BoxEvent` values that feed validation rules and
exporters. Streaming consumers accumulate those events into immutable ``BoxNode``
snapshots so the UI, CLI, and exporters share a canonical tree model. This
mirrors the architecture outlined in the master product requirements document
and the execution workplan so the library stays in sync with the higher level
ISOInspector deliverables.

## Core layers

- **IO adapters** map files into memory or stream from file handles while
  guaranteeing bounds-checked reads.
- **Box decoding** converts raw header data into strongly typed `BoxHeader`
  structures with offsets, sizes, and UUID details.
- **Validation** applies structural rules (size checks, ordering, metadata)
  derived from the documentation backlog, surfacing warnings through the shared
  telemetry pipeline.
- **Tree builders** materialize streaming events into ``BoxNode`` trees that
  capture headers, catalog metadata, parsed payloads, validation issues, and
  child relationships in a sendable aggregate.
- **Exporters** transform parsed nodes into JSON or binary capture formats for
  downstream tooling including the CLI.

## Related documentation

- <doc:IntegrationTouchpoints>
- ISOInspectorCLI DocC catalog (`Sources/ISOInspectorCLI/ISOInspectorCLI.docc`)
- ISOInspectorApp DocC catalog (`Sources/ISOInspectorApp/ISOInspectorApp.docc`)
