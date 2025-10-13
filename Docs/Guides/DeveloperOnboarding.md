# ISOInspector Developer Onboarding Guide

This guide helps new contributors prepare their environment, understand the repository layout, and find the primary API entry points across the ISOInspectorKit library, CLI, and app surfaces. It complements the project README and execution rules that define the XP + TDD workflow used across the repo.【F:README.md†L1-L41】【F:DOCS/RULES/02_TDD_XP_Workflow.md†L1-L68】

## 1. Toolchain & Prerequisites

| Requirement | Notes |
| --- | --- |
| Swift toolchain | Install Swift **6.0.1 or newer**; Linux contributors can use the toolchain shipped in CI containers.【F:README.md†L17-L24】 |
| Xcode (Apple platforms) | Use the latest Xcode 15+ release to build SwiftUI targets and run DocC locally.【F:README.md†L17-L24】 |
| Node & `npx` | Required if you opt into the repo-provided pre-commit hook for Markdown linting.【F:README.md†L26-L40】 |
| Docker (optional) | Mirrors CI SwiftLint runs via `docker run ghcr.io/realm/swiftlint:0.53.0 lint --strict`.【F:README.md†L63-L74】 |

### Recommended macOS packages
- [swiftlint](https://github.com/realm/SwiftLint) for local linting parity with CI.【F:README.md†L63-L74】
- [docc](https://www.swift.org/documentation/docc/) support ships with Xcode; install command-line tools to build documentation archives.【F:README.md†L41-L55】

## 2. Repository Bootstrap

1. Clone the repository and change into the workspace directory.
2. (Optional) Enable the repo-managed Git hooks so Markdown linting runs automatically:
   ```sh
   git config core.hooksPath .githooks
   ```
   The hook runs `npx markdownlint-cli2 --fix 'DOCS/INPROGRESS/**/*.md' 'DOCS/COMMANDS/**/*.md' 'DOCS/RULES/**/*.md'`. Re-run the command if local git config resets the hooks path.【F:README.md†L26-L40】
3. Review `DOCS/RULES/02_TDD_XP_Workflow.md`, `DOCS/RULES/04_PDD.md`, and `DOCS/RULES/07_AI_Code_Structure_Principles.md` before starting a task. These rules govern iteration cadence, puzzle-driven development, and file-structure guardrails.【F:DOCS/RULES/02_TDD_XP_Workflow.md†L1-L112】【F:DOCS/RULES/04_PDD.md†L1-L74】【F:DOCS/RULES/07_AI_Code_Structure_Principles.md†L1-L80】
4. Sync `todo.md` by regenerating puzzles if you add or remove any `@todo` comments. The file reflects outstanding work tracked by the PDD workflow.【F:DOCS/RULES/04_PDD.md†L17-L74】

## 3. Build, Test, and QA Loops

The default outside-in workflow keeps the entire workspace green. Run the following commands early and often:

```sh
swift build
swift test
```
These commands compile every target and execute all XCTest suites across ISOInspectorKit, ISOInspectorCLI, and ISOInspectorApp.【F:README.md†L17-L32】

For linting parity with CI, invoke the same helper scripts the pipelines use:

```sh
scripts/swiftlint-format.sh
# or run the containerized lint step directly

docker run --rm -v "$(pwd)":/workspace ghcr.io/realm/swiftlint:0.53.0 lint --strict
```
SwiftLint must pass before changes merge to `main`.【F:README.md†L63-L74】

Generate DocC archives whenever you change public APIs or documentation:

```sh
scripts/generate_documentation.sh
```
The script renders DocC bundles for ISOInspectorKit, the CLI, and the SwiftUI app under `Documentation/DocC/<Target>`, fulfilling the DocC publishing workflow completed under task A3.【F:README.md†L41-L55】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L8-L24】

## 4. Architecture Overview

ISOInspector is a Swift Package Manager workspace with three primary targets plus supporting DocC catalogs.【F:README.md†L5-L20】 The execution plan highlights dependencies between phases A (infrastructure), B (parsing core), C (SwiftUI), and downstream documentation tasks like F3.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L1-L52】 The high-level boundaries are:

- **ISOInspectorKit** — Core parsing, validation, export, and research logging utilities. All public APIs live here and power both CLI and app experiences.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L1-L120】【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L1-L40】【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L1-L52】
- **ISOInspectorCLI** — Command-line driver built on `swift-argument-parser`, streaming parse events, validations, exports, and batch summaries to the console or files.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L1-L135】
- **ISOInspectorApp** — SwiftUI application that hosts the parser pipeline, tree explorer, detail view, and annotation subsystems with Combine-backed stores.【F:Sources/ISOInspectorApp/AppShellView.swift†L1-L105】【F:Sources/ISOInspectorApp/State/ParseTreeStore.swift†L1-L80】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L1-L70】

Completed dependencies referenced in the task definition provide onboarding resources:
- **A3 — DocC scaffolding**: DocC catalogs sit in `Sources/*/*.docc`, and publishing scripts keep archives up to date.【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L8-L24】
- **B6 — Export modules**: `ISOInspectorKit/Export` exposes JSON/tree exporters that the CLI and app share for save operations.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L1-L52】
- **C3 — Detail & hex inspectors**: SwiftUI detail panes wire payload metadata, highlights, and validation issues into the UI so onboarding developers can see how view models depend on kit payloads.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L1-L80】【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L81-L160】

## 5. ISOInspectorKit API Outline

The library organizes parsing responsibilities into focused modules:

- **IO** — `ChunkedFileReader` wraps `FileHandle` to provide cached, chunk-aligned reads and satisfies the `RandomAccessReader` protocol used by streaming pipelines.【F:Sources/ISOInspectorKit/IO/ChunkedFileReader.swift†L1-L84】
- **Streaming pipeline** — `ParsePipeline.live()` constructs an `AsyncThrowingStream` over MP4 boxes using `StreamingBoxWalker`, enriching events with metadata, validation, and research logging.【F:Sources/ISOInspectorKit/ISO/ParsePipeline.swift†L43-L120】【F:Sources/ISOInspectorKit/ISO/StreamingBoxWalker.swift†L1-L60】
- **Validation** — `BoxValidator` aggregates rule objects (VR-001—VR-006) that annotate parse events with actionable issues consumed by the CLI and app UI.【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L1-L80】
- **Metadata catalogs** — `FourCharContainerCode` and `MediaAndIndexBoxCode` centralize structural heuristics for container traversal and streaming hints, feeding UI filters and CLI classifiers.【F:Sources/ISOInspectorKit/ISO/FourCharContainerCode.swift†L1-L160】【F:Sources/ISOInspectorKit/ISO/MediaAndIndexBoxCode.swift†L1-L120】
- **Export** — `JSONParseTreeExporter` and related capture codecs turn streaming snapshots into persisted JSON trees used by CLI `export` commands and app save actions.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L1-L68】【F:Sources/ISOInspectorKit/Export/ParseTreeBuilder.swift†L1-L80】
- **Research logging** — VR-006 hooks populate research logs for unknown boxes so future contributors can extend the parser safely; `ResearchLogEntry` emits schema-aligned records consumed by automation.【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L56-L120】【F:Sources/ISOInspectorKit/Validation/ResearchLogWriter.swift†L1-L80】

### Key extension points
- Add new box parsers by registering them with `BoxParserRegistry.shared` in DocC tutorials or dedicated modules. Use existing `ISOInspectorKit/ISO` decoders as references.
- Contribute validation rules by creating new `BoxValidationRule` implementations and wiring them into `BoxValidator.defaultRules` alongside VR-001—VR-006.【F:Sources/ISOInspectorKit/Validation/BoxValidator.swift†L1-L80】
- Export pipelines accept custom encoders—pass an alternate `JSONEncoder` to `JSONParseTreeExporter` when new payload fields require formatting tweaks.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L1-L40】

## 6. CLI Surface Overview

`ISOInspectorCommand` exposes the top-level `isoinspector` executable with four primary subcommands backed by shared kit services.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L1-L135】

| Command | Description |
| --- | --- |
| `inspect` | Streams parse events, validation summaries, and research log hooks for a single media file. Accepts optional research-log output locations and verbosity toggles.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L48-L110】 |
| `validate` | Runs validation-focused output, reusing the shared context store and telemetry toggles (see `Commands.Validate`).【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L136-L220】 |
| `export` | Produces JSON or binary captures using the export modules from ISOInspectorKit (see `Commands.Export`).【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L221-L340】 |
| `batch` | Processes multiple files, aggregating summaries via `BatchValidationSummary`. Use this for CI regressions and performance harnesses.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L341-L520】【F:Sources/ISOInspectorCLI/BatchValidationSummary.swift†L1-L120】 |

Global flags (`--quiet`, `--verbose`, telemetry toggles) are managed through `GlobalOptions`, which updates the shared `ISOInspectorCommandContextStore` so all subcommands share environment state.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L18-L80】

## 7. App Surface Overview

The SwiftUI app wraps the same streaming pipeline with Combine stores, annotation sessions, and accessibility helpers:

- **App shell** — `AppShellView` presents the navigation split view, document importer, recents list, and onboarding screen, delegating file loading to the session controller.【F:Sources/ISOInspectorApp/AppShellView.swift†L1-L100】
- **Session controller** — `DocumentSessionController` orchestrates file bookmarks, pipeline startup, recents persistence, and workspace restoration, leveraging `ChunkedFileReader` and `ParsePipeline.live()` factories.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L1-L120】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L121-L240】
- **Parse tree store** — `ParseTreeStore` bridges `AsyncThrowingStream` events onto the main queue, producing `ParseTreeSnapshot` data consumed by SwiftUI views and hex providers.【F:Sources/ISOInspectorApp/State/ParseTreeStore.swift†L1-L120】
- **Detail pane** — `ParseTreeDetailView` renders metadata, validation issues, field annotations, and hex slices, coordinating with `AnnotationBookmarkSession` for notes/bookmarks.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L1-L120】【F:Sources/ISOInspectorApp/Annotations/AnnotationBookmarkSession.swift†L1-L80】
- **Annotations** — `AnnotationBookmarkSession` wraps persistence stores (CoreData or JSON fallback) and synchronizes UI state with selection changes.【F:Sources/ISOInspectorApp/Annotations/AnnotationBookmarkSession.swift†L1-L120】

When extending UI surfaces, ensure new stateful logic stays in stores or controllers so SwiftUI views remain declarative and testable.

## 8. Contribution Checklist

Before opening a pull request:

- [ ] Implement changes using test-first or doc-first workflows aligned with XP + PDD principles.【F:DOCS/RULES/02_TDD_XP_Workflow.md†L1-L112】【F:DOCS/RULES/04_PDD.md†L1-L74】
- [ ] Update or add XCTest coverage for new functionality across Kit, CLI, and App targets where applicable.【F:README.md†L17-L32】
- [ ] Regenerate DocC archives and ensure new documentation lands alongside code changes.【F:README.md†L41-L55】
- [ ] Run `swift build`, `swift test`, and SwiftLint locally; resolve all warnings or lint failures.【F:README.md†L17-L74】
- [ ] Synchronize `todo.md` with any added or removed `@todo` comments to keep puzzles accurate.【F:DOCS/RULES/04_PDD.md†L17-L74】
- [ ] Capture outstanding follow-ups as `@todo PDD:` comments and, if needed, add entries to `DOCS/INPROGRESS/` per the micro-PRD template.【F:DOCS/RULES/04_PDD.md†L17-L74】【F:DOCS/RULES/agent-system-prompt.md†L49-L120】

## 9. Distribution & Notarization Checklist

- Use the shared distribution metadata at `Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json` when
  updating bundle identifiers, marketing version, or build number so CI tooling and documentation stay synchronized.【F:Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json†L1-L21】
- Reference `Distribution/Entitlements/` when configuring Xcode or Tuist targets; macOS builds require the App Sandbox and
  bookmark entitlements for persisted file access.【F:Distribution/Entitlements/ISOInspectorApp.macOS.entitlements†L1-L13】
- Submit notarization requests with `scripts/notarize_app.sh`. Run with `--dry-run` in Linux containers to confirm arguments
  before executing on macOS builders with configured `notarytool` credentials.【F:scripts/notarize_app.sh†L1-L75】
- Generate Xcode projects with Tuist by running `tuist generate`; the template in `Tuist/Project.swift` reads the shared
  distribution metadata so bundle identifiers and build numbers stay in sync.【F:Tuist/Project.swift†L1-L111】

## 10. Further Reading

- DocC archives generated via task A3 cover API tutorials for ISOInspectorKit, CLI usage, and SwiftUI state stores (`Sources/*/*.docc`).【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L8-L24】
- Task archive summaries provide historical context for major systems (see `DOCS/TASK_ARCHIVE/`).
- `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md` tracks remaining backlog items and highlights blocked scenarios (e.g., macOS automation and Combine benchmarks).【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L1-L160】

