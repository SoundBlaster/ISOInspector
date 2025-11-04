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

When tolerant mode is enabled with `--tolerant`, the CLI appends a corruption
summary after the parse completes. The summary lists error, warning, and info
totals along with the deepest affected depth so operators can gauge severity
without opening the UI.

## Validate

```
$ isoinspect validate <file.mp4>
```

Streams validation issues for a single file and exits non-zero when warnings or
errors are encountered. Use this command when integrating into lightweight CI
jobs that operate on individual samples.

## Batch Validate

```
$ isoinspect batch <inputs...> [--csv summary.csv]
```

Processes multiple files in one run, expanding directories or glob patterns and
emitting an aggregated summary table. When `--csv` is provided the CLI writes a
machine-readable report that mirrors the console output, making it ideal for CI
pipelines that need to archive validation results.

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
