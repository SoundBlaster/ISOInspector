# Phase 4.2: Implement KeyboardShortcuts Utility

## 🎯 Objective

Create a cross-platform KeyboardShortcuts utility that provides platform-specific keyboard shortcut definitions and Command/Control key abstraction for FoundationUI components.

## 🧩 Context

- **Phase**: Phase 4.2 - Utilities & Helpers
- **Layer**: Utilities (cross-layer support)
- **Priority**: P1 (Important for quality)
- **Dependencies**:
  - ✅ Design Tokens (Layer 0) - Complete
  - ✅ Core Components (Layer 2) - Complete
  - ✅ Patterns (Layer 3) - Complete
  - ✅ Platform Adaptation (Layer 4) - Complete

## ✅ Success Criteria

### Implementation Requirements

- [ ] Create `Sources/FoundationUI/Utilities/KeyboardShortcuts.swift`
- [ ] Define platform-specific keyboard shortcut types
- [ ] Implement Command/Control key abstraction (⌘ on macOS, Ctrl on other platforms)
- [ ] Support standard shortcuts (Copy, Paste, Cut, Select All, etc.)
- [ ] SwiftUI ViewModifier integration (`.keyboardShortcut()` extension)
- [ ] Documentation for standard shortcuts with examples
- [ ] Zero magic numbers (use DS tokens where applicable)
- [ ] 100% DocC documentation for all public APIs
- [ ] Platform guards (#if os(macOS), #if os(iOS))

### Testing Requirements

- [ ] Create `Tests/FoundationUITests/UtilitiesTests/KeyboardShortcutsTests.swift`
- [ ] Unit tests for shortcut definitions (≥15 test cases)
- [ ] Test Command/Control abstraction
- [ ] Test platform-specific behavior
- [ ] Test shortcut equality and hashing
- [ ] Platform-specific test coverage
- [ ] All tests pass with `swift test`
- [ ] SwiftLint reports 0 violations

### Quality Requirements

- [ ] Zero magic numbers (100% DS token usage where applicable)
- [ ] Descriptive test names following convention
- [ ] SwiftUI Previews demonstrating usage (≥3 previews)
- [ ] Accessibility considerations documented
- [ ] Cross-platform compatibility verified

## 🔧 Implementation Plan

### Step 1: Define KeyboardShortcut Types

**File**: `Sources/FoundationUI/Utilities/KeyboardShortcuts.swift`

**Key Components**:

1. **KeyboardShortcutType Enum** - Standard shortcut definitions
   ```swift
   public enum KeyboardShortcutType {
       case copy      // ⌘C / Ctrl+C
       case paste     // ⌘V / Ctrl+V
       case cut       // ⌘X / Ctrl+X
       case selectAll // ⌘A / Ctrl+A
       case undo      // ⌘Z / Ctrl+Z
       case redo      // ⌘⇧Z / Ctrl+Y
       case save      // ⌘S / Ctrl+S
       case find      // ⌘F / Ctrl+F
       case newItem   // ⌘N / Ctrl+N
       case close     // ⌘W / Ctrl+W
       case refresh   // ⌘R / Ctrl+R
       case custom(key: KeyEquivalent, modifiers: EventModifiers)
   }
   ```

2. **KeyboardShortcutModifiers** - Platform-specific modifier keys
   ```swift
   public struct KeyboardShortcutModifiers {
       public static var command: EventModifiers {
           #if os(macOS)
           return .command
           #else
           return .control
           #endif
       }

       public static var commandShift: EventModifiers {
           #if os(macOS)
           return [.command, .shift]
           #else
           return [.control, .shift]
           #endif
       }

       public static var option: EventModifiers {
           #if os(macOS)
           return .option
           #else
           return .alt
           #endif
       }
   }
   ```

3. **KeyboardShortcut Extension** - Helper properties
   ```swift
   extension KeyboardShortcutType {
       public var keyEquivalent: KeyEquivalent { ... }
       public var modifiers: EventModifiers { ... }
       public var displayString: String { ... } // e.g., "⌘C" or "Ctrl+C"
       public var accessibilityLabel: String { ... }
   }
   ```

4. **View Extension** - Convenient shortcut application
   ```swift
   public extension View {
       func shortcut(_ type: KeyboardShortcutType, action: @escaping () -> Void) -> some View {
           // Apply keyboard shortcut with platform-specific behavior
       }
   }
   ```

### Step 2: Write Failing Tests First (TDD)

**File**: `Tests/FoundationUITests/UtilitiesTests/KeyboardShortcutsTests.swift`

**Test Categories** (≥15 tests):

1. **Shortcut Type Tests** (5 tests)
   - Test copy shortcut definition
   - Test paste shortcut definition
   - Test cut shortcut definition
   - Test custom shortcut definition
   - Test all standard shortcuts defined

2. **Platform-Specific Modifier Tests** (4 tests)
   - Test Command key on macOS returns .command
   - Test Command key on other platforms returns .control
   - Test Shift combination modifiers
   - Test Option/Alt key abstraction

3. **Display String Tests** (3 tests)
   - Test macOS display strings (⌘C, ⌘V, etc.)
   - Test non-macOS display strings (Ctrl+C, Ctrl+V, etc.)
   - Test custom shortcut display string

4. **Accessibility Tests** (2 tests)
   - Test accessibility labels for shortcuts
   - Test VoiceOver announcements

5. **Integration Tests** (1 test)
   - Test View extension shortcut application

**Example Test Structure**:

```swift
import XCTest
@testable import FoundationUI
#if canImport(SwiftUI)
import SwiftUI

final class KeyboardShortcutsTests: XCTestCase {

    // MARK: - Shortcut Type Tests

    func testKeyboardShortcutType_Copy_DefinedCorrectly() {
        let shortcut = KeyboardShortcutType.copy
        XCTAssertEqual(shortcut.keyEquivalent, "c")
        #if os(macOS)
        XCTAssertEqual(shortcut.modifiers, .command)
        #else
        XCTAssertEqual(shortcut.modifiers, .control)
        #endif
    }

    func testKeyboardShortcutType_Paste_DefinedCorrectly() {
        // Test paste shortcut
    }

    // MARK: - Platform-Specific Modifier Tests

    func testKeyboardShortcutModifiers_Command_macOS_ReturnsCommandKey() {
        #if os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.command, .command)
        #else
        // Test skipped on macOS
        #endif
    }

    func testKeyboardShortcutModifiers_Command_NonMacOS_ReturnsControlKey() {
        #if !os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.command, .control)
        #else
        // Test skipped on non-macOS
        #endif
    }

    // MARK: - Display String Tests

    func testKeyboardShortcutType_DisplayString_macOS_ReturnsSymbol() {
        #if os(macOS)
        let copy = KeyboardShortcutType.copy
        XCTAssertEqual(copy.displayString, "⌘C")
        #endif
    }

    func testKeyboardShortcutType_DisplayString_NonMacOS_ReturnsCtrlFormat() {
        #if !os(macOS)
        let copy = KeyboardShortcutType.copy
        XCTAssertTrue(copy.displayString.contains("Ctrl"))
        #endif
    }

    // ... (more tests)
}
#endif
```

### Step 3: Implement Minimal Code to Pass Tests

1. Create `KeyboardShortcuts.swift` with basic structure
2. Implement `KeyboardShortcutType` enum
3. Implement `KeyboardShortcutModifiers` struct
4. Implement extensions and helpers
5. Run `swift test` until all tests pass

### Step 4: Add SwiftUI Previews

**Previews** (≥3):

1. **Standard Shortcuts Preview** - Showcase copy/paste/cut
2. **Platform-Specific Preview** - Show Command vs Control
3. **Custom Shortcuts Preview** - Demonstrate custom shortcut usage

```swift
#Preview("Standard Shortcuts") {
    VStack(spacing: DS.Spacing.l) {
        Button("Copy (⌘C)") { }
            .shortcut(.copy) { print("Copy triggered") }
        Button("Paste (⌘V)") { }
            .shortcut(.paste) { print("Paste triggered") }
        Button("Cut (⌘X)") { }
            .shortcut(.cut) { print("Cut triggered") }
    }
    .padding(DS.Spacing.xl)
}
```

### Step 5: Add DocC Documentation

- Document all public types with `///` comments
- Include usage examples
- Document platform-specific behavior
- Add code snippets for common use cases

## 🧠 Design Token Usage

Use DS tokens where applicable:

- **Spacing**: Use `DS.Spacing.*` for layout in previews
- **Typography**: Use `DS.Typography.*` for text in previews
- **Colors**: Use `DS.Colors.*` for visual feedback in previews

**Note**: Keyboard shortcuts themselves don't typically use design tokens, but preview implementations should follow DS guidelines.

## 🔗 Source References

### FoundationUI Documents

- [FoundationUI Task Plan § Phase 4.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#42-utilities--helpers)
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [Platform Extensions](../../../FoundationUI/Sources/FoundationUI/Contexts/PlatformExtensions.swift) - Reference for platform-specific code

### Apple Documentation

- [SwiftUI KeyboardShortcut](https://developer.apple.com/documentation/swiftui/keyboardshortcut)
- [EventModifiers](https://developer.apple.com/documentation/swiftui/eventmodifiers)
- [KeyEquivalent](https://developer.apple.com/documentation/swiftui/keyequivalent)

### Development Rules

- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md) - Outside-in TDD
- [07_AI_Code_Structure_Principles.md](../../../DOCS/RULES/07_AI_Code_Structure_Principles.md) - One entity per file
- [11_SwiftUI_Testing.md](../../../DOCS/RULES/11_SwiftUI_Testing.md) - SwiftUI testing guidelines

## 📋 Execution Checklist

### Phase 1: Test-Driven Development

- [ ] Create `KeyboardShortcutsTests.swift` test file
- [ ] Write failing tests for all shortcut types (5 tests)
- [ ] Write failing tests for platform modifiers (4 tests)
- [ ] Write failing tests for display strings (3 tests)
- [ ] Write failing tests for accessibility (2 tests)
- [ ] Write failing integration test (1 test)
- [ ] Run `swift test` to confirm failures

### Phase 2: Implementation

- [ ] Create `KeyboardShortcuts.swift` file
- [ ] Implement `KeyboardShortcutType` enum
- [ ] Implement `KeyboardShortcutModifiers` struct
- [ ] Implement extensions (keyEquivalent, modifiers, displayString)
- [ ] Implement View extension for shortcut application
- [ ] Run `swift test` iteratively until all tests pass

### Phase 3: Documentation & Previews

- [ ] Add DocC comments to all public APIs
- [ ] Create 3+ SwiftUI Previews
- [ ] Document platform-specific behavior
- [ ] Add usage examples in documentation
- [ ] Verify previews render correctly

### Phase 4: Quality Assurance

- [ ] Run `swift test` - all tests pass
- [ ] Run `swiftlint --strict` - 0 violations
- [ ] Verify zero magic numbers
- [ ] Check 100% DocC coverage
- [ ] Test on macOS (if available)
- [ ] Test on iOS simulator (if available)

### Phase 5: Finalization

- [ ] Update Task Plan with [x] completion mark
- [ ] Create task archive document
- [ ] Move to `TASK_ARCHIVE/` folder
- [ ] Commit changes with descriptive message
- [ ] Update `next_tasks.md` with next priority

## 📈 Expected Outcomes

### Files Created

1. `Sources/FoundationUI/Utilities/KeyboardShortcuts.swift` (~250-300 lines)
2. `Tests/FoundationUITests/UtilitiesTests/KeyboardShortcutsTests.swift` (~400-500 lines)

### Test Coverage

- **Minimum**: ≥15 unit tests
- **Coverage**: ≥85% for KeyboardShortcuts utility

### Quality Metrics

- ✅ 100% public API coverage
- ✅ Zero magic numbers
- ✅ 100% DocC documentation
- ✅ SwiftLint compliance (0 violations)
- ✅ ≥3 SwiftUI Previews
- ✅ Cross-platform compatibility

## 🚧 Known Challenges & Mitigations

### Challenge 1: Platform-Specific Compilation

**Issue**: Different keyboard shortcut behavior on macOS vs iOS/iPadOS
**Mitigation**: Use `#if os(macOS)` conditional compilation extensively

### Challenge 2: Testing Without UI Runtime

**Issue**: Keyboard shortcuts require SwiftUI runtime to test fully
**Mitigation**: Focus on testing data structures and logic; integration tests for full behavior

### Challenge 3: Hardware Keyboard on iOS

**Issue**: iOS keyboard shortcuts only work with hardware keyboards
**Mitigation**: Document this limitation clearly in DocC

## 🎯 Success Definition

This task is **COMPLETE** when:

1. ✅ KeyboardShortcuts.swift implemented with all features
2. ✅ KeyboardShortcutsTests.swift with ≥15 tests - all passing
3. ✅ SwiftLint reports 0 violations
4. ✅ 100% DocC documentation
5. ✅ ≥3 SwiftUI Previews created
6. ✅ All success criteria checklist items marked [x]
7. ✅ Task archived with completion report
8. ✅ Task Plan updated with [x] completion mark

---

**Estimated Effort**: 4-6 hours (Medium task)
**Assigned**: TBD
**Status**: 🚧 IN PROGRESS
**Started**: 2025-11-03
**Target Completion**: TBD

---

## 📝 Progress Notes

### 2025-11-03: Task Created

- Task selected using SELECT_NEXT.md algorithm
- All prerequisites verified (Utilities directory, test infrastructure, Package.swift, SwiftLint)
- Ready to begin TDD implementation
- Dependencies: All Phase 2-3 components complete

---

*Last Updated: 2025-11-03*
