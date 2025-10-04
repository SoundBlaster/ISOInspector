
# ISOInspector Project — Master PRD

## Scope & Intent
Design a cross-platform ISO BMFF (MP4/QuickTime) Inspector system composed of:
- **ISOInspectorCore** — async streaming parser and validator.
- **ISOInspectorUI** — SwiftUI tree/details/hex visualization.
- **ISOInspectorCLI** — command-line inspector.
- **ISOInspectorApp** — macOS/iPadOS/iOS integration app.

### Deliverables
| Component | Type | Description |
|------------|------|-------------|
| ISOInspectorCore | SwiftPM lib | Streaming parser, validation, export |
| ISOInspectorUI | SwiftPM lib | SwiftUI UI for tree/details/hex |
| ISOInspectorCLI | Executable | CLI interface |
| ISOInspectorApp | App | Universal app integrating Core+UI |
| Docs | Markdown/DocC | Full developer & user specs |

### Success Criteria
- Parse/validate files up to 20GB.
- Streaming events for UI with latency <200ms.
- Memory <100MB.
- Cross-platform Swift codebase.

### Constraints
Swift 5.9+, Foundation, SwiftUI. No third-party dependencies.
