# CommandReference

ISOInspectorCLI exposes subcommands that map directly to ISOInspectorKit
features. The catalog grows alongside the kit and should always reflect the
latest validation and export capabilities.

## Inspect

```
$ isoinspect inspect <file.mp4>
```

Runs the streaming parser, printing validation issues, research log notes, and a
summary of the MP4 structure. This command is ideal for quick verification or as
a CI gate.

## Export JSON

```
$ isoinspect export json <file.mp4> --output ./capture.json
```

Generates a JSON representation of the parsed boxes using the kit's export
helpers. Output can be diffed or shared with downstream analysis tooling.

## Export Binary Capture

```
$ isoinspect export capture <file.mp4> --output ./capture.isoinspect
```

Persists a binary capture suitable for offline replays inside integration tests
or the app's research log importer.

## Refresh MP4RA Catalog

```
$ isoinspect mp4ra refresh --output ./MP4RABoxes.json
```

Pulls the MP4 Registration Authority catalog and writes a merged JSON resource so
the kit stays aligned with upstream metadata.

## Next steps

See the ISOInspectorKit DocC catalog for APIs powering these commands and the
ISOInspectorApp catalog for the SwiftUI experience that consumes the same parsing
pipeline.
