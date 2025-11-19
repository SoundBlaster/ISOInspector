# Task 242: Update Existing Patterns for NavigationSplitScaffold

**Phase**: 3.1 (Patterns & Platform Adaptation)
**Priority**: P0 (Critical for cross-platform navigation)
**Status**: Ready for Implementation (Tasks 240 + 241 Complete)
**Created**: 2025-11-18
**Dependencies**: Task 240 ✅, Task 241 ✅

---

## 🎯 Objective

Update existing FoundationUI patterns (`SidebarPattern`, `InspectorPattern`, `ToolbarPattern`) to integrate with the new `NavigationSplitScaffold` pattern, ensuring seamless composition, accessibility, and cross-platform navigation support.

---

## 🧩 Context

**Completed Prerequisites**:
- ✅ **Task 240**: NavigationSplitViewKit dependency integrated into FoundationUI
- ✅ **Task 241**: NavigationSplitScaffold pattern implemented with environment keys and 35+ tests

**Current State**:
- Existing patterns (SidebarPattern, InspectorPattern, ToolbarPattern) were designed before NavigationSplitScaffold
- These patterns have their own navigation and layout logic
- They don't yet consume the `NavigationModel` from environment
- Preview and test files don't demonstrate NavigationSplitScaffold composition

**Goal**:
Make existing patterns NavigationSplitScaffold-aware while maintaining backward compatibility. Patterns should:
1. Access `NavigationModel` from environment when available
2. Provide enhanced functionality when used inside NavigationSplitScaffold
3. Continue to work standalone (outside scaffold) with graceful degradation
4. Demonstrate scaffold composition in previews and tests

---

## ✅ Success Criteria

### 1. SidebarPattern Updates

**File**: `FoundationUI/Sources/FoundationUI/Patterns/SidebarPattern.swift`

- [ ] Add `@Environment(\.navigationModel)` property wrapper
- [ ] When `navigationModel` is available:
  - [ ] Use `navigationModel.columnVisibility` to detect sidebar visibility state
  - [ ] Provide optional callback for sidebar toggle actions
  - [ ] Expose accessibility label for "Toggle Sidebar" action
- [ ] When `navigationModel` is nil:
  - [ ] Pattern works as before (backward compatible)
  - [ ] No runtime errors or warnings
- [ ] Update DocC documentation with NavigationSplitScaffold integration examples
- [ ] Add 3+ unit tests for environment integration
- [ ] Update SwiftUI previews to show both standalone and scaffold modes

### 2. InspectorPattern Updates

**File**: `FoundationUI/Sources/FoundationUI/Patterns/InspectorPattern.swift`

- [ ] Add `@Environment(\.navigationModel)` property wrapper
- [ ] When `navigationModel` is available:
  - [ ] React to inspector column visibility changes
  - [ ] Support inspector pinning state from NavigationModel
  - [ ] Provide accessibility labels for inspector toggle
- [ ] When `navigationModel` is nil:
  - [ ] Pattern continues to work standalone
  - [ ] Uses internal state for visibility/pinning
- [ ] Update DocC documentation with scaffold integration
- [ ] Add 3+ unit tests for navigation model integration
- [ ] Update previews with NavigationSplitScaffold composition examples

### 3. ToolbarPattern Updates

**File**: `FoundationUI/Sources/FoundationUI/Patterns/ToolbarPattern.swift`

- [ ] Add `@Environment(\.navigationModel)` property wrapper
- [ ] When `navigationModel` is available:
  - [ ] Provide toolbar items for column visibility toggles
  - [ ] Add keyboard shortcuts (⌘⌃S for sidebar, ⌘⌥I for inspector)
  - [ ] Expose VoiceOver labels for navigation controls
- [ ] When `navigationModel` is nil:
  - [ ] Toolbar items gracefully hidden or disabled
  - [ ] Pattern continues to work without navigation controls
- [ ] Update DocC documentation
- [ ] Add 3+ unit tests for toolbar-navigation integration
- [ ] Update previews showing scaffold + toolbar composition

### 4. Integration Tests

**New File**: `FoundationUI/Tests/FoundationUITests/IntegrationTests/NavigationScaffoldIntegrationTests.swift`

Create comprehensive integration tests (6+ tests) covering:

- [ ] NavigationSplitScaffold + SidebarPattern composition
- [ ] NavigationSplitScaffold + InspectorPattern composition
- [ ] NavigationSplitScaffold + ToolbarPattern composition
- [ ] Full three-pattern composition (Sidebar + Toolbar + Inspector + Scaffold)
- [ ] NavigationModel synchronization across patterns
- [ ] Column visibility state propagation
- [ ] Accessibility label verification across integrated patterns
- [ ] Platform-specific behavior (compact vs regular size classes)

### 5. Agent YAML Schema Updates

**Files**: `FoundationUI/Sources/FoundationUI/AgentSupport/*.yaml`

- [ ] Add `navigationScaffold` component type to ComponentSchema.yaml
- [ ] Define properties for column visibility binding
- [ ] Add navigation-aware variants to existing patterns
- [ ] Update examples to show scaffold + pattern composition
- [ ] Document navigation model environment access

### 6. Documentation Updates

- [ ] Update FoundationUI README.md with NavigationSplitScaffold section
- [ ] Add architecture diagram showing pattern composition layers
- [ ] Create "Migration Guide" for updating custom patterns
- [ ] Document backward compatibility approach
- [ ] Add "Best Practices" section for pattern + scaffold integration

---

## 🔧 Implementation Notes

### Phase 1: SidebarPattern Integration (0.5 days)

1. **Environment Access**:
```swift
@Environment(\.navigationModel) private var navigationModel

var isInScaffold: Bool {
    navigationModel != nil
}

var sidebarIsVisible: Bool {
    navigationModel?.columnVisibility == .all ||
    navigationModel?.columnVisibility == .automatic
}
```

2. **Backward Compatibility**:
```swift
// Internal state used when outside scaffold
@State private var internalVisibility: Bool = true

var effectiveVisibility: Bool {
    if let model = navigationModel {
        return model.columnVisibility != .contentOnly
    }
    return internalVisibility
}
```

3. **Accessibility Integration**:
```swift
.accessibilityLabel(isInScaffold ? "File Browser in Navigation" : "File Browser")
.accessibilityHint(isInScaffold ? "Part of navigation split view" : nil)
```

### Phase 2: InspectorPattern Integration (0.5 days)

1. **Inspector Visibility Binding**:
```swift
var inspectorVisible: Bool {
    if let model = navigationModel {
        return model.columnVisibility == .all
    }
    return internalInspectorVisible
}
```

2. **Pinning Support**:
```swift
// React to NavigationModel pinning state if available
// Fall back to internal state otherwise
```

### Phase 3: ToolbarPattern Integration (0.5 days)

1. **Conditional Toolbar Items**:
```swift
ToolbarItemGroup(placement: .navigation) {
    if let model = navigationModel {
        Button(action: { toggleSidebar(model) }) {
            Label("Toggle Sidebar", systemImage: "sidebar.left")
        }
        .keyboardShortcut("s", modifiers: [.command, .control])
    }
}
```

2. **Inspector Toggle**:
```swift
ToolbarItemGroup(placement: .primaryAction) {
    if let model = navigationModel {
        Button(action: { toggleInspector(model) }) {
            Label("Toggle Inspector", systemImage: "sidebar.right")
        }
        .keyboardShortcut("i", modifiers: [.command, .option])
    }
}
```

### Phase 4: Integration Testing (0.5 days)

**Test Structure**:
```swift
final class NavigationScaffoldIntegrationTests: XCTestCase {
    @MainActor
    func testScaffoldWithSidebarPattern() {
        let model = NavigationModel()

        let scaffold = NavigationSplitScaffold(model: model) {
            SidebarPattern(sections: testSections, selection: .constant(nil)) { _ in
                Text("Detail")
            }
        } content: {
            Text("Content")
        } detail: {
            Text("Detail")
        }

        // Verify SidebarPattern receives navigation model
        // Verify visibility state synchronization
    }

    @MainActor
    func testFullPatternComposition() {
        // Test NavigationSplitScaffold + Sidebar + Inspector + Toolbar
    }
}
```

---

## 📋 Testing Strategy

### Unit Tests (9+ tests)
- **SidebarPattern** (3 tests):
  - Environment model access
  - Backward compatibility without model
  - Visibility state synchronization

- **InspectorPattern** (3 tests):
  - Environment model access
  - Inspector visibility binding
  - Pinning state coordination

- **ToolbarPattern** (3 tests):
  - Conditional toolbar items
  - Keyboard shortcuts
  - Accessibility labels

### Integration Tests (6+ tests)
- Scaffold + SidebarPattern composition
- Scaffold + InspectorPattern composition
- Scaffold + ToolbarPattern composition
- Full three-pattern composition
- NavigationModel synchronization
- Platform-specific behavior verification

### Snapshot Tests
- Update existing pattern snapshot tests to include scaffold variants
- Verify visual consistency across platforms

---

## 🧠 Source References

- **Task 240 Summary**: `DOCS/INPROGRESS/Summary_of_Work_Task_240.md`
- **Task 241 Summary**: `DOCS/INPROGRESS/Summary_of_Work_Task_241.md`
- **NavigationSplitScaffold**: `FoundationUI/Sources/FoundationUI/Patterns/NavigationSplitScaffold.swift`
- **Usage Guidelines**: `DOCS/AI/ISOViewer/NavigationSplitView_Guidelines.md`
- **Master PRD**: `DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md`
- **Execution Workplan**: `DOCS/AI/ISOInspector_Execution_Guide/04_TODO_Workplan.md`
- **TDD Workflow**: `DOCS/RULES/02_TDD_XP_Workflow.md`
- **PDD Methodology**: `DOCS/RULES/04_PDD.md`

---

## 🔍 Implementation Approach

### Backward Compatibility Strategy

**Key Principle**: Patterns must work both inside and outside NavigationSplitScaffold.

**Detection Pattern**:
```swift
@Environment(\.navigationModel) private var navigationModel

var isInScaffold: Bool { navigationModel != nil }
```

**Dual-Mode Logic**:
```swift
// When in scaffold: use NavigationModel
if let model = navigationModel {
    return model.columnVisibility == .all
}
// When standalone: use internal state
return internalState
```

### Accessibility Enhancement

When patterns are used inside NavigationSplitScaffold:
- Expose column toggle actions
- Provide keyboard shortcuts
- Add VoiceOver labels that indicate scaffold context
- Ensure focus management across columns

When patterns are standalone:
- Standard accessibility labels
- No navigation-specific hints
- Self-contained focus management

### Testing Approach (TDD)

1. **Write failing tests first**:
   - Test environment model access
   - Test dual-mode behavior (scaffold vs standalone)
   - Test integration scenarios

2. **Implement minimal code to pass tests**

3. **Refactor for clarity**:
   - Extract dual-mode logic into computed properties
   - Ensure all constants use DS tokens

4. **Verify with integration tests**

---

## ⚡ Effort Estimate

- **SidebarPattern Updates**: 0.5 days
- **InspectorPattern Updates**: 0.5 days
- **ToolbarPattern Updates**: 0.5 days
- **Integration Tests**: 0.5 days
- **YAML Schema Updates**: 0.25 days
- **Documentation**: 0.25 days

**Total**: ~2.5 days (slightly over original estimate due to comprehensive testing)

---

## 🎨 Preview Examples

### Before (Standalone Pattern)
```swift
#Preview {
    SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
        Text("Detail")
    }
}
```

### After (Scaffold Integration)
```swift
#Preview("With NavigationSplitScaffold") {
    NavigationSplitScaffold {
        SidebarPattern(sections: sections, selection: $selection) { _ in
            Text("Detail")
        }
    } content: {
        ParseTreeView()
    } detail: {
        InspectorPattern(content: atomDetails)
    }
}

#Preview("Standalone Mode") {
    SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
        Text("Detail")
    }
}
```

---

## 🔗 Related Tasks

- **Predecessor**: Task 240 (NavigationSplitViewKit Integration) ✅
- **Predecessor**: Task 241 (NavigationSplitScaffold Pattern) ✅
- **Follow-up**: Task 243+ (ISOInspectorApp integration with NavigationSplitScaffold)

---

## ✅ Acceptance Checklist

Before marking this task complete:

- [ ] All three patterns (Sidebar, Inspector, Toolbar) updated
- [ ] 9+ unit tests added and passing
- [ ] 6+ integration tests added and passing
- [ ] Backward compatibility verified (patterns work standalone)
- [ ] All SwiftUI previews updated with scaffold examples
- [ ] Agent YAML schemas updated
- [ ] Documentation updated (README, migration guide)
- [ ] Zero SwiftLint violations in modified files
- [ ] All existing tests still pass
- [ ] CI builds successfully
- [ ] DocC documentation builds without warnings

---

**Last Updated**: 2025-11-18
**Assigned To**: Claude Agent
**Status**: Ready for Implementation
