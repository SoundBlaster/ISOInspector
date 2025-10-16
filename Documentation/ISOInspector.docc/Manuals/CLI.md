# ISOInspector CLI Manual

The `isoinspect` command streams ISO Base Media File Format structures from the terminal. It shares parsers with the app, emit
s validation summaries, and can export JSON or binary captures for automation.

## Getting started

1. Build the release binary:
   ```sh
   swift build -c release --product isoinspect
   ```
2. Run the tool with `swift run isoinspect` during development or invoke the compiled binary from `.build/release/isoinspect`.
   The executable registers global flags before dispatching to subcommands.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†
L11-L72】

## Global options

Use these flags before any subcommand:

- `--quiet` (`-q`) suppresses standard output, emitting only errors and summaries.【F:Sources/ISOInspectorCLI/ISOInspectorComman
d.swift†L76-L134】
- `--verbose` prints each message with a `[verbose]` prefix and enables additional diagnostics.【F:Sources/ISOInspectorCLI/ISOIns
pectorCommand.swift†L48-L134】
- `--enable-telemetry` and `--disable-telemetry` override the default streaming telemetry behaviour. The command validates that
mutually exclusive flags are not combined.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L76-L146】

## Sandbox automation

- Pair the CLI with a signed sandbox profile and FilesystemAccessKit bookmarks to run without interactive prompts. Follow the `ISOInspector CLI Sandbox Automation Guide` for provisioning steps, including the `--open` bookmark capture flow and `--authorize` headless execution path.【F:Documentation/ISOInspector.docc/Guides/CLISandboxProfileGuide.md†L1-L124】
- Invoke automation jobs with `sandbox-exec -f <profile>` so the CLI inherits the same entitlements as the notarized app build, preventing accidental unsandboxed runs.

## `inspect` — stream parse events

```
isoinspect [global options] inspect <file> [--research-log <path>]
```

- Streams parse events, validation issues, and research log hooks to stdout using the active formatter.【F:Sources/ISOInspectorC
LI/ISOInspectorCommand.swift†L149-L205】
- If `--research-log` is omitted, events are written to `~/.isoinspector/research-log.json` (macOS) or the user documents direc
tory on mobile platforms via `ResearchLogWriter.defaultLogURL`.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L166-L199】【
F:Sources/ISOInspectorKit/Validation/ResearchLogWriter.swift†L19-L60】
- Exit codes: `0` on success, `3` when parsing fails (I/O or validation pipeline errors).【F:Sources/ISOInspectorCLI/ISOInspecto
rCommand.swift†L191-L205】

### Sample output

```
Research log → /Users/name/.isoinspector/research-log.json
VR-006 schema v1: boxType, filePath, startOffset, endOffset
[willStartBox] ftyp (size: 24)
[didFinishBox] ftyp (elapsed: 0.0004s)
```

## `validate` — summarize issues

```
isoinspect [global options] validate <file>
```

- Aggregates validation issues by severity and prints each rule identifier and message.【F:Sources/ISOInspectorCLI/ISOInspector
Command.swift†L206-L268】
- Exits with code `2` when errors are present, `1` when only warnings remain, and `0` when the file is clean. Exit code `3` ind
icates an I/O or parsing failure.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L255-L267】

## `export` — persist parse artifacts

### JSON tree

```
isoinspect [global options] export json <file> [--output <path>]
```

- Builds the full parse tree and writes a `.isoinspector.json` file next to the input when no output path is provided.【F:Source
s/ISOInspectorCLI/ISOInspectorCommand.swift†L271-L360】
- The exporter reuses streaming events, ensuring parity with the interactive UI.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.
swift†L373-L418】

### Binary capture

```
isoinspect [global options] export capture <file> [--output <path>]
```

- Serializes streaming events for later replay using `ParseEventCaptureEncoder`. Default extension: `.capture`.【F:Sources/ISOIn
spectorCLI/ISOInspectorCommand.swift†L271-L418】

Both export variants validate the destination directory before writing and return exit code `3` if the path is unwritable.【F:So
urces/ISOInspectorCLI/ISOInspectorCommand.swift†L419-L441】

## `batch` — validate many files at once

```
isoinspect [global options] batch <inputs...> [--csv <path>]
```

- Accepts file paths, glob patterns, or directories. Input resolution collects unique files and reports unmatched patterns in s
tderr.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L444-L707】
- Streams each file through the same pipeline, recording box counts and per-severity totals. The summary table prints to stdou
t and can be exported to CSV for regression tracking.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L482-L595】
- Exit codes mirror validation severity: `3` for parse failures, `2` when any file contains errors, `1` when warnings remain, `0`
otherwise.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L584-L595】

## Refreshing the MP4RA catalog

The CLI package still ships the legacy runner helpers for refreshing the bundled MP4 Registration Authority catalog:

```
isoinspect mp4ra refresh [--output <path>] [--source <url>]
```

- Downloads the latest JSON catalog and rewrites `Sources/ISOInspectorKit/Resources/MP4RABoxes.json` by default.【F:Sources/ISOI
nspectorCLI/CLI.swift†L40-L213】
- Use `--output` to store the snapshot elsewhere or `--source` to test alternate registry URLs.【F:Sources/ISOInspectorCLI/CLI.s
wift†L133-L213】

## Research log reference

Research log entries capture VR-006 unknown-box diagnostics for later analysis. Logs are deduplicated and persisted atomically
to the path configured by the `inspect` command.【F:Sources/ISOInspectorKit/Validation/ResearchLogWriter.swift†L19-L76】

## Troubleshooting

- **Permission errors** — Ensure the destination directory exists and is writable before running `export` or `batch` with `--cs
v`; the CLI validates parent directories before writing.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L419-L441】【F:Sour
ces/ISOInspectorCLI/ISOInspectorCommand.swift†L567-L583】
- **Unexpected exit codes** — Review stderr for parse or validation failures. Non-zero exit statuses map directly to severity co
unts as described above.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L255-L267】【F:Sources/ISOInspectorCLI/ISOInspecto
rCommand.swift†L584-L595】
- **MP4RA refresh issues** — Provide a writable `--output` path and confirm network access to the registry source when using th
e legacy refresh helper.【F:Sources/ISOInspectorCLI/CLI.swift†L133-L213】
