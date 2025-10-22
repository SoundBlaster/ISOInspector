# ISOInspector Technical Specification

## Architecture Overview
The system is organized into layered Swift packages with clear separation of concerns:
- **ISOInspectorCore** — Handles file I/O, streaming parse pipeline, validation rules, and metadata catalog.
- **ISOInspectorUI** — SwiftUI components consuming core events via Combine publishers; provides visualization and user interactions.
- **ISOInspectorCLI** — Command-line executable leveraging core parsing APIs and shared reporting utilities.
- **ISOInspectorApp** — SwiftUI lifecycle application bundling core and UI modules with platform integrations (document browser, persistence).
- **FilesystemAccessKit** — Security-scoped filesystem mediator providing unified open/save/bookmark APIs for sandboxed targets.

Components communicate through typed event streams and shared domain models to keep concurrency boundaries explicit and testable.

## Module Responsibilities
| Module | Responsibilities | Key Types | External References |
|--------|------------------|-----------|---------------------|
| Core.IO | Chunked file reader using `FileHandle.AsyncBytes` with configurable buffer size. | `ChunkReader`, `FileSlice`, `ReadContext` | Foundation |
| Core.Parser | Decode MP4 atom headers, dispatch to box-specific decoders, and emit events. | `BoxHeader`, `BoxDecoder`, `ParseEvent`, `ParsePipeline` | ISO/IEC 14496-12 | 
| Core.Validation | Validate structural rules, track context stack, report warnings/errors. | `ValidationRule`, `ValidationIssue`, `ContextStack` | ISO/IEC 14496-12 | 
| Core.Metadata | Maintain registry of known boxes referencing MP4RA data; provide descriptive metadata. | `BoxCatalog`, `BoxDescriptor` | MP4RA registry | 
| Core.Export | Serialize parse tree and validation results to JSON and binary capture. | `JSONExporter`, `CaptureWriter` | Codable | 
| UI.Tree | Render hierarchical tree with virtualization. | `BoxNode`, `BoxTreeView`, `BoxTreeStore` | SwiftUI | 
| UI.Detail | Present metadata, hex viewer, annotations. | `BoxDetailView`, `HexView`, `AnnotationStore` | SwiftUI | 
| UI.Session | Manage multi-file sessions, bookmarks, persistence via CoreData or JSON. | `SessionStore`, `Bookmark` | FileManager, CoreData | 
| CLI.Commands | Command definitions for `inspect`, `validate`, `export`. | `InspectCommand`, `ValidateCommand` | ArgumentParser | 
| CLI.Reporting | Format console output, CSV summary, exit codes. | `ReportFormatter`, `CSVWriter` | Foundation |
| App.Shell | SwiftUI App entry, window scenes, document importers. | `ISOInspectorApp`, `DocumentController` | SwiftUI, UniformTypeIdentifiers |
| Sandbox.FilesystemAccess | Request, persist, and resolve security-scoped bookmarks for user-selected files. | `FilesystemAccess`, `SecurityScopedBookmark`, `FilesystemAccessError` | App Sandbox design guide, UIDocumentPicker docs |

## Data Flow
1. **File ingestion** — CLI/UI passes file URLs to `ChunkReader` which reads sequential slices (default 1 MB) asynchronously.
2. **Parsing pipeline** — `ParsePipeline` receives `FileSlice`, decodes headers (`BoxHeader`), consults `BoxCatalog` for known types, and constructs `ParseEvent` objects.
3. **Validation** — Each `ParseEvent` passes through `ValidationRule` chain verifying structure (size fields, version compatibility, container nesting). Issues appended to event metadata.
4. **Distribution** — Events published via `AsyncStream`/Combine publishers to subscribers (UI tree store, CLI reporter, exporters).
5. **Persistence/Export** — UI or CLI triggers exporters that consume stored tree snapshots to produce JSON or binary capture.

## Event Model
```swift
struct ParseEvent: Sendable, Codable {
    let fileID: UUID
    let boxPath: [BoxIdentifier]
    let header: BoxHeader
    let payloadOffset: UInt64
    let payloadLength: UInt64
    let metadata: BoxDescriptor?
    let validationIssues: [ValidationIssue]
    let timestamp: Date
}
```
- `BoxIdentifier` includes four-character code, index among siblings, and optional extended type.
- Events must be emitted in document order; consumers rely on monotonic offsets.

## Parsing Algorithms
1. Read 8-byte base header (size + type).
2. If size == 1, read 8-byte large size; adjust payload length accordingly.
3. If type == `uuid`, read 16-byte extended type GUID.
4. Validate size ≥ header length; if not, emit error and attempt to resynchronize by skipping to next 4-byte boundary.
5. For container boxes, recursively parse children while total bytes consumed < declared size.
6. Use streaming recursion via explicit stack to avoid deep call stacks.
7. `mdat` payload handled via skip; store metadata but do not buffer entire payload.

## Validation Rules
| Rule ID | Description | Severity | Enforcement |
|---------|-------------|----------|-------------|
| VR-001 | Box size must be ≥ header length. | Error | Immediate event flagged; skip payload. |
| VR-002 | Container boxes must close exactly at declared size. | Error | Compare consumed bytes; emit error if mismatch. |
| VR-003 | Version/flags must match MP4RA metadata when specified. | Warning | Compare metadata table; report mismatch. |
| VR-004 | `ftyp` must appear before any media box. | Error | Track first non-`ftyp` encountered; emit error if missing. |
| VR-005 | `moov` must precede `mdat` unless flagged streaming. | Warning | Evaluate order; attach suggestion. |
| VR-006 | Unknown box types recorded for follow-up research. | Info | Append to research log with type code. |

### Validation Configuration
- `ValidationRuleID` enumerates shipping rules, enabling presentation layers to build toggle lists without probing implementation details.
- `ValidationPreset` models curated bundles (e.g., `allChecks`, `structuralOnly`, `advisoryFocus`) and surfaces localized descriptions.
- `ValidationConfiguration` stores the active preset name plus per-rule overrides; defaults enable every rule to preserve backward compatibility.
- Configuration flows through dependency injection: CLI resolves flags into a configuration, UI sessions persist the last selection, and exports annotate their payloads with the active preset for audit trails.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L1-L120】
- Persisted settings serialize via `Codable` so workspaces, CLI config files, and potential future shared preferences reuse the same schema.

## Concurrency Model
- Parsing executes on dedicated background task using Swift concurrency (`Task`, `AsyncStream`).
- UI subscribes via `@StateObject` stores bridging Combine to SwiftUI.
- CLI uses async/await to consume event streams sequentially.
- Shared mutable state avoided; use actors for `BoxCatalog` updates and session persistence.

## Error Handling Strategy
- Distinguish between recoverable validation issues and fatal I/O errors.
- Provide `ParseError` enumerations with localized descriptions for UI/CLI.
- Ensure CLI exit codes map: `0` success, `1` validation warnings only, `2` validation errors, `3` fatal runtime error.

## Testing & Verification
| Test Type | Coverage | Tooling |
|-----------|----------|---------|
| Unit Tests | Parser primitives, validation rules, metadata mapping. | XCTest, JSON fixtures. |
| Integration Tests | End-to-end parse of sample MP4 files, CLI command invocations. | XCTest + `swift test --enable-code-coverage`. |
| Performance Tests | Measure parsing throughput and memory profile on large files. | XCTest Metrics, Instruments automation. |
| Fuzzing | Randomized box sequences to ensure robustness. | SwiftFuzzer integration. |
| UI Snapshot Tests | Validate SwiftUI views render expected layout. | SwiftSnapshotTesting. |
| Accessibility Tests | VoiceOver labels, Dynamic Type scaling. | XCTest + Accessibility Inspector automation. |

## Instrumentation & Telemetry
- Add signposts (`os_signpost`) around parse stages to measure latency in Instruments.
- Provide debug logging toggled via environment variables (`ISOINSPECTOR_LOG_LEVEL`).
- CLI `--verbose` flag increases logging detail.

## Packaging & Distribution
- All modules defined in a single SwiftPM workspace with multiple targets.
- App target configured via Xcode project referencing SwiftPM packages.
- CI builds universal binaries for Apple silicon and Intel (where supported).
- Release artifacts include CLI binary, SwiftPM packages, and notarized app bundle.

## Documentation Strategy
- Use DocC catalogs for API docs (`ISOInspector.docc`).
- Markdown guides stored under `Docs/Guides` with version tagging.
- Generate CLI man pages via `swift-argument-parser` autodoc.
- Keep MP4 box catalog synced with MP4RA updates; include script to fetch registry JSON.
