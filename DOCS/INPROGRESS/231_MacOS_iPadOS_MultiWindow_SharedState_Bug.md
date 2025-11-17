# Bug Report #231: macOS/iPadOS Multiple Windows Share Application State

**Date Reported**: 2025-11-17
**Severity**: HIGH
**Status**: IN PROGRESS

---

## 📋 OBJECTIVE

Fix the issue where multiple windows of ISOInspector application on macOS and iPadOS share a common application state, causing changes in one window to affect all other windows. Each window should maintain independent state for file selection, detail views, and other session-specific properties.

---

## 🔴 SYMPTOMS

When a user creates multiple windows of the ISOInspector application:

1. **State Sharing**: All windows display the same application state
2. **File Selection**: Changing the selected file in one window immediately changes the selection in all other windows
3. **View State**: Detail panel content, hex viewer selections, and other UI state changes propagate across all windows
4. **Expected Behavior**: Each window should operate independently with its own document context and view state

**Example Scenario**:
- User opens Window A with `document1.iso` and selects item X
- User opens Window B with `document2.iso` and selects item Y
- **Actual Result**: Both windows now show `document2.iso` with item Y selected
- **Expected Result**: Window A shows `document1.iso` with item X; Window B shows `document2.iso` with item Y

---

## 🌍 ENVIRONMENT

- **Platform**: macOS (confirmed), iPadOS (probable)
- **iOS Version**: iOS 16+ / iPadOS 16+ / macOS 12+
- **Application**: ISOInspector
- **Multi-Window Support**: Enabled via `WindowGroup` in SwiftUI

---

## 🔄 REPRODUCTION STEPS

### On macOS:
1. Launch ISOInspector
2. Open an ISO file (e.g., `document1.iso`)
3. Select an item in the tree view
4. Create a new window: `Window > New Window` (or Command+N)
5. Open a different ISO file in the new window (e.g., `document2.iso`)
6. Select a different item in the new window
7. Switch back to the first window
8. **Expected**: First window still shows `document1.iso` with original selection
9. **Actual**: First window now shows `document2.iso` with the new selection

### On iPadOS:
1. Launch ISOInspector on iPad
2. Open an ISO file in the main window
3. Select an item
4. Drag ISOInspector to split-screen or use Stage Manager to create a second window
5. Open a different ISO file in the second window
6. Select a different item
7. Switch back to the first window
8. **Expected**: First window maintains its own state
9. **Actual**: First window reflects the state from the second window

---

## ✅ EXPECTED vs ACTUAL

| Aspect | Expected | Actual |
|--------|----------|--------|
| **File Selection** | Each window has independent file selection | All windows share the same file |
| **Tree Selection** | Each window has independent tree item selection | All windows select the same item |
| **Detail Panel** | Each window shows details for its own selected item | All windows show details from last selection globally |
| **Hex Viewer** | Each window's hex viewer is independent | All windows scroll/position synchronized |
| **Search State** | Each window can search independently | Search state is shared |
| **Window Persistence** | Each window saves its own state on close | All windows share restoration state |

---

## ❓ OPEN QUESTIONS

1. Should each window persist its own session independently, or should windows share the open document list while maintaining per-window selections?
2. Should closing a window in a multi-window scenario close the document, or keep it open for other windows?
3. Should undo/redo state be global or per-window?

---

## 🔍 DIAGNOSTIC FINDINGS

### Root Cause Analysis

**Architecture Analysis** (from codebase exploration):

```
Current Architecture (Singleton Pattern):
┌─────────────────────────────────────────────┐
│          ISOInspectorApp (SwiftUI)          │
│                                             │
│  WindowGroup {                              │
│    DocumentView()                           │
│  }                                          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  DocumentSessionController @StateObject     │  ← SINGLETON INSTANCE
│  (Shared across ALL windows)                │
│                                             │
│  - currentDocument: DocumentViewModel       │
│  - selections: [SelectionViewModel]         │
│  - userPreferences: PreferencesStore        │
│  - validationConfig: ValidationConfig       │
└─────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│          All WindowGroup Views              │
│  (Share same controller instance)           │
└─────────────────────────────────────────────┘
```

**Current Implementation Issues**:

1. **`DocumentSessionController`** (Sources/ISOInspectorApp/State/DocumentSessionController.swift)
   - Created as `@StateObject` in the app root
   - Single instance shared across all windows via `environmentObject`
   - Mutation of any property (currentDocument, selections, etc.) affects all windows

2. **`DocumentViewModel`** (State/DocumentViewModel.swift)
   - Contains document-specific state (parse tree, detail panel state, hex viewer state)
   - Published properties change for all observers when mutations occur

3. **Scene/Window Isolation Needed**:
   - No per-window state container
   - No SceneDelegate or WindowGroup scene binding
   - All windows observe the same EnvironmentObject

### Affected Components

**Files requiring modification**:
- `Sources/ISOInspectorApp/ISOInspectorApp.swift` - App entry point
- `Sources/ISOInspectorApp/State/DocumentSessionController.swift` - Central state controller
- `Sources/ISOInspectorApp/State/DocumentViewModel.swift` - Document state
- `Sources/ISOInspectorApp/UI/DocumentView.swift` - Main view hierarchy

**Components that need per-window isolation**:
- DocumentViewModel (file, selections, detail panel state)
- TreeOutlineViewModel (expanded/collapsed state)
- DetailPanelViewModel (scroll position, selected details)
- HexViewerViewModel (scroll position, selection)
- SearchViewModel (search query, results)

---

## 📐 SCOPE & HYPOTHESES

### Front of Work
- **Area**: Multi-window state management on macOS/iPadOS
- **Functional Impact**: Document selection and view state isolation
- **Severity**: HIGH - Breaks core multi-window functionality

### Primary Hypothesis
**"State Leakage via Shared EnvironmentObject"**

The `DocumentSessionController` is created once at app launch and passed to all windows via `@EnvironmentObject`. When a window modifies the controller's state, all windows observing that controller see the changes.

### Secondary Hypotheses
1. **Session Restoration Issue**: Scene restoration may be incorrectly restoring all windows to the same state
2. **WindowGroup Binding Gap**: The WindowGroup binding to `id` parameter may not be properly isolating state
3. **@StateObject Lifecycle**: The lifecycle of @StateObject may not align with window lifecycle

---

## 🧪 TESTING PLAN

### Diagnostics Plan

**Phase 1: State Tracking**
```swift
// Add logging to DocumentSessionController
func didChangeCurrentDocument() {
    print("🔴 DIAGNOSTIC: currentDocument changed to: \(currentDocument?.fileURL?.lastPathComponent ?? "nil")")
    print("   Stack: \(Thread.callStackSymbols)")
    // Log which window/scene initiated the change
}
```

**Phase 2: Window Identification**
```swift
// Track which window is making changes
@available(iOS 16.0, macOS 13.0, *)
func windowScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first
}

// For macOS, use NSApplication.shared.windows
```

**Phase 3: State Isolation Verification**
- Add unique ID tracking to each window's state
- Verify that separate DocumentViewModels exist per window
- Confirm that @Published property changes only notify local observers

### TDD Testing Plan

**Test 1: Window Isolation - File Selection**
```swift
func testMultipleWindowsHaveIndependentFileSelection() {
    // Open document in window 1
    // Open different document in window 2
    // Assert: Window 1's document remains unchanged
    // Assert: Window 2's document is the new one
}
```

**Test 2: Window Isolation - Tree Selection**
```swift
func testMultipleWindowsHaveIndependentTreeSelection() {
    // Select item A in window 1
    // Select item B in window 2
    // Assert: Window 1 still has item A selected
    // Assert: Window 2 has item B selected
}
```

**Test 3: Window State Persistence**
```swift
func testWindowStatePersistedIndependently() {
    // Open window 1 with document A, item X selected
    // Open window 2 with document B, item Y selected
    // Close and reopen app
    // Assert: Window 1 restored to document A, item X
    // Assert: Window 2 restored to document B, item Y
}
```

**Test 4: Window Closure**
```swift
func testClosingWindowDoesNotAffectOtherWindows() {
    // Open window 1 with document A
    // Open window 2 with document B
    // Close window 2
    // Assert: Window 1 still has document A open
    // Assert: Window 1 selection unchanged
}
```

---

## 🛠️ REMEDIATION APPROACH

### Option A: Per-Window State Container (RECOMMENDED)

Create a `WindowState` structure that holds all window-specific state:

```swift
@MainActor
class WindowState: ObservableObject {
    @Published var documentViewModel: DocumentViewModel?
    @Published var treeOutline: TreeOutlineViewModel
    @Published var detailPanel: DetailPanelViewModel
    @Published var hexViewer: HexViewerViewModel
    @Published var search: SearchViewModel

    init(windowID: UUID) {
        self.windowID = windowID
        // Initialize with independent state
    }
}

// In ISOInspectorApp.swift:
WindowGroup(id: "document") { $document in
    DocumentView()
        .environmentObject(WindowState(windowID: document.id))  // Per-window state
        .environmentObject(appSessionController)  // Shared app-level state
}
```

### Option B: SceneDelegate Approach (iOS/iPadOS)

Implement `UIWindowSceneDelegate` to manage per-scene state (iOS 13+).

### Option C: Scene-Scoped StateObject (macOS 13+)

Use `@SceneStorage` to persist per-window state automatically:

```swift
@SceneStorage("selectedDocumentPath") var selectedDocument: URL?
```

---

## 📚 REFERENCE DOCUMENTS

- **Architecture Overview**: Explored via codebase analysis
- **Related Puzzles**: Puzzle #222 (Settings Panel) - Similar multi-window issue
- **State Management Pattern**: Combine + @StateObject + EnvironmentObject
- **Apple Documentation**: [Supporting Multiple Windows on iOS](https://developer.apple.com/documentation/uikit/supporting_multiple_windows_on_iphone_and_ipad)

---

## 📊 WORK TRACKING

### Implementation Checklist
- [ ] Step 1: Implement Per-Window State Container
- [ ] Step 2: Refactor DocumentSessionController to remove document state
- [ ] Step 3: Update WindowGroup binding to isolate state
- [ ] Step 4: Implement per-window session persistence
- [ ] Step 5: Write and execute automated tests
- [ ] Step 6: Manual testing on macOS and iPadOS
- [ ] Step 7: Update documentation and PRD

### Commit Targets
- Will be created on branch: `claude/fix-macos-ipados-bug-01AYY5MrfwRuCTX28KcS2XDZ`

---

## 📝 STATUS LOG

| Date | Status | Notes |
|------|--------|-------|
| 2025-11-17 | Opened | Bug report created, root cause identified as Singleton pattern in DocumentSessionController |
| 2025-11-17 | In Progress | Implementing per-window state isolation |
| 2025-11-17 | Completed | WindowSessionController implemented for per-window state; AppShellView and ISOInspectorApp refactored; unit tests added |
| 2025-11-17 | Fixed | Restored export functionality: exportJSON/exportIssueSummary now delegate to appSessionController with status forwarding via bindings |
| 2025-11-17 | Fixed | Fixed recents sidebar buttons: openRecent now routes through proper document loading path |
| 2025-11-17 | Fixed | Fixed main thread blocking: offloaded heavy parsing work to background Task.detached(priority: .userInitiated) |

---

## IMPLEMENTATION SUMMARY

### ✅ Completed Steps:
1. **Created WindowSessionController** (`Sources/ISOInspectorApp/State/WindowSessionController.swift`)
   - Per-window document state management
   - Independent ParseTreeStore and AnnotationBookmarkSession per window
   - Window-specific load failures and export status

2. **Refactored AppShellView**
   - Changed from shared `DocumentSessionController` to per-window `WindowSessionController`
   - All window-specific operations now delegate to `windowController`
   - Shared app-level operations still use `appController` (recents, preferences)

3. **Updated ISOInspectorApp**
   - Simplified WindowGroup to pass only `appController` to AppShellView
   - Each view creates its own `WindowSessionController` in init

4. **Added Unit Tests** (`Tests/ISOInspectorAppTests/WindowSessionControllerTests.swift`)
   - Test independent state between windows
   - Test isolated ParseTreeStore instances
   - Test isolated DocumentViewModel instances
   - Test isolated AnnotationSession instances

5. **Restored Export Functionality**
   - Export methods now properly delegate to `appSessionController.exportJSON/exportIssueSummary`
   - Window's `exportStatus` is synchronized with app controller's via Combine bindings
   - `dismissExportStatus` clears both window and app controller state

6. **Fixed Document Loading Performance**
   - Offloaded heavy I/O and parsing work from main thread to background task
   - Security-scoped file access remains on main thread (required by API)
   - Reader creation, pipeline initialization, and context setup run on `.userInitiated` priority background task
   - UI updates (parseTreeStore.start) return to main thread
   - Prevents UI freezing when opening large ISO/MP4 files

---

## NEXT STEPS

1. ✅ **COMPLETED**: Bug report captured and root cause identified
2. ✅ **COMPLETED**: Implement per-window state container (Option A)
3. ✅ **COMPLETED**: Write unit tests for window isolation
4. **PENDING**: Manual testing on macOS and iPadOS
5. **PENDING**: Archive to TASK_ARCHIVE upon completion

