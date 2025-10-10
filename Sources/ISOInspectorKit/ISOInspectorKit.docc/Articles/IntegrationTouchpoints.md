# IntegrationTouchpoints

Every ISOInspector surface consumes ISOInspectorKit APIs. The CLI wires box
parsing events into command handlers, while the SwiftUI app binds them to
observable view models. These integrations ensure the package remains the single
source of truth for parsing, validation, and exporting behavior.

## CLI integration

The `isoinspect` executable executes `ParsePipeline.live()` and streams
validation issues to the console, mirroring the workflows described in the
execution guide. Refer to the ISOInspectorCLI DocC catalog (`Sources/ISOInspectorCLI/ISOInspectorCLI.docc`)
for commands that depend on the kit.

## App integration

`ISOInspectorApp` creates document-based scenes that subscribe to the pipeline
and surface research telemetry in previews and runtime UI. The module overview in
the ISOInspectorApp DocC catalog (`Sources/ISOInspectorApp/ISOInspectorApp.docc`)
details how validation issues surface in SwiftUI.

## Extending integrations

New features must start in ISOInspectorKit. Update the CLI and app
simultaneously, leaving focused @todo notes if propagation needs to be split into
additional tasks.
