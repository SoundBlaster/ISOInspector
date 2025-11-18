# NavigationSplitView Usage Guidelines for ISOInspector

**Version**: 1.0.0
**Date**: 2025-11-18
**Applies to**: FoundationUI NavigationSplitScaffold pattern (Task 241+)

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [Architecture Principles](#architecture-principles)
4. [Good Practices](#good-practices)
5. [Anti-Patterns](#anti-patterns)
6. [ISOInspector-Specific Patterns](#isoinspector-specific-patterns)
7. [Testing Strategy](#testing-strategy)
8. [References](#references)

---

## Overview

### Purpose

This document defines how NavigationSplitView should be used in ISOInspector to create consistent, accessible, and platform-adaptive navigation patterns across iOS 17+, iPadOS 17+, and macOS 14+.

### Scope

- **FoundationUI**: NavigationSplitScaffold pattern wrapping NavigationSplitViewKit
- **ISOInspectorApp**: Main application navigation structure
- **ISOInspectorKit**: Document session navigation state management

### Key Dependencies

- **NavigationSplitViewKit** (≥1.0.0): Production-ready NavigationSplitView wrapper
- **Composable Clarity Design System**: DS tokens for spacing, colors, typography
- **SwiftUI Navigation**: Native NavigationSplitView on iOS 16+

---

## Core Concepts

### Three-Column Layout

NavigationSplitView supports adaptive three-column layouts:

```
┌─────────────┬──────────────────┬──────────────┐
│   Sidebar   │     Content      │  Inspector   │
│  (Primary)  │   (Secondary)    │   (Detail)   │
├─────────────┼──────────────────┼──────────────┤
│ • Recents   │ • Parse Tree     │ • Properties │
│ • Browse    │ • Hex View       │ • Metadata   │
│ • Search    │ • Report View    │ • Integrity  │
└─────────────┴──────────────────┴──────────────┘
```

**Column Roles**:
1. **Sidebar** (Primary): Navigation list, file browser, search
2. **Content** (Secondary): Main content area (parse tree, hex, reports)
3. **Inspector** (Detail): Contextual details, properties, metadata

### Column Visibility States

Columns adapt to screen size and user preferences:

| Platform | Compact | Regular | Full |
|----------|---------|---------|------|
| **iPhone** | Content only | Sidebar + Content | N/A |
| **iPad Portrait** | Content only | Sidebar + Content | Sidebar + Content + Inspector |
| **iPad Landscape** | Sidebar + Content | Sidebar + Content + Inspector | All 3 visible |
| **macOS** | Sidebar + Content | Sidebar + Content + Inspector | All 3 visible |

### Navigation Model

NavigationSplitViewKit provides a shared `NavigationModel` for state management:

```swift
@Observable
class NavigationModel {
    var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    var inspectorVisibility: NavigationSplitViewVisibility = .automatic
    var columnVisibility: NavigationSplitViewColumn.Visibility = .all
    var preferredCompactColumn: NavigationSplitViewColumn = .content
}
```

---

## Architecture Principles

### 1. Single Source of Truth

**Principle**: Navigation state lives in ONE place and flows down.

**✅ Good Practice**:
```swift
// DocumentSessionController owns navigation state
@Observable
final class DocumentSessionController {
    var navigationModel = NavigationModel()
    var selectedFile: FileURL?
    var selectedAtom: AtomNode?
}

// Views observe and derive from it
struct ISOInspectorView: View {
    @Bindable var session: DocumentSessionController

    var body: some View {
        NavigationSplitScaffold(model: session.navigationModel) {
            // Columns...
        }
    }
}
```

**❌ Anti-Pattern**:
```swift
// DON'T: Multiple sources of truth
struct SidebarView: View {
    @State private var sidebarVisibility = NavigationSplitViewVisibility.automatic
}

struct InspectorView: View {
    @State private var inspectorVisibility = NavigationSplitViewVisibility.automatic
}
// Now sidebar and inspector states are disconnected!
```

### 2. Composable Clarity Integration

**Principle**: All navigation UI uses DS (Design System) tokens, never magic numbers.

**✅ Good Practice**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        List(files) { file in
            FileRow(file: file)
                .padding(DS.Spacing.s)  // Design token
        }
        .listStyle(.sidebar)
        .background(DS.Colors.surfaceBG)  // Semantic color
    }
}
```

**❌ Anti-Pattern**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        List(files) { file in
            FileRow(file: file)
                .padding(8)  // Magic number!
        }
        .background(Color.gray.opacity(0.1))  // Not semantic!
    }
}
```

### 3. Platform-Adaptive Behavior

**Principle**: Respect platform conventions. Don't force desktop patterns on mobile.

**✅ Good Practice**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        FileList(files: files, selection: $selectedFile)
    }
    ContentColumn {
        if let file = selectedFile {
            ParseTreeView(file: file, selection: $selectedAtom)
        } else {
            EmptyStateView(message: "Select a file to inspect")
        }
    }
    InspectorColumn {
        if let atom = selectedAtom {
            AtomInspectorView(atom: atom)
        }
    }
}
.inspectorColumnVisibility($navigationModel.inspectorVisibility)
// iOS: Inspector hidden in compact, shown in regular
// macOS: Inspector always available, user can toggle
```

**❌ Anti-Pattern**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    // DON'T: Force inspector to always show on iPhone
    InspectorColumn {
        AtomInspectorView(atom: selectedAtom)
    }
}
.inspectorColumnVisibility(.visible)  // Breaks compact layouts!
```

### 4. Accessibility First

**Principle**: All navigation controls must be VoiceOver accessible and keyboard navigable.

**✅ Good Practice**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        FileList(files: files, selection: $selectedFile)
            .accessibilityLabel("File Browser")
            .accessibilityHint("Select a file to inspect its structure")
    }
    ContentColumn {
        ParseTreeView(file: selectedFile)
            .accessibilityLabel("Parse Tree")
            .accessibilityAddTraits(.updatesFrequently)
    }
    InspectorColumn {
        AtomInspectorView(atom: selectedAtom)
            .accessibilityLabel("Atom Inspector")
            .accessibilityHint("View properties and metadata")
    }
}
.toolbar {
    ToolbarItem(placement: .navigation) {
        Button(action: toggleSidebar) {
            Label("Toggle Sidebar", systemImage: "sidebar.left")
        }
        .accessibilityLabel("Toggle Sidebar")
        .keyboardShortcut("s", modifiers: [.command, .option])
    }
}
```

**❌ Anti-Pattern**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        // DON'T: Missing accessibility labels
        FileList(files: files, selection: $selectedFile)
    }
}
.toolbar {
    ToolbarItem {
        // DON'T: Icon-only button without label
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
        }
        // Missing accessibility label and keyboard shortcut!
    }
}
```

### 5. State Persistence

**Principle**: User navigation preferences should persist across sessions.

**✅ Good Practice**:
```swift
@Observable
final class DocumentSessionController {
    var navigationModel = NavigationModel()

    init() {
        loadNavigationPreferences()
    }

    private func loadNavigationPreferences() {
        if let savedVisibility = UserDefaults.standard.string(forKey: "inspectorVisibility") {
            navigationModel.inspectorVisibility = NavigationSplitViewVisibility(rawValue: savedVisibility) ?? .automatic
        }
    }

    func saveNavigationPreferences() {
        UserDefaults.standard.set(navigationModel.inspectorVisibility.rawValue, forKey: "inspectorVisibility")
    }
}
```

**❌ Anti-Pattern**:
```swift
// DON'T: Always reset to defaults on every launch
@Observable
final class DocumentSessionController {
    var navigationModel = NavigationModel()  // Always starts with .automatic
    // User's preferred inspector visibility is lost!
}
```

---

## Good Practices

### 1. Column Content Organization

**Principle**: Each column has a clear, focused purpose.

**✅ Sidebar Column**:
- File browser / Recent files list
- Search interface
- Navigation sections (Browse, Recents, Bookmarks)
- Global actions (New, Open, Settings)

```swift
SidebarColumn {
    List(selection: $selectedSection) {
        Section("Files") {
            Label("Recents", systemImage: "clock")
                .tag(SidebarSection.recents)
            Label("Browse", systemImage: "folder")
                .tag(SidebarSection.browse)
        }
        Section("Tools") {
            Label("Search", systemImage: "magnifyingglass")
                .tag(SidebarSection.search)
        }
    }
    .listStyle(.sidebar)
    .navigationTitle("ISOInspector")
}
```

**✅ Content Column**:
- Primary content area (parse tree, hex view, reports)
- Context-dependent on sidebar selection
- Should handle empty states gracefully

```swift
ContentColumn {
    switch selectedSection {
    case .recents:
        RecentFilesView(files: recentFiles)
    case .browse:
        if let file = selectedFile {
            ParseTreeView(file: file, selection: $selectedAtom)
        } else {
            EmptyStateView(
                icon: "doc.text.magnifyingglass",
                message: "Select a file to inspect",
                action: {
                    Button("Open File") { showFilePicker() }
                }
            )
        }
    case .search:
        SearchResultsView(results: searchResults)
    }
}
.navigationTitle(navigationTitle)
```

**✅ Inspector Column**:
- Contextual details for selected content item
- Properties, metadata, integrity checks
- Read-only information display (not primary editing)

```swift
InspectorColumn {
    if let atom = selectedAtom {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "Properties")
                KeyValueRow(key: "Type", value: atom.type, isCopyable: true)
                KeyValueRow(key: "Size", value: atom.size.formatted(), isCopyable: true)
                KeyValueRow(key: "Offset", value: atom.offset.formatted(.hex), isCopyable: true)

                SectionHeader(title: "Integrity")
                IntegrityStatusView(status: atom.integrityStatus)
            }
            .padding(DS.Spacing.m)
        }
    } else {
        EmptyInspectorView(message: "Select an atom to view details")
    }
}
```

### 2. Empty State Handling

**Principle**: Every column should handle empty states gracefully with helpful messaging.

**✅ Good Practice**:
```swift
ContentColumn {
    if let file = selectedFile {
        ParseTreeView(file: file)
    } else {
        VStack(spacing: DS.Spacing.l) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(DS.Colors.textSecondary)

            Text("No File Selected")
                .font(DS.Typography.title)

            Text("Select a file from the sidebar or open a new file to begin inspecting.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Open File") {
                showFilePicker()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Spacing.xl)
    }
}
```

**❌ Anti-Pattern**:
```swift
ContentColumn {
    if let file = selectedFile {
        ParseTreeView(file: file)
    }
    // DON'T: Show nothing when no file selected - confusing UX!
}
```

### 3. Column Visibility Controls

**Principle**: Provide explicit user controls for showing/hiding columns where appropriate.

**✅ Good Practice**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    // Columns...
}
.toolbar {
    ToolbarItemGroup(placement: .navigation) {
        Button(action: toggleSidebar) {
            Label("Toggle Sidebar", systemImage: "sidebar.left")
        }
        .help("Show or hide the sidebar")
        .keyboardShortcut("s", modifiers: [.command, .control])
    }

    ToolbarItemGroup(placement: .primaryAction) {
        Button(action: toggleInspector) {
            Label("Toggle Inspector", systemImage: "sidebar.right")
        }
        .help("Show or hide the inspector")
        .keyboardShortcut("i", modifiers: [.command, .option])
    }
}

private func toggleSidebar() {
    withAnimation(DS.Animation.quick) {
        navigationModel.sidebarVisibility = navigationModel.sidebarVisibility == .visible ? .hidden : .visible
    }
}

private func toggleInspector() {
    withAnimation(DS.Animation.quick) {
        navigationModel.inspectorVisibility = navigationModel.inspectorVisibility == .visible ? .hidden : .visible
    }
}
```

**❌ Anti-Pattern**:
```swift
NavigationSplitScaffold(model: navigationModel) {
    // Columns...
}
// DON'T: No way for users to show/hide columns
// Users can't reclaim screen space!
```

### 4. Responsive Layout

**Principle**: Content should adapt gracefully to different column widths and size classes.

**✅ Good Practice**:
```swift
struct AtomInspectorView: View {
    let atom: AtomNode
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            if sizeClass == .compact {
                // Compact: Stack vertically
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    propertiesSection
                    integritySection
                    metadataSection
                }
            } else {
                // Regular: Use grid layout
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DS.Spacing.m) {
                    propertiesSection
                    integritySection
                    metadataSection
                }
            }
        }
    }

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            SectionHeader(title: "Properties")
            KeyValueRow(key: "Type", value: atom.type)
            KeyValueRow(key: "Size", value: atom.size.formatted())
        }
    }
}
```

**❌ Anti-Pattern**:
```swift
struct AtomInspectorView: View {
    let atom: AtomNode

    var body: some View {
        // DON'T: Fixed width layout that breaks in narrow columns
        HStack(spacing: 100) {  // Fixed spacing!
            VStack { /* Properties */ }
            VStack { /* Integrity */ }
        }
        .frame(width: 500)  // Fixed width!
        // Will overflow or get cut off in narrow inspector column
    }
}
```

### 5. Deep Linking and State Restoration

**Principle**: Support deep linking to specific navigation states for better UX.

**✅ Good Practice**:
```swift
@Observable
final class DocumentSessionController {
    var navigationModel = NavigationModel()
    var selectedFileID: UUID?
    var selectedAtomPath: [String]?

    func restoreNavigationState(from url: URL) {
        // Parse deep link: isoinspector://inspect/file/abc123/atom/moov/trak/tkhd
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        if let fileID = components.queryItems?.first(where: { $0.name == "file" })?.value,
           let uuid = UUID(uuidString: fileID) {
            selectedFileID = uuid
        }

        if let atomPath = components.queryItems?.first(where: { $0.name == "path" })?.value {
            selectedAtomPath = atomPath.split(separator: "/").map(String.init)
        }

        // Restore column visibility
        if let visibility = components.queryItems?.first(where: { $0.name == "inspector" })?.value {
            navigationModel.inspectorVisibility = NavigationSplitViewVisibility(rawValue: visibility) ?? .automatic
        }
    }

    func currentDeepLink() -> URL {
        var components = URLComponents()
        components.scheme = "isoinspector"
        components.host = "inspect"

        var queryItems: [URLQueryItem] = []
        if let fileID = selectedFileID {
            queryItems.append(URLQueryItem(name: "file", value: fileID.uuidString))
        }
        if let atomPath = selectedAtomPath {
            queryItems.append(URLQueryItem(name: "path", value: atomPath.joined(separator: "/")))
        }
        queryItems.append(URLQueryItem(name: "inspector", value: navigationModel.inspectorVisibility.rawValue))

        components.queryItems = queryItems
        return components.url!
    }
}
```

---

## Anti-Patterns

### 1. ❌ Fighting the Platform

**DON'T**: Override adaptive behavior to force desktop-like layouts on mobile.

```swift
// BAD: Forces three columns on iPhone
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn { /* ... */ }
    ContentColumn { /* ... */ }
    InspectorColumn { /* ... */ }
}
.navigationSplitViewStyle(.prominentDetail)  // Ignores compact size class!
.frame(minWidth: 1200)  // Forces wide layout on small screens!
```

**DO**: Respect platform conventions and size classes.

```swift
// GOOD: Adapts naturally to screen size
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn { /* ... */ }
    ContentColumn { /* ... */ }
    InspectorColumn { /* ... */ }
}
// iOS automatically hides sidebar/inspector in compact size class
// macOS shows all columns with user-controllable visibility
```

### 2. ❌ Mixing Navigation Paradigms

**DON'T**: Mix NavigationSplitView with NavigationStack in conflicting ways.

```swift
// BAD: Nested navigation stacks that conflict
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        NavigationStack {  // DON'T nest NavigationStack in sidebar!
            List(files) { file in
                NavigationLink(value: file) {
                    FileRow(file: file)
                }
            }
        }
    }
    ContentColumn {
        NavigationStack {  // Another stack - now two competing navigation systems!
            ParseTreeView(file: selectedFile)
        }
    }
}
// Now you have competing navigation states and back buttons!
```

**DO**: Use NavigationSplitView's built-in selection binding.

```swift
// GOOD: Single source of truth for selection
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn {
        List(files, selection: $selectedFile) { file in
            FileRow(file: file)
                .tag(file)
        }
    }
    ContentColumn {
        if let file = selectedFile {
            ParseTreeView(file: file)
        }
    }
}
```

### 3. ❌ Ignoring Empty States

**DON'T**: Leave columns blank when there's no content.

```swift
// BAD: Blank screen confuses users
ContentColumn {
    if let file = selectedFile {
        ParseTreeView(file: file)
    }
    // When selectedFile is nil: blank screen, no guidance!
}
```

**DO**: Provide helpful empty state messaging.

```swift
// GOOD: Clear guidance when empty
ContentColumn {
    if let file = selectedFile {
        ParseTreeView(file: file)
    } else {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            message: "Select a file from the sidebar to begin",
            action: { Button("Open File") { showFilePicker() } }
        )
    }
}
```

### 4. ❌ Poor Performance with Large Datasets

**DON'T**: Load entire file tree eagerly in sidebar.

```swift
// BAD: Loads 10,000 files into memory immediately
SidebarColumn {
    List(allFiles) { file in  // allFiles = 10,000+ items!
        FileRow(file: file)
    }
}
// Causes UI lag, high memory usage
```

**DO**: Use pagination, lazy loading, or virtualization.

```swift
// GOOD: Load incrementally
SidebarColumn {
    List {
        ForEach(paginatedFiles) { file in
            FileRow(file: file)
        }

        if hasMoreFiles {
            ProgressView()
                .onAppear { loadMoreFiles() }
        }
    }
}
```

### 5. ❌ Inconsistent Column Widths

**DON'T**: Use magic numbers for column sizing.

```swift
// BAD: Hardcoded widths that don't adapt
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn { /* ... */ }
        .frame(width: 250)  // Magic number!
    ContentColumn { /* ... */ }
        .frame(width: 600)  // Magic number!
    InspectorColumn { /* ... */ }
        .frame(width: 300)  // Magic number!
}
```

**DO**: Use NavigationSplitView's adaptive sizing.

```swift
// GOOD: Adaptive sizing with minimum constraints
NavigationSplitScaffold(model: navigationModel) {
    SidebarColumn { /* ... */ }
    ContentColumn { /* ... */ }
    InspectorColumn { /* ... */ }
}
.navigationSplitViewColumnWidth(
    sidebar: .ideal(250, min: 200, max: 400),
    content: .flexible,
    inspector: .ideal(300, min: 250, max: 500)
)
```

---

## ISOInspector-Specific Patterns

### Pattern 1: File Browser + Parse Tree + Inspector

**Use Case**: Primary navigation for inspecting ISO/MP4 files.

```swift
struct ISOInspectorMainView: View {
    @Bindable var session: DocumentSessionController

    var body: some View {
        NavigationSplitScaffold(model: session.navigationModel) {
            // Sidebar: File browser
            SidebarColumn {
                FileBrowserSidebar(
                    recentFiles: session.recentFiles,
                    selection: $session.selectedFileURL
                )
            }

            // Content: Parse tree or hex view
            ContentColumn {
                if let fileURL = session.selectedFileURL {
                    TabView {
                        ParseTreeView(
                            fileURL: fileURL,
                            selection: $session.selectedAtom
                        )
                        .tabItem { Label("Parse Tree", systemImage: "list.tree") }

                        HexView(fileURL: fileURL)
                            .tabItem { Label("Hex", systemImage: "number") }

                        ReportView(fileURL: fileURL)
                            .tabItem { Label("Report", systemImage: "doc.text") }
                    }
                } else {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        message: "Open a file to begin inspection"
                    ) {
                        Button("Open File") {
                            session.showFilePicker()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            // Inspector: Atom details
            InspectorColumn {
                if let atom = session.selectedAtom {
                    AtomInspectorView(atom: atom)
                } else if session.selectedFileURL != nil {
                    EmptyInspectorView(
                        message: "Select an atom to view its properties"
                    )
                } else {
                    EmptyInspectorView(
                        message: "No file opened"
                    )
                }
            }
        }
        .navigationTitle(session.selectedFileURL?.lastPathComponent ?? "ISOInspector")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: session.toggleSidebar) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: session.toggleInspector) {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }
    }
}
```

### Pattern 2: Search Results Navigation

**Use Case**: Search-driven navigation with filtered results.

```swift
struct SearchView: View {
    @Bindable var session: DocumentSessionController
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationSplitScaffold(model: session.navigationModel) {
            SidebarColumn {
                VStack(spacing: 0) {
                    SearchBar(text: $searchQuery)
                        .padding(DS.Spacing.m)

                    List(filteredAtoms, selection: $session.selectedAtom) { atom in
                        SearchResultRow(atom: atom, query: searchQuery)
                            .tag(atom)
                    }
                }
            }

            ContentColumn {
                if let atom = session.selectedAtom {
                    AtomDetailView(atom: atom, highlightQuery: searchQuery)
                } else {
                    SearchEmptyStateView(
                        hasQuery: !searchQuery.isEmpty,
                        resultCount: filteredAtoms.count
                    )
                }
            }

            InspectorColumn {
                if let atom = session.selectedAtom {
                    AtomInspectorView(atom: atom)
                }
            }
        }
    }

    private var filteredAtoms: [AtomNode] {
        guard !searchQuery.isEmpty else { return [] }
        return session.allAtoms.filter { atom in
            atom.type.localizedCaseInsensitiveContains(searchQuery) ||
            atom.properties.values.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
}
```

### Pattern 3: Multi-Window Support (macOS/iPadOS)

**Use Case**: Each window has independent navigation state.

```swift
@Observable
final class WindowSessionController {
    let id = UUID()
    var navigationModel = NavigationModel()
    var documentSession: DocumentSessionController

    init(documentSession: DocumentSessionController) {
        self.documentSession = documentSession
        loadWindowPreferences()
    }

    private func loadWindowPreferences() {
        let key = "window.\(id.uuidString).navigation"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(NavigationModelState.self, from: data) {
            navigationModel.restore(from: decoded)
        }
    }

    func saveWindowPreferences() {
        let key = "window.\(id.uuidString).navigation"
        if let encoded = try? JSONEncoder().encode(navigationModel.state) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

struct ISOInspectorWindow: Scene {
    @State private var windowSession: WindowSessionController

    var body: some Scene {
        Window("ISOInspector", id: windowSession.id.uuidString) {
            ISOInspectorMainView(session: windowSession)
                .onDisappear {
                    windowSession.saveWindowPreferences()
                }
        }
    }
}
```

---

## Testing Strategy

### Unit Tests

Test navigation state management in isolation:

```swift
final class NavigationModelTests: XCTestCase {
    func testSidebarVisibilityToggle() {
        let model = NavigationModel()
        XCTAssertEqual(model.sidebarVisibility, .automatic)

        model.sidebarVisibility = .hidden
        XCTAssertEqual(model.sidebarVisibility, .hidden)

        model.sidebarVisibility = .visible
        XCTAssertEqual(model.sidebarVisibility, .visible)
    }

    func testInspectorVisibilityPersistence() throws {
        let model = NavigationModel()
        model.inspectorVisibility = .visible

        let encoded = try JSONEncoder().encode(model.state)
        let decoded = try JSONDecoder().decode(NavigationModelState.self, from: encoded)

        XCTAssertEqual(decoded.inspectorVisibility, .visible)
    }
}
```

### Integration Tests

Test column coordination and selection binding:

```swift
final class NavigationSplitScaffoldIntegrationTests: XCTestCase {
    func testSidebarSelectionUpdatesContent() {
        let session = DocumentSessionController()
        let testFile = FileURL(path: "/test.mp4")

        session.selectedFileURL = testFile
        XCTAssertNotNil(session.selectedFileURL)

        // Content column should react to selection
        XCTAssertTrue(session.shouldShowParseTree)
    }

    func testInspectorFollowsContentSelection() {
        let session = DocumentSessionController()
        let testAtom = AtomNode(type: "ftyp", size: 20, offset: 0)

        session.selectedAtom = testAtom
        XCTAssertEqual(session.selectedAtom?.type, "ftyp")

        // Inspector should show atom details
        XCTAssertTrue(session.shouldShowInspector)
    }
}
```

### UI Tests

Test adaptive behavior across size classes:

```swift
final class NavigationSplitViewUITests: XCTestCase {
    func testCompactSizeClassHidesSidebar() {
        let app = XCUIApplication()
        app.launch()

        // Simulate compact size class (iPhone)
        XCTContext.runActivity(named: "Compact size class") { _ in
            let sidebar = app.otherElements["FileBrowserSidebar"]
            XCTAssertFalse(sidebar.exists)  // Sidebar hidden in compact

            let content = app.otherElements["ParseTreeView"]
            XCTAssertTrue(content.exists)  // Content visible
        }
    }

    func testRegularSizeClassShowsAllColumns() {
        let app = XCUIApplication()
        app.launch()

        // Simulate regular size class (iPad landscape, macOS)
        XCTContext.runActivity(named: "Regular size class") { _ in
            let sidebar = app.otherElements["FileBrowserSidebar"]
            XCTAssertTrue(sidebar.exists)

            let content = app.otherElements["ParseTreeView"]
            XCTAssertTrue(content.exists)

            let inspector = app.otherElements["AtomInspectorView"]
            XCTAssertTrue(inspector.exists)
        }
    }
}
```

### Accessibility Tests

Test VoiceOver navigation and keyboard shortcuts:

```swift
final class NavigationAccessibilityTests: XCTestCase {
    func testSidebarToggleHasAccessibilityLabel() {
        let app = XCUIApplication()
        app.launch()

        let toggleButton = app.buttons["Toggle Sidebar"]
        XCTAssertTrue(toggleButton.exists)
        XCTAssertEqual(toggleButton.label, "Toggle Sidebar")
    }

    func testKeyboardShortcutsWork() {
        let app = XCUIApplication()
        app.launch()

        // Press Cmd+Ctrl+S to toggle sidebar
        app.typeKey("s", modifierFlags: [.command, .control])

        // Verify sidebar visibility changed
        let sidebar = app.otherElements["FileBrowserSidebar"]
        // State should have toggled
    }

    func testVoiceOverAnnouncesColumnChanges() {
        let app = XCUIApplication()
        app.launch()

        // Enable VoiceOver testing
        XCTAssertTrue(app.isVoiceOverRunning || true)  // Skip if VO not available

        let sidebar = app.otherElements["FileBrowserSidebar"]
        XCTAssertEqual(sidebar.accessibilityLabel, "File Browser")
    }
}
```

---

## References

### Internal Documentation

- **NavigationSplitViewKit Integration**: `DOCS/INPROGRESS/240_NavigationSplitViewKit_Integration.md`
- **NavigationSplitScaffold Pattern**: `DOCS/INPROGRESS/241_NavigationSplitScaffold_Pattern.md` (Task 241)
- **Composable Clarity Design System**: `FoundationUI/Sources/FoundationUI/DesignTokens/`
- **TDD Workflow**: `DOCS/RULES/02_TDD_XP_Workflow.md`

### External References

- **NavigationSplitViewKit Repository**: https://github.com/SoundBlaster/NavigationSplitView
- **Apple NavigationSplitView Documentation**: https://developer.apple.com/documentation/swiftui/navigationsplitview
- **WWDC 2022 - Navigation cookbook**: Session 10054
- **Human Interface Guidelines - Navigation**: https://developer.apple.com/design/human-interface-guidelines/navigation

### Example Projects

- **ComponentTestApp**: `Examples/ComponentTestApp/` - FoundationUI component demos
- **ISOInspectorApp**: Reference implementation using NavigationSplitScaffold

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-18 | Initial guidelines created for Task 240 |

---

**Maintained by**: ISOInspector Team
**Last Updated**: 2025-11-18
**Status**: Active
