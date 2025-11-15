# NavigationSplitViewKit Integration Specification

## Overview

Integrate the external `NavigationSplitViewKit` Swift package to provide a reusable, adaptive navigation scaffold for FoundationUI patterns. This dependency unlocks a consistent three-column navigation experience for ISOInspectorApp (iOS, iPadOS, macOS) and ensures Sidebar, Inspector, and future navigation-driven patterns share a unified state model.

### Role inside FoundationUI

- `NavigationSplitScaffold` is the skeleton for ISOInspectorApp – it owns layout orchestration for Sidebar → Content → Inspector and exposes a single navigation state to the rest of the design system.
- `SidebarPattern` and `InspectorPattern` remain focused, column-scoped patterns; they plug into the scaffold instead of replacing it.
- Downstream contexts (BoxTree, Toolbar, inspector detail panes) rely on the scaffold to understand how their column is presented, eliminating duplicated navigation rules.

## Layer Classification

- **Layer**: 3
- **Type**: Pattern (navigation scaffold)
- **Priority**: P0 (required for cross-platform navigation skeleton)

## API Design

### Swift API

```swift
import FoundationUI
import NavigationSplitViewKit

public struct NavigationSplitScaffold<Sidebar: View, Content: View, Detail: View>: View {
    @Bindable private var navigationModel: NavigationModel
    private let sidebar: Sidebar
    private let content: Content
    private let detail: Detail

    public init(
        model: NavigationModel = NavigationModel(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.navigationModel = model
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
    }

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
```

### Design Tokens Used

- `DS.Spacing` — spacing for sidebar/list row padding and inspector gutter
- `DS.Colors` — background surfaces for sidebar/content/detail columns
- `DS.Typography` — navigation titles, inspector headers
- `DS.Animation.medium` — transitions when toggling columns and inspector visibility
- `DS.Radius.card` — default radii for inspector panels and selection highlights

### Dependencies

- `NavigationSplitViewKit.NavigationModel` for synchronized state management across all columns
- Existing FoundationUI patterns (`SidebarPattern`, `InspectorPattern`, `ToolbarPattern`) which render inside the scaffold without reimplementing navigation rules
- Platform adaptation utilities (e.g., `PlatformAdaptation`) for size-class awareness
- Composable Clarity tokens (zero magic numbers rule)

## Behavior Specification

### Variants

- **ThreeColumn** — Sidebar + Content + Detail inspector (desktop & tablet landscape)
- **TwoColumnCompact** — Collapses inspector into content column on compact width
- **SingleColumnCompact** — Stack-style navigation for iPhone portrait
- **InspectorPinned** — Keeps inspector visible when `navigationModel.isInspectorPinned` is true

### Platform Differences

- **iOS**: Uses NavigationSplitViewKit compact behaviors with toolbar toggle for inspector visibility; supports navigation stack fallback when column visibility collapses.
- **iPadOS**: Enables column pinning and drag-to-resize gestures; honors pointer hover states for sidebar rows.
- **macOS**: Defaults to three columns with resizable split view gutters; integrates keyboard shortcuts for column focus and inspector toggling.

### Accessibility Requirements

- Column toggle controls expose VoiceOver labels ("Show Inspector", "Collapse Sidebar")
- Focus order preserved when columns appear/disappear
- Support for Reduce Motion by disabling animated column transitions
- Dynamic Type adjustments propagate through Sidebar/Inspector patterns automatically
- Full keyboard navigation parity (⌘1 Sidebar, ⌘2 Content, ⌘3 Inspector shortcuts)

## Documentation Updates

### Task Plan

- Added NavigationSplitViewKit integration tasks to Phase 3 (Patterns & Platform Adaptation)
- Updated progress counters and dependency tracking for new Layer 3 workstream

### PRD

- Added navigation scaffold requirement under Architecture → Patterns to document dependency and success metrics

### Test Plan

- Added navigation integration test coverage expectations for NavigationSplitScaffold and NavigationModel bridging across all platforms

## Next Steps

1. Add `NavigationSplitViewKit` dependency to `FoundationUI/Package.swift`, `Project.swift`, and `Package.resolved`.
2. Create `NavigationSplitScaffold` wrapper and environment key for exposing `NavigationModel` inside FoundationUI patterns.
3. Update `SidebarPattern`, `InspectorPattern`, and `ToolbarPattern` previews/tests to use the shared navigation scaffold.
4. Author unit, snapshot, and integration tests covering three/two/single-column variants across iOS, iPadOS, and macOS.
5. Document usage in DocC tutorials and agent YAML schemas for navigation-driven layouts.

## Open Questions

- Should column visibility shortcuts map to existing CommandPalette actions or remain localized to NavigationSplitViewKit defaults?
- Do we expose inspector pinning as part of the public API or rely on NavigationModel defaults?
- How will the ISOInspector demo apps surface navigation state to agents (YAML schema updates required)?

---
**Proposal Date**: 2025-11-12
**Status**: Ready for Implementation
