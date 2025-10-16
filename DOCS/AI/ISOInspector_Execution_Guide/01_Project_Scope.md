# ISOInspector Project Scope

## Objective Statement
Design and deliver a cross-platform ISO Base Media File Format (ISO BMFF / MP4 / QuickTime) inspection system composed of reusable Swift packages and distribution targets. The solution must parse, validate, and visualize MP4 structures for files up to 20 GB with <200 ms UI latency and <100 MB memory usage on Apple platforms.

## Deliverables
| # | Deliverable | Type | Description | Completion Criteria |
|---|-------------|------|-------------|---------------------|
| 1 | ISOInspectorCore | SwiftPM library | Streaming ISO BMFF parser, validator, and metadata exporter. | All parser APIs documented; passes validation suites; emits structured events for UI/CLI. |
| 2 | ISOInspectorUI | SwiftPM library | SwiftUI component library for tree, detail, and hex visualization. | Renders parser events in interactive views with filtering and search. |
| 3 | ISOInspectorCLI | Executable | Command-line interface wrapping the core parser with reporting and export commands. | Supports file inspection, validation summary, JSON export, and error reporting. |
| 4 | ISOInspectorApp | App bundle | macOS + iPadOS + iOS app integrating core and UI packages. | Ships with onboarding, file picker, session management, and workspace persistence. |
| 5 | Documentation Suite | Markdown + DocC | Developer onboarding, API reference, and user guides. | Published with navigation index, setup instructions, and troubleshooting appendix. |
| 6 | FilesystemAccessKit | SwiftPM library | Security-scoped file access API shared by app and CLI targets. | Provides open/save/bookmark APIs validated by unit tests and integrated into platform targets. |

## Success Criteria
- Stream-parse MP4/QuickTime files up to 20 GB.
- Maintain steady-state memory usage below 100 MB during parsing sessions.
- UI event propagation latency below 200 ms from parser emission to rendered view update.
- 100% automated test coverage for parser primitives and validation rules.
- CI pipeline executing build, test, lint, and documentation verification on every merge.

## Constraints
- Language: Swift 5.9+.
- Frameworks: Foundation, Swift Concurrency, SwiftUI, Combine.
- Platforms: macOS 13+, iOS 16+, iPadOS 16+.
- No third-party runtime dependencies. Use only Apple SDKs and standard libraries.
- Parser must support both little-endian and big-endian MP4 box payloads per ISO/IEC 14496.

## Assumptions
- Input files follow ISO BMFF container semantics; malformed boxes must be reported, not silently ignored.
- Build tooling uses Swift Package Manager and Xcode 15+.
- CI/CD environment provides macOS runners with Xcode preinstalled.

## External Dependencies
| Dependency | Purpose | Interaction Mode |
|------------|---------|------------------|
| ISO/IEC 14496-12 specification | Defines MP4 box structures and validation rules. | Consult for parser schema and validation invariants. |
| MP4RA Registered Box Types ([mp4ra.org](https://mp4ra.org/registered-types/boxes)) | Registry of extended atom types and vendor-specific codes. | Synchronize supported box catalog and metadata. |
| Apple Developer Documentation (Swift, SwiftUI, Combine) | API references for implementation. | Reference for concurrency, UI components, and best practices. |

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Large file streaming performance | Parser stalls or memory spikes. | Use chunked file IO with `FileHandle` async sequences and bounded buffers. |
| Vendor-specific atoms missing from registry | Validation gaps. | Fallback to generic box handler; log unknown types; schedule research tasks (see `05_Research_Gaps.md`). |
| UI rendering complexity on low-memory devices | App crashes or stutters. | Employ diffable data sources, virtualization, and lazy loading. |
