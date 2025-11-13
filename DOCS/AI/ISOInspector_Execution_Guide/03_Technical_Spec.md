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
- Default presets load from bundled JSON manifests while user-authored presets persist in `Application Support/ISOInspector/validation-presets.json`, letting upgrades merge in new defaults without erasing local customizations.
- `ValidationPreset` models curated bundles (e.g., `allChecks`, `structuralOnly`, `advisoryFocus`) and surfaces localized descriptions.
- `ValidationConfiguration` stores the active preset name plus per-rule overrides; defaults enable every rule to preserve backward compatibility.
- Configuration flows through dependency injection: CLI resolves flags into a configuration, UI sessions persist the last selection, and exports annotate their payloads with the active preset for audit trails.【F:Sources/ISOInspectorCLI/ISOInspectorCommand.swift†L1-L120】
- Global defaults persist in an app-level `ValidationPreferences` file colocated with other user settings, while per-document/workspace overrides travel with the document bundle and can be cleared to fall back to the global layer.
- Persisted settings serialize via `Codable` so workspaces, CLI config files, and potential future shared preferences reuse the same schema.
- Export pipelines emit a `disabledRules` collection whose entries include `{ id, status: "skipped" }`; CLI text reports omit those rules from their issue tables but retain preset metadata in the header.
- CLI conveniences register alias flags (for example, `--structural-only`) that map directly to preset identifiers in addition to the generic `--preset <name>` option.

## User Settings Panel Architecture
- `SettingsPanelScene` is a shared SwiftUI view that can be hosted inside an `NSPanel` (macOS) or a `.sheet`/`.presentationDetents` modal (iPadOS/iOS). Platform adapters determine chrome only; all layout/styling flows through FoundationUI wrappers so cards, section headers, and inspectors stay consistent with the migration plan in `DOCS/INPROGRESS/FoundationUI_Integration_Strategy.md`.
- The panel's view model exposes two published collections: `permanentGroups` sourced from `UserPreferencesStore` (which already wraps `ValidationPreferences` and future telemetry toggles) and `sessionGroups` sourced from `DocumentSessionController.currentSessionSettings`. Each group reports whether it diverges from global defaults so the UI can badge changed values.
- A dedicated `SettingsBridge` actor serializes write operations, ensuring that permanent changes optimistically persist via `UserPreferencesStore.persist()` and emit diagnostics (Task E6) when writes fail, while session changes call `DocumentSessionController.updateSessionSettings(for:documentID:)` so CoreData + JSON snapshots (Task E3) remain authoritative.
- macOS builds expose a `SettingsPanelWindowController` hosting the SwiftUI scene inside an `NSPanel` with floating window level and remembered frame stored in the session payload; iPad/iOS builds expose the same SwiftUI scene via `.sheet` with detents that match the FoundationUI inspector pattern.
- Keyboard shortcuts (`⌘,`) and toolbar buttons toggle the panel. Automation hooks publish `SettingsPanelDidPresent` / `SettingsPanelDidDismiss` events for integration tests so UI automation can assert state synchronization.
- Reset affordances call helpers that either reset the global preferences file (permanent) or clear only the current session's overrides before reloading the view model, mirroring the behavior previously implemented for `ValidationSettingsView` (Task C19).

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

## CI & Quality Automation
- **Formatting:** `.pre-commit-config.yaml` runs `swift format --configuration .swift-format.json --in-place` for staged Swift files while `.github/workflows/ci.yml` executes `swift format --mode lint` to guarantee identical style across contributors and CI agents.【F:todo.md†L3-L7】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L11】
- **Static Analysis:** `.swiftlint.yml` re-enables complexity-oriented rules (`cyclomatic_complexity`, `function_body_length`, `type_body_length`, `nesting`) and CI publishes analyzer diagnostics via `.github/workflows/swiftlint.yml`, mirroring the expectations captured in the execution workplan.【F:todo.md†L7-L11】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L12】
- **Coverage Gate:** `coverage_analysis.py --threshold 0.67` runs after `swift test --enable-code-coverage` in pre-push hooks and GitHub Actions to block regressions in the code-to-test ratio, storing reports under `Documentation/Quality/` for historical review.【F:todo.md†L5】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L8-L24】
- **DocC Health:** SwiftLint's `missing_docs` rule and the documentation workflow combine to fail builds lacking DocC-ready comments, and the suppression guide in `Documentation/ISOInspector.docc/Guides/DocumentationStyle.md` explains how to annotate intentional gaps.【F:todo.md†L6】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L26-L28】
- **Strict Concurrency:** Git hooks and CI execute `swift build --strict-concurrency=complete` and `swift test --strict-concurrency=complete`, uploading logs referenced by `PRD_SwiftStrictConcurrency_Store.md` to demonstrate zero-warning compliance.【F:todo.md†L7】【F:DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md†L20-L24】

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

---

## FoundationUI Integration Architecture

### Overview
ISOInspectorApp integrates FoundationUI design system following a **6-phase gradual migration** approach (see `DOCS/INPROGRESS/FoundationUI_Integration_Strategy.md` for detailed planning).

**Key Principles:**
- All UI components use FoundationUI design system (no magic numbers)
- Design system tokens (DS.Spacing, DS.Colors, DS.Typography) used exclusively
- Platform-aware adaptation via environment contexts (macOS/iOS/iPadOS)
- Backward compatibility: old + new UI coexist during transition
- Comprehensive testing: unit tests, snapshot tests, a11y tests, performance tests

### Design System Layers

**Layer 0: Design Tokens (DS namespace)**
```swift
DS.Spacing     // s(8), m(12), l(16), xl(24)
DS.Colors      // semantic: primary, secondary, tertiary, accent + text variants
DS.Typography  // label, body, title, caption, code, headline, subheadline
DS.Radius      // small(6), medium(8), card(10), chip(999)
DS.Animation   // quick(0.15s), medium(0.25s), slow(0.35s), spring
```

**Layer 1: View Modifiers**
```swift
.badgeChipStyle(level: .info | .warning | .error | .success)
.cardStyle(elevation: .surface | .raised | .floating)
.interactiveStyle()  // hover (macOS) / tap (iOS) feedback
.surfaceStyle(.thin | .regular | .thick)  // material elevation
.copyableModifier()  // platform-specific clipboard
```

**Layer 2: Components (Composable)**
```swift
DS.Badge                    // status indicator
DS.Indicator               // compact status dot (mini/small/medium)
DS.Card                    // content container with elevation
DS.KeyValueRow             // metadata display (horizontal/vertical)
DS.SectionHeader           // section title with optional divider
DS.CopyableText            // interactive text with copy feedback
DS.Copyable<Content>       // generic copyable wrapper
```

**Layer 3: Patterns (Organisms)**
```swift
DS.InspectorPattern        // scrollable inspector with fixed header
DS.SidebarPattern          // NavigationSplitView sidebar
DS.ToolbarPattern          // platform-adaptive toolbar
DS.BoxTreePattern          // hierarchical tree with lazy rendering
```

**Layer 4: Contexts (Cross-Cutting)**
```swift
@Environment(\.surfaceStyleKey)         // material selection
@Environment(\.platformAdaptation)      // spacing/sizing per platform
@Environment(\.colorSchemeAdapter)      // dark mode adaptation
@Environment(\.accessibilityContext)    // a11y: motion, contrast, dynamic type
```

### Integration Patterns

**Pattern 1: Component Wrappers**
```swift
// Example: BoxStatusBadgeView wraps DS.Badge with ISO-specific semantics
struct BoxStatusBadgeView: View {
    let status: ParseStatus  // .success, .warning, .error, .info

    var body: some View {
        DS.Badge(text: status.description)
            .badgeChipStyle(level: status.level)  // maps to DS semantic level
    }
}
```

**Pattern 2: Pattern Wrappers**
```swift
// Example: BoxesSidebar wraps DS.SidebarPattern
struct BoxesSidebar: View {
    @StateObject var store: BoxNodeStore

    var body: some View {
        DS.SidebarPattern(
            sections: store.sections,
            onSelect: { store.select($0) }
        )
        .platformAdaptation()  // auto-adapts macOS/iOS/iPadOS
    }
}
```

**Pattern 3: Accessibility Integration**
All views apply accessibility contexts:
```swift
struct ContentView: View {
    var body: some View {
        VStack { /* UI */ }
            .environment(\.platformAdaptation, PlatformAdaptation())
            .environment(\.colorSchemeAdapter, ColorSchemeAdapter())
            .environment(\.accessibilityContext, AccessibilityContext())
    }
}
```

### No Magic Numbers Rule

**Enforcement:** All numeric values in UI must reference design tokens.

**Correct:**
```swift
VStack(spacing: DS.Spacing.m) {  // ✅ Uses DS token
    Text("Label")
}
```

**Incorrect:**
```swift
VStack(spacing: 12) {  // ❌ Magic number
    Text("Label")
}
```

**Audit:** SwiftLint rule `magic_numbers` enforces zero magic numbers in UI code. Custom exceptions tracked in `.swiftlint.yml`.

### Integration Phases & Testing Gates

| Phase | Duration | Focus | Test Coverage | A11y Score | Status |
|-------|----------|-------|---------------|-----------|--------|
| Phase 0 | 3-4d | Setup, test infrastructure, Component Showcase | ≥80% | N/A | 📋 Planned |
| Phase 1 | 5-7d | Badges, Cards, Key-Value Rows | ≥80% | ≥98% | 📋 Planned |
| Phase 2 | 5-7d | Copyable, Interactive Styles, Materials | ≥80% | ≥98% | 📋 Planned |
| Phase 3 | 7-10d | Sidebar, Inspector, Tree, Toolbar Patterns | ≥80% | ≥98% | 📋 Planned |
| Phase 4 | 4-5d | Platform Adaptation, Accessibility, Dark Mode | ≥80% | ≥98% | 📋 Planned |
| Phase 5 | 5-7d | Search, Progress, Export, Hex Viewer | ≥80% | ≥98% | 📋 Planned |
| Phase 6 | 5-7d | Integration, Performance, Beta, Release | ≥80% | ≥98% | 📋 Planned |

**Phase Gate Criteria (must pass to proceed):**
1. ✅ All phase tasks complete
2. ✅ Unit tests pass + coverage ≥80%
3. ✅ Snapshot regression tests pass (all platforms)
4. ✅ Accessibility audit ≥95% (no WCAG 2.1 AA violations)
5. ✅ Code review approved (zero SwiftLint warnings)
6. ✅ Performance baselines met (no regressions)

### Platform-Specific Adaptations

**macOS**
- Sidebar always visible (horizontal split)
- Keyboard shortcuts (Cmd+1/2/3 for sidebar sections, Cmd+F for search)
- Hover states on interactive elements
- Top toolbar placement

**iOS**
- Navigation stack for hierarchical navigation
- Bottom toolbar (if present)
- Touch feedback (no hover)
- Single-column layout (no split view)

**iPadOS**
- Sidebar collapsible in portrait, persistent in landscape
- Keyboard shortcuts supported
- Large pointer area for touch
- Split view with dynamic width

### Testing Strategy

**Test Distribution (Testing Pyramid):**
```
Unit Tests (70%)
  - Component logic, state management
  - Token validation, modifier composition
  - Examples: BadgeTests, CardTests, KeyValueRowTests

Integration Tests (20%)
  - Pattern composition, navigation flows
  - Context propagation, accessibility feature interaction
  - Examples: SidebarPatternTests, InspectorPatternTests

E2E Tests (10%)
  - App launch, complete user workflows
  - Cross-platform validation
  - Examples: AppLaunchTests, NavigationFlowTests
```

**Test Suites per Phase:**
```
Tests/ISOInspectorAppTests/FoundationUI/
├── Phase0/
│   ├── DependencyTests.swift
│   ├── ComponentShowcaseTests.swift
│   └── IntegrationSetupTests.swift
├── Phase1/
│   ├── BadgeIndicatorTests.swift
│   ├── BadgeIndicatorSnapshotTests.swift
│   ├── CardSectionTests.swift
│   ├── KeyValueRowTests.swift
│   └── ...AccessibilityTests.swift
├── Phase2/
│   ├── CopyableTests.swift
│   ├── InteractiveStyleTests.swift
│   └── SurfaceStyleTests.swift
├── Phase3/
│   ├── SidebarPatternTests.swift
│   ├── SidebarPatternSnapshotTests.swift
│   ├── InspectorPatternTests.swift
│   ├── BoxTreePatternTests.swift
│   ├── BoxTreePatternPerformanceTests.swift
│   └── ToolbarPatternTests.swift
├── Phase4/
│   ├── PlatformAdaptationTests.swift
│   ├── AccessibilityContextTests.swift
│   └── ColorSchemeAdapterTests.swift
├── Phase5/
│   ├── SearchFilterTests.swift
│   ├── ProgressAsyncTests.swift
│   ├── ExportShareTests.swift
│   └── HexViewerTests.swift
└── Phase6/
    ├── IntegrationTests/
    ├── PerformanceTests/
    ├── SnapshotIntegrationTests.swift
    └── AccessibilityComplianceTests.swift
```

**Snapshot Testing:** All UI variants tested on multiple platforms (iOS, iPadOS, macOS) and modes (light, dark, high contrast).

**Accessibility Testing:** WCAG 2.1 AA compliance verified through:
- VoiceOver narration tests (50+)
- Keyboard navigation tests (20+)
- Color contrast tests (30+)
- Dynamic Type tests (20+)
- Motion reduction tests (15+)

### Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Test Coverage | ≥80% | XCTest code coverage per phase |
| Accessibility | ≥95% (AA) | Automated audit + manual validation |
| Performance: App Launch | <2s | XCTest + Instruments |
| Performance: Tree Scroll | ≥55fps (1000 nodes) | Instruments CoreAnimation |
| Performance: Memory | <250MB (large files) | Xcode Memory Debugger |
| Binary Size Impact | <10% | xcodesign + dsymutil |
| SwiftLint Violations | 0 | Strict mode enforcement |

### Migration Documentation

See `DOCS/AI/ISOInspector_Execution_Guide/MIGRATION.md` (created during Phase 6.3) for:
- Old UI component → FoundationUI mapping
- Code examples for common patterns
- Troubleshooting guide
- Integration checklist

### Practical Integration Examples

This section provides concrete code examples demonstrating how to integrate FoundationUI components into ISOInspector's UI codebase.

#### Example 1: Badge Integration for Parse Status

**Use Case:** Display parse validation status with semantic coloring.

```swift
// Sources/ISOInspectorApp/UI/Components/BoxStatusBadgeView.swift

import SwiftUI
import FoundationUI

/// Wraps FoundationUI Badge component for ISO box parse status display
struct BoxStatusBadgeView: View {
    let status: ParseStatus

    var body: some View {
        Badge(text: status.displayText, level: status.badgeLevel, showIcon: true)
            .accessibilityLabel("\(status.badgeLevel.accessibilityLabel): \(status.displayText)")
    }
}

// Map domain ParseStatus to FoundationUI BadgeLevel
extension ParseStatus {
    var badgeLevel: BadgeLevel {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        case .info, .parsing: return .info
        }
    }

    var displayText: String {
        switch self {
        case .success: return "VALID"
        case .warning: return "WARNINGS"
        case .error: return "ERRORS"
        case .info: return "INFO"
        case .parsing: return "PARSING"
        }
    }
}

// Usage in tree view
struct BoxTreeRowView: View {
    let box: BoxNode

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Text(box.name)
                .font(DS.Typography.body)

            Spacer()

            BoxStatusBadgeView(status: box.parseStatus)
        }
        .padding(DS.Spacing.m)
    }
}
```

**Test Coverage:** See `Tests/ISOInspectorAppTests/FoundationUI/BadgeComponentTests.swift` for 32 comprehensive tests.

---

#### Example 2: Card Integration for Detail Panels

**Use Case:** Display box metadata in consistent card containers with elevation.

```swift
// Sources/ISOInspectorApp/UI/Components/BoxMetadataCard.swift

import SwiftUI
import FoundationUI

/// Wraps FoundationUI Card for box metadata display
struct BoxMetadataCard: View {
    let box: BoxNode
    let elevation: CardElevation

    init(box: BoxNode, elevation: CardElevation = .medium) {
        self.box = box
        self.elevation = elevation
    }

    var body: some View {
        Card(elevation: elevation) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "METADATA", showDivider: true)

                BoxMetadataRow(key: "Type", value: box.type)
                BoxMetadataRow(key: "Size", value: formatBytes(box.size))
                BoxMetadataRow(key: "Offset", value: formatOffset(box.offset))

                if let version = box.version {
                    BoxMetadataRow(key: "Version", value: "\(version)")
                }
            }
            .padding(DS.Spacing.l)
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func formatOffset(_ offset: UInt64) -> String {
        String(format: "0x%08X", offset)
    }
}

// Usage in inspector
struct BoxInspectorView: View {
    let box: BoxNode

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                BoxMetadataCard(box: box, elevation: .medium)

                // Additional cards for validation, hex view, etc.
                ValidationCard(issues: box.validationIssues)
                HexViewCard(data: box.payload)
            }
            .padding(DS.Spacing.l)
        }
        .background(.thinMaterial)
    }
}
```

**Test Coverage:** See `Tests/ISOInspectorAppTests/FoundationUI/CardComponentTests.swift`.

---

#### Example 3: KeyValueRow Integration for Metadata Display

**Use Case:** Display key-value metadata pairs with copyable text and consistent formatting.

```swift
// Sources/ISOInspectorApp/UI/Components/BoxMetadataRow.swift

import SwiftUI
import FoundationUI

/// Wraps FoundationUI KeyValueRow for ISO box metadata
struct BoxMetadataRow: View {
    let key: String
    let value: String
    let layout: KeyValueLayout
    let monospaced: Bool

    init(
        key: String,
        value: String,
        layout: KeyValueLayout = .horizontal,
        monospaced: Bool = false
    ) {
        self.key = key
        self.value = value
        self.layout = layout
        self.monospaced = monospaced
    }

    var body: some View {
        KeyValueRow(
            key: key,
            value: value,
            layout: layout,
            copyable: true,
            monospaced: monospaced
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key): \(value)")
    }
}

// Specialized wrapper for hex offset display
struct HexOffsetRow: View {
    let offset: UInt64

    var body: some View {
        BoxMetadataRow(
            key: "Offset",
            value: String(format: "0x%08X", offset),
            monospaced: true
        )
    }
}

// Usage in detail view
struct BoxDetailMetadataView: View {
    let box: BoxNode

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "BOX DETAILS", showDivider: true)

            BoxMetadataRow(key: "Type", value: box.fourCC)
            BoxMetadataRow(key: "Size", value: "\(box.size) bytes")
            HexOffsetRow(offset: box.offset)
            BoxMetadataRow(key: "Container", value: box.parent?.fourCC ?? "—")

            if let flags = box.flags {
                BoxMetadataRow(
                    key: "Flags",
                    value: String(format: "0x%06X", flags),
                    monospaced: true
                )
            }
        }
        .padding(DS.Spacing.l)
    }
}
```

**Test Coverage:** See `Tests/ISOInspectorAppTests/FoundationUI/KeyValueRowComponentTests.swift`.

---

#### Example 4: Compose Multiple Components (Integrity Summary Panel)

**Use Case:** Build complex UI by composing FoundationUI components.

```swift
// Sources/ISOInspectorApp/UI/Panels/IntegritySummaryPanel.swift

import SwiftUI
import FoundationUI

/// Demonstrates composition of multiple FoundationUI components
struct IntegritySummaryPanel: View {
    let file: ParsedFile
    @State private var colorScheme: ColorScheme = .light

    var body: some View {
        Card(elevation: .high) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // Header with status badge
                HStack {
                    SectionHeader(title: "FILE INTEGRITY", showDivider: false)
                    Spacer()
                    Badge(
                        text: file.overallStatus.rawValue,
                        level: file.overallStatus.badgeLevel,
                        showIcon: true
                    )
                }

                Divider()
                    .background(DS.Colors.secondary)

                // Summary metadata
                VStack(spacing: DS.Spacing.s) {
                    KeyValueRow(key: "Filename", value: file.name, copyable: true)
                    KeyValueRow(key: "Format", value: file.format)
                    KeyValueRow(key: "Size", value: formatFileSize(file.size))
                    KeyValueRow(
                        key: "Parsed Boxes",
                        value: "\(file.boxCount)",
                        layout: .horizontal
                    )
                }

                Divider()
                    .background(DS.Colors.secondary)

                // Validation summary
                SectionHeader(title: "VALIDATION", showDivider: false)

                HStack(spacing: DS.Spacing.m) {
                    validationCounter(
                        count: file.errorCount,
                        label: "Errors",
                        level: .error
                    )
                    validationCounter(
                        count: file.warningCount,
                        label: "Warnings",
                        level: .warning
                    )
                    validationCounter(
                        count: file.infoCount,
                        label: "Info",
                        level: .info
                    )
                }
            }
            .padding(DS.Spacing.xl)
        }
        .environment(\.colorScheme, colorScheme)
    }

    @ViewBuilder
    private func validationCounter(
        count: Int,
        label: String,
        level: BadgeLevel
    ) -> some View {
        VStack(spacing: DS.Spacing.s) {
            Text("\(count)")
                .font(DS.Typography.title)
                .foregroundColor(level.foregroundColor)

            Text(label)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.m)
        .background(level.backgroundColor.opacity(0.1))
        .cornerRadius(DS.Radius.medium)
    }

    private func formatFileSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

// Preview
#Preview {
    IntegritySummaryPanel(
        file: ParsedFile(
            name: "sample.mp4",
            format: "MP4/ISO",
            size: 1_048_576,
            boxCount: 42,
            errorCount: 0,
            warningCount: 3,
            infoCount: 12,
            overallStatus: .warning
        )
    )
    .frame(width: 400)
    .padding()
}
```

---

### Design Token Usage Guidelines

All UI spacing, colors, typography, and animation must reference FoundationUI design tokens. **Zero magic numbers allowed.**

#### Spacing Tokens

```swift
// ✅ Correct: Use DS.Spacing tokens
VStack(spacing: DS.Spacing.m) {
    Text("Title")
}
.padding(.horizontal, DS.Spacing.l)
.padding(.vertical, DS.Spacing.s)

// ❌ Incorrect: Magic numbers
VStack(spacing: 12) {  // NO!
    Text("Title")
}
.padding(.horizontal, 16)  // NO!
```

#### Color Tokens

```swift
// ✅ Correct: Use semantic colors
Text("Error")
    .foregroundColor(BadgeLevel.error.foregroundColor)
    .background(BadgeLevel.error.backgroundColor)

// ❌ Incorrect: Hardcoded colors
Text("Error")
    .foregroundColor(.red)  // NO!
    .background(Color(red: 1.0, green: 0.2, blue: 0.2))  // NO!
```

#### Typography Tokens

```swift
// ✅ Correct: Use DS.Typography
Text("Headline")
    .font(DS.Typography.headline)

Text("Body content")
    .font(DS.Typography.body)

Text("CODE")
    .font(DS.Typography.code)

// ❌ Incorrect: Custom font definitions
Text("Headline")
    .font(.system(size: 17, weight: .semibold))  // NO!
```

#### Animation Timing

```swift
// ✅ Correct: Use DS.Animation tokens
withAnimation(.easeInOut(duration: DS.Animation.medium)) {
    isExpanded.toggle()
}

// Use predefined spring animation
withAnimation(DS.Animation.spring) {
    offset = newValue
}

// ❌ Incorrect: Magic timing values
withAnimation(.easeInOut(duration: 0.25)) {  // NO!
    isExpanded.toggle()
}
```

---

### Do's and Don'ts

#### ✅ DO: Wrap FoundationUI Components with Domain Semantics

```swift
// ✅ Create domain-specific wrappers
struct BoxStatusBadge: View {
    let status: ParseStatus

    var body: some View {
        Badge(text: status.text, level: status.level)
    }
}

// Usage is semantic
BoxStatusBadge(status: box.parseStatus)
```

#### ❌ DON'T: Use FoundationUI Components Directly in Business Logic

```swift
// ❌ Don't expose FoundationUI types in business layer
struct BoxNode {
    let status: BadgeLevel  // NO! BadgeLevel is a UI concern
}

// ✅ Use domain types, map in UI layer
struct BoxNode {
    let status: ParseStatus  // Domain type
}
```

---

#### ✅ DO: Use Design Tokens Exclusively

```swift
// ✅ All spacing via tokens
VStack(spacing: DS.Spacing.m) {
    content
}
.padding(DS.Spacing.l)

// ✅ All colors via semantic tokens
.foregroundColor(DS.Colors.primaryText)
.background(DS.Colors.surfaceBackground)
```

#### ❌ DON'T: Use Magic Numbers or Hardcoded Values

```swift
// ❌ Magic numbers forbidden
VStack(spacing: 12) { }  // NO!
.padding(16)             // NO!
.cornerRadius(8)         // NO! Use DS.Radius.medium

// ❌ Hardcoded colors forbidden
.foregroundColor(.blue)  // NO!
.background(Color(hex: "#FF5733"))  // NO!
```

---

#### ✅ DO: Write Comprehensive Tests

```swift
// ✅ Test all component states
func testBadgeAllLevels() {
    for level in BadgeLevel.allCases {
        let badge = Badge(text: "TEST", level: level)
        XCTAssertNotNil(badge.body)
    }
}

// ✅ Test accessibility
func testBadgeAccessibilityLabel() {
    let badge = Badge(text: "ERROR", level: .error)
    XCTAssertEqual(badge.level.accessibilityLabel, "Error")
}
```

#### ❌ DON'T: Skip Accessibility Testing

```swift
// ❌ Don't skip a11y tests
func testBadgeRendering() {
    let badge = Badge(text: "TEST", level: .info)
    XCTAssertNotNil(badge.body)
    // Missing: accessibility labels, VoiceOver, Dynamic Type
}
```

---

#### ✅ DO: Use Snapshot Tests for Visual Regressions

```swift
// ✅ Snapshot test all variants
func testBadgeSnapshotAllLevels() {
    for level in BadgeLevel.allCases {
        let view = Badge(text: "TEST", level: level)
        assertSnapshot(matching: view, as: .image)
    }
}

// ✅ Test dark mode
func testBadgeSnapshotDarkMode() {
    let view = Badge(text: "TEST", level: .error)
        .environment(\.colorScheme, .dark)
    assertSnapshot(matching: view, as: .image)
}
```

---

#### ✅ DO: Apply Platform Adaptation Contexts

```swift
// ✅ Use environment contexts for platform awareness
struct ContentView: View {
    var body: some View {
        VStack {
            // UI content
        }
        .environment(\.platformAdaptation, PlatformAdaptation())
        .environment(\.accessibilityContext, AccessibilityContext())
    }
}
```

#### ❌ DON'T: Hardcode Platform-Specific Behavior

```swift
// ❌ Don't manually check platform
#if os(macOS)
    .padding(12)
#else
    .padding(16)
#endif

// ✅ Use PlatformAdaptation context
@Environment(\.platformAdaptation) var platform
.padding(platform.spacing.medium)
```

---

#### ✅ DO: Compose Components for Complex UIs

```swift
// ✅ Build complex UIs by composition
struct BoxDetailPanel: View {
    var body: some View {
        Card(elevation: .medium) {
            VStack(spacing: DS.Spacing.l) {
                SectionHeader(title: "METADATA")
                KeyValueRow(key: "Type", value: box.type)
                KeyValueRow(key: "Size", value: "\(box.size)")
            }
        }
    }
}
```

#### ❌ DON'T: Mix FoundationUI with Legacy UI Patterns

```swift
// ❌ Don't mix old and new UI in same screen
struct MixedUIView: View {
    var body: some View {
        VStack {
            // Old UI (manual styling)
            Text("Title")
                .padding(12)  // Magic number
                .background(Color.gray)  // Hardcoded

            // New UI (FoundationUI)
            Badge(text: "NEW", level: .info)  // Inconsistent!
        }
    }
}
```

---

#### ✅ DO: Document Wrapper Components

```swift
// ✅ Add DocC comments
/// Displays box parse status using FoundationUI Badge component.
///
/// Maps domain `ParseStatus` to semantic `BadgeLevel` for consistent
/// visual representation across the application.
///
/// ## Usage
/// ```swift
/// BoxStatusBadge(status: box.parseStatus)
/// ```
///
/// ## Accessibility
/// - VoiceOver announces status level and text
/// - Supports Dynamic Type scaling
/// - High contrast mode compatible
struct BoxStatusBadge: View {
    let status: ParseStatus
    // ...
}
```

---

#### ✅ DO: Reference ComponentTestApp for Examples

The live component showcase provides interactive examples:

```bash
# Open ComponentTestApp to see all FoundationUI components in action
cd Examples/ComponentTestApp
tuist generate
open ComponentTestApp.xcworkspace
```

**ComponentTestApp includes:**
- Design token visualizations
- Interactive component galleries
- Light/Dark mode previews
- Accessibility testing utilities
- Code snippet references

See `Examples/ComponentTestApp/README.md` for detailed usage.

---

### Integration Checklist

Before integrating FoundationUI into a new screen or feature, verify:

- [ ] **Design Tokens:** All spacing uses `DS.Spacing.*`
- [ ] **Design Tokens:** All colors use `DS.Colors.*` or semantic `BadgeLevel` colors
- [ ] **Design Tokens:** All typography uses `DS.Typography.*`
- [ ] **Design Tokens:** All corner radii use `DS.Radius.*`
- [ ] **Design Tokens:** All animations use `DS.Animation.*`
- [ ] **Components:** Wrapped in domain-specific views (e.g., `BoxStatusBadge`)
- [ ] **Components:** Not exposed in business/domain layer types
- [ ] **Testing:** Unit tests written for all component wrappers
- [ ] **Testing:** Snapshot tests for visual regressions (light + dark modes)
- [ ] **Testing:** Accessibility tests (VoiceOver, Dynamic Type, contrast)
- [ ] **Accessibility:** VoiceOver labels set correctly
- [ ] **Accessibility:** Semantic roles assigned (button, label, etc.)
- [ ] **Accessibility:** Focus management implemented
- [ ] **Platform:** Uses `@Environment(\.platformAdaptation)` for cross-platform support
- [ ] **Platform:** Tested on macOS, iOS, and iPadOS
- [ ] **Documentation:** DocC comments added to wrapper components
- [ ] **Documentation:** Cross-linked to ComponentTestApp examples
- [ ] **SwiftLint:** Zero violations (run `swift lint` before committing)
- [ ] **Build:** No compiler warnings (run with `-warnings-as-errors`)

---

### Related Documents

- **Detailed Integration Plan:** `DOCS/TASK_ARCHIVE/213_I0_2_Create_Integration_Test_Suite/FoundationUI_Integration_Strategy.md`
- **Design System Guide:** `DOCS/AI/ISOInspector_Execution_Guide/10_DESIGN_SYSTEM_GUIDE.md`
- **Component Showcase:** `Examples/ComponentTestApp/README.md` — Interactive demo of all components
- **Integration Test Suite:** `Tests/ISOInspectorAppTests/FoundationUI/` — 123 comprehensive tests
- **FoundationUI PRD:** `DOCS/AI/ISOViewer/FoundationUI_PRD.md`
- **FoundationUI Task Plan:** `DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md`
- **FoundationUI Test Plan:** `DOCS/AI/ISOViewer/FoundationUI_TestPlan.md`
