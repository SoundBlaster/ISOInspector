# ISOInspector App Manual

The ISOInspector SwiftUI application streams ISO Base Media File Format (MP4/QuickTime) structures into an interactive tree, de
tail pane, and hex viewer so you can review files without leaving the app. The interface is powered by the same streaming pipeli
ne used by the CLI, and it keeps bookmarks, notes, and recents in sync across launches.

## Supported platforms and requirements

- **Platforms:** macOS 14 and iOS/iPadOS 16 or newer via the SwiftPM targets declared in the package manifest.【F:Package.swift†L6
-L44】
- **File types:** MP4 (`.mp4`) and QuickTime (`.mov`) containers exposed through the system document picker.【F:Sources/ISOInspecto
rApp/State/DocumentSessionController.swift†L16-L120】
- **First launch:** Build and run the `ISOInspectorApp` product from SwiftPM or the generated Xcode project. The app greets you
with the sidebar and an onboarding panel prompting you to open a file.【F:Sources/ISOInspectorApp/AppShellView.swift†L5-L119】

## Opening media and managing recents

1. Click **Open File…** in the sidebar to present the system file importer, or drop a compatible file onto the window. The docu
ment controller resolves security-scoped bookmarks on macOS so future launches reuse permissions automatically.【F:Sources/ISOIns
pectorApp/AppShellView.swift†L40-L83】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L52-L146】
2. The selected file appears under **Recents** with its display name, a relative "last opened" timestamp, and the full path. Rec
ents are capped at ten entries; removing a row immediately updates the persisted list.【F:Sources/ISOInspectorApp/AppShellView.s
wift†L59-L110】【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L96-L146】
3. Choosing a recent reopens the document, restores streaming state, and syncs the bookmark store so annotations remain availab
le across sessions.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L52-L193】
4. Stale or revoked bookmarks refresh automatically. The session controller requests new bookmark data through FilesystemAccessKit, records the resolution state, and removes invalid entries so future launches prompt for consent instead of leaving broken recents behind.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L566-L683】【F:Sources/ISOInspectorKit/FilesystemAccess/FilesystemAccess.swift†L60-L109】

## Interface tour

### Box hierarchy header

The main workspace shows a balanced split view. A header labelled **Box Hierarchy** summarizes the parse status and keeps the fo
cus commands discoverable.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L17-L91】

### Search and filters

The outline pane includes:

- A search field that tokenizes input and matches box identifiers, names, and summaries. Matches auto-expand the tree to expos
e results.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L93-L193】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutline
ViewModel.swift†L9-L202】
- Toggle buttons for each validation severity; enabling a badge narrows the tree to nodes with matching issues and exposes a **
Clear filters** shortcut when any filter is active.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L116-L159】【F:Sour
ces/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L1-L38】
- Horizontal chips for available box categories such as metadata, streaming, or media payloads. You can mix categories with sev
erity filters to focus on specific structures.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L161-L189】【F:Sources/I
SOInspectorApp/Tree/ParseTreeOutlineViewModel.swift†L203-L235】
- A switch to hide or reveal streaming indicator nodes when you only need structural boxes.【F:Sources/ISOInspectorApp/Tree/Pars
eTreeOutlineView.swift†L191-L199】【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineFilter.swift†L1-L38】

### Outline navigation

Scroll or use arrow keys (macOS) to traverse the tree. Selecting a row loads its detail view and highlights matching search res
ults; toggling the bookmark icon stores the selection for later review.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swi
ft†L201-L287】

### Detail pane

The detail pane surfaces metadata, validation issues, annotations, and payload bytes for the active selection:

- **Metadata** lists type, byte ranges, registry metadata, and snapshot timestamps, and exposes a bookmark control tied to the
annotation session.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L1-L145】
- **Notes** let you add, edit, and delete free-form entries. The composer disables itself until a selection is available and pe
rsistence succeeds.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L146-L220】
- **Field annotations** highlight parsed subranges and allow quick selection of interesting fields.【F:Sources/ISOInspectorApp/D
etail/ParseTreeDetailView.swift†L221-L279】
- **Validation** badges group rule identifiers with copy-to-clipboard actions for the messages.【F:Sources/ISOInspectorApp/Deta
il/ParseTreeDetailView.swift†L280-L326】
- **Hex** shows a windowed payload slice with byte offsets and selection callbacks for highlighting.【F:Sources/ISOInspectorApp/
Detail/ParseTreeDetailView.swift†L327-L374】

### JSON exports

- The main window toolbar now exposes **Export JSON…** and **Export Selection…** buttons. The former serializes the entire parse tree, while the latter activates when a node is selected and captures only that subtree.【F:Sources/ISOInspectorApp/AppShellView.swift†L18-L116】
- The outline row context menu mirrors the selection export so you can right-click a box and immediately persist its JSON snapshot without changing focus.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L215-L288】
- The app-level **Export** command menu adds keyboard-accessible entries for the same flows, keeping menu bar parity with the CLI exporters.【F:Sources/ISOInspectorApp/ISOInspectorApp.swift†L1-L71】
- When tolerant parsing diagnostics are present, exports add a `schema.version` value of `2` alongside each node’s `issues` array so downstream automation can detect the richer payload while strict-mode files remain byte-for-byte compatible.【F:Sources/ISOInspectorKit/Export/JSONParseTreeExporter.swift†L17-L120】【F:Tests/ISOInspectorKitTests/Fixtures/Snapshots/tolerant-issues.json†L1-L74】

### Keyboard shortcuts

Use ⌘⌥1 to focus the outline, ⌘⌥2 for detail, ⌘⌥3 for notes, and ⌘⌥4 for the hex viewer. These shortcuts aid assistive technolo
gy users and speed up deep file reviews.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L57-L90】

## Session persistence and recovery

- The session controller persists recents, bookmarks, and notes through Core Data so annotations reopen with their last selectio
n highlighted.【F:Sources/ISOInspectorApp/State/DocumentSessionController.swift†L15-L193】
- Backgrounding the app pauses streaming work to conserve resources; returning to the foreground resumes with the latest parse
snapshot.【F:Sources/ISOInspectorApp/AppShellView.swift†L11-L38】
- Security-scoped bookmarks ensure macOS sandbox builds can reopen files without prompting each time.【F:Sources/ISOInspectorApp
/State/DocumentSessionController.swift†L64-L145】

## Troubleshooting and platform notes

- Validation warnings and errors appear both in the outline badges and in the detail pane; copy messages directly from the pane
when filing follow-up tasks.【F:Sources/ISOInspectorApp/Tree/ParseTreeOutlineView.swift†L201-L287】【F:Sources/ISOInspectorApp/De
tail/ParseTreeDetailView.swift†L280-L326】
- Notes or bookmarks may be unavailable when running on platforms without the Core Data store; the detail view displays status
messages in that case.【F:Sources/ISOInspectorApp/Detail/ParseTreeDetailView.swift†L146-L220】
- Automated UI coverage and Combine-backed benchmarks still require macOS hardware with the appropriate entitlements; refer to
 the archived task notes when scheduling those runs.【F:DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/51_ParseTreeStreamingSel
ectionAutomation_macOS_Run.md†L1-L33】【F:DOCS/TASK_ARCHIVE/50_Summary_of_Work_2025-02-16/50_Combine_UI_Benchmark_macOS_Run.md†
L1-L33】

## Related resources

- [CLI manual](../Manuals/CLI.md) — Inspect, validate, and export the same parse data from scripts.
- [DocC tutorials](../Guides) — Developer-oriented guides for extending ISOInspectorKit APIs.
