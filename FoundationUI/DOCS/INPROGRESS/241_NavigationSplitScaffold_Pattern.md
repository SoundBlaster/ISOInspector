# Task 241: Create NavigationSplitScaffold Pattern

**Phase**: 3.1 (Patterns & Platform Adaptation)
**Priority**: P0 (Critical for cross-platform navigation)
**Status**: Pending (Depends on Task 240)
**Created**: 2025-11-18
**Specification**: [`NEW_NavigationSplitViewKit_Proposal.md`](./NEW_NavigationSplitViewKit_Proposal.md)

---

## 🎯 Objective

Create a `NavigationSplitScaffold` wrapper pattern that integrates `NavigationSplitViewKit.NavigationModel` with FoundationUI's design system. The scaffold becomes the architectural skeleton for iOS/iPadOS/macOS apps, coordinating three columns (Sidebar, Content, Detail) while allowing existing FoundationUI patterns (SidebarPattern, InspectorPattern) to remain focused on their specific layout responsibilities.

---

## 🧩 Context

**Dependency**: Task 240 (Integrate NavigationSplitViewKit dependency) must complete first.

The `NavigationSplitScaffold` pattern acts as a **Layer 3 Community** (not an Organism itself) that:

1. **Owns layout orchestration** — Manages three-column layout rules and column visibility across all size classes
2. **Provides shared state** — Exposes `NavigationModel` via environment so downstream patterns can query navigation state without owning it
3. **Applies design tokens** — All spacing, colors, animations use DS tokens (zero magic numbers)
4. **Supports accessibility** — Column toggles expose VoiceOver labels, keyboard shortcuts (⌘1/⌘2/⌘3)

**Column Responsibilities** (ISOInspector reference implementation):
- **Sidebar** → Lightweight hub for recent files + global actions
- **Content** → Powered by `BoxTreePattern`, hierarchical navigator
- **Detail** → Actual Box content or preview surface users work in
- **Inspector (optional)** → Floats above columns, shows properties/metadata/bookmarks without duplicating content

---

## ✅ Success Criteria

### Core API
1. **NavigationSplitScaffold struct implemented**:
   - Generic over Sidebar, Content, Detail view types
   - Public initializer accepting ViewBuilder closures
   - Applies `NavigationSplitViewKit.NavigationSplitView` internally
   - All layout constants sourced from DS tokens

2. **Environment key for NavigationModel**:
   - `NavigationModelKey` defined for passing model to child views
   - Downstream patterns can access via `@Environment(\.navigationModel)`
   - Thread-safe, follows FoundationUI conventions

3. **Design token application**:
   - `.navigationSplitAppearance(.foundation)` sets custom appearance
   - Spacing: DS.Spacing tokens for sidebars, inspector gutters
   - Colors: DS.Colors for backgrounds and selection states
   - Animation: DS.Animation.medium for column transitions
   - Typography: DS.Typography for headers
   - Zero magic numbers validation in SwiftLint

### Testing Coverage
1. **Unit tests** (≥20 test cases):
   - Model initialization and binding verification
   - Environment key propagation to child views
   - Column visibility state transitions
   - Inspector pinning toggle behavior
   - Size class detection (compact, regular)

2. **Snapshot tests**:
   - Three-column layout (macOS landscape, iPad landscape)
   - Two-column compact (iPad portrait)
   - Single-column compact (iPhone portrait)
   - Light/Dark mode variants
   - Dynamic Type (XS, M, XXL)
   - Inspector pinned vs. unpinned

3. **Integration tests** (≥15 test cases):
   - Scaffold + SidebarPattern + InspectorPattern composition
   - Environment value propagation through nested patterns
   - Keyboard shortcut navigation (⌘1/⌘2/⌘3)
   - Focus management across columns
   - Platform-specific behaviors (macOS vs iOS vs iPad)

### Accessibility
1. **VoiceOver support**:
   - Column toggle buttons expose descriptive labels
   - Focus order preserved when columns appear/disappear
   - Navigation state announced on changes

2. **Keyboard navigation**:
   - ⌘1 → Focus Sidebar column
   - ⌘2 → Focus Content column
   - ⌘3 → Focus Detail/Inspector column
   - Tab key navigates between columns when active

3. **Reduce Motion**:
   - Animated column transitions respect `accessibilityReduceMotion`
   - Inspector appearance uses `DS.Animation.quick` or instant when enabled

### Documentation
1. **DocC article**: `CreatingNavigationScaffolds.md`
   - Explains scaffold architecture vs. traditional patterns
   - Shows how to embed SidebarPattern, InspectorPattern, etc.
   - Platform adaptation examples (iOS portrait, iPad landscape, macOS)

2. **Code examples**:
   - Minimal scaffold example (3 closures, basic content)
   - ISOInspector reference implementation with Sidebar, BoxTree, Inspector
   - Platform-specific customization patterns

3. **API reference**:
   - Public types: `NavigationSplitScaffold`, `NavigationModelKey`, `NavigationModelEnvironmentKey`
   - 100% DocC coverage with parameter descriptions
   - "See Also" cross-references to related patterns

4. **SwiftUI Previews**:
   - 6+ previews covering three-column, compact variants
   - Real-world ISO Inspector mockup with actual patterns
   - Platform comparison side-by-side
   - Inspector pinned/unpinned variants
   - Dark mode support
   - Accessibility features demo

### Agent Support (Stretch)
1. **AgentDescribable conformance** (if time permits):
   - Expose scaffold configuration via `componentType: "NavigationSplitScaffold"`
   - Properties for column count, inspector pinned state, preferred visibility
   - Schema defined in `ComponentSchema.yaml`

---

## 🔧 Implementation Plan

### Phase 1: Core API (Days 1–1.5)

**File**: `Sources/FoundationUI/Patterns/NavigationSplitScaffold.swift` (300+ lines expected)

```swift
import SwiftUI
import NavigationSplitViewKit

public struct NavigationSplitScaffold<Sidebar: View, Content: View, Detail: View>: View {
    @Bindable var navigationModel: NavigationModel
    let sidebar: Sidebar
    let content: Content
    let detail: Detail

    public init(
        model: NavigationModel = NavigationModel(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) { ... }

    public var body: some View {
        NavigationSplitView(
            columnVisibility: $navigationModel.columnVisibility,
            preferredCompactColumn: $navigationModel.preferredCompactColumn
        ) {
            sidebar
                .environment(\.navigationModel, navigationModel)
        } content: {
            content
                .environment(\.navigationModel, navigationModel)
        } detail: {
            detail
                .environment(\.navigationModel, navigationModel)
        }
        .navigationSplitAppearance(.foundation)
        .animation(DS.Animation.medium, value: navigationModel.columnVisibility)
    }
}

// Environment key for exposing navigation state
struct NavigationModelKey: EnvironmentKey {
    static let defaultValue: NavigationModel? = nil
}

extension EnvironmentValues {
    var navigationModel: NavigationModel? {
        get { self[NavigationModelKey.self] }
        set { self[NavigationModelKey.self] = newValue }
    }
}
```

**Tasks**:
1. ✅ Define `NavigationSplitScaffold` generic struct with ViewBuilder support
2. ✅ Implement `body` property with NavigationSplitViewKit integration
3. ✅ Create `NavigationModelKey` environment key
4. ✅ Add extension to `EnvironmentValues` for convenient access
5. ✅ Apply all DS tokens (spacing, colors, animation)
6. ✅ 100% DocC documentation with parameter docs

### Phase 2: Unit & Integration Tests (Days 1.5–2.5)

**File**: `Tests/FoundationUITests/PatternsTests/NavigationSplitScaffoldTests.swift` (600+ lines)

1. **Unit tests** (20+ cases):
   - Initialization and bindings
   - Environment key propagation
   - State transitions (show/hide columns)
   - Inspector pinning
   - Size class adaptations

2. **Integration tests** (15+ cases):
   - Scaffold + SidebarPattern
   - Scaffold + InspectorPattern
   - Full three-pattern composition
   - Keyboard navigation
   - Accessibility attributes

3. **Snapshot tests** (platform-gated):
   - Record baselines for macOS, iOS, iPad
   - Verify layout consistency across platforms

### Phase 3: SwiftUI Previews (Days 2.5–3)

**File**: `Sources/FoundationUI/Patterns/NavigationSplitScaffold+Previews.swift` (400+ lines)

Previews to implement:
1. **Simple Three-Column** — Basic sidebar, content, detail
2. **Compact TwoColumn** — Sidebar + Content (inspector collapsed)
3. **SingleColumn iPhone** — Stack-style navigation
4. **ISO Inspector Reference** — Real mockup with Sidebar, BoxTree, Detail
5. **Inspector Pinned** — Inspector always visible
6. **Dark Mode** — All variants in dark appearance
7. **Accessibility Inspector** — VoiceOver labels and keyboard shortcuts
8. **Platform Comparison** — iOS/iPad/macOS side-by-side

### Phase 4: Documentation (Days 3–3.5)

1. **DocC article**: `Sources/FoundationUI/Documentation.docc/Articles/CreatingNavigationScaffolds.md` (2KB+)
   - Role in FoundationUI architecture
   - When to use vs. custom layouts
   - Platform adaptation patterns
   - Integration with existing patterns

2. **Update Architecture.md** to reference NavigationSplitScaffold as coordination layer

3. **Create usage guide** in `Sources/FoundationUI/Patterns/NavigationSplitScaffold.swift` DocC

---

## 🧪 Verification Steps

### Build & Compile
```bash
cd FoundationUI
swift build
# Must succeed without warnings
```

### Run Tests
```bash
swift test --filter NavigationSplitScaffoldTests
# All 35+ tests must pass
```

### Snapshot Tests (via Tuist)
```bash
tuist build FoundationUISnapshotTests --scheme FoundationUISnapshotTests
# Record baselines: xcrun simctl spawn booted defaults write com.apple.CoreSimulator.CoreSimulatorService DevicePreferences '{"udid": "snapshot"}'
```

### SwiftLint Validation
```bash
swiftlint lint --strict
# Zero violations in new files
```

### DocC Build
```bash
docc convert Sources/FoundationUI/Documentation.docc \
    --fallback-display-name FoundationUI \
    --fallback-bundle-identifier com.foundationui \
    --output-path /tmp/docc-build
# Build succeeds without warnings
```

---

## 🔍 Known Constraints

1. **Platform Support**: NavigationSplitViewKit must support iOS 17+, iPadOS 17+, macOS 14+ without platform gates.

2. **State Synchronization**: The `NavigationModel` is mutable and uses `@Bindable`. Ensure no race conditions in multi-threaded access (unit tests will verify).

3. **Column Pinning**: Inspector pinning is a `NavigationSplitViewKit` feature; document any platform-specific limitations.

4. **Performance**: Test with many rows in sidebar/content to ensure 60 FPS rendering. LazyVStack may be needed for large datasets.

---

## 📋 Dependencies & Blockers

- **Blocker**: Task 240 (NavigationSplitViewKit integration) must complete first
- **Related**: Task 242 (Update existing patterns) builds on this
- **Follow-up**: Agent YAML schema updates for navigation-driven layouts

---

## 🔗 References

- **Specification**: [`NEW_NavigationSplitViewKit_Proposal.md`](./NEW_NavigationSplitViewKit_Proposal.md)
- **Task Plan**: [`FoundationUI_TaskPlan.md`](../TASK_ARCHIVE/FoundationUI_TaskPlan.md) — Phase 3.1, item 445–462
- **PRD**: [`FoundationUI_PRD.md`](../../DOCS/AI/ISOViewer/FoundationUI_PRD.md) — Section 4.3
- **Upstream Package**: https://github.com/SoundBlaster/NavigationSplitView

---

## ⚡ Effort Estimate

- **Core API**: 1 day
- **Testing**: 1.5 days
- **Previews & Examples**: 1 day
- **Documentation**: 0.5 days

**Total**: ~4 days (can be split across two sprints if needed)

---

**Last Updated**: 2025-11-18
**Assigned To**: Claude Agent
**Status**: Pending Task 240 Completion
