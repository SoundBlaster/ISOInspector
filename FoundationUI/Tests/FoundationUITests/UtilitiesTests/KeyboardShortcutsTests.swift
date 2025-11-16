// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

#if canImport(SwiftUI)
  import SwiftUI

  /// Comprehensive tests for KeyboardShortcuts utility
  ///
  /// Tests cover:
  /// - Shortcut type definitions
  /// - Platform-specific modifier abstraction
  /// - Display string formatting
  /// - Accessibility labels
  /// - View integration
  @available(iOS 17.0, macOS 14.0, *)
  @MainActor
  final class KeyboardShortcutsTests: XCTestCase {
    // MARK: - Shortcut Type Tests

    /// Test that Copy shortcut is defined correctly with platform-specific modifiers
    func testKeyboardShortcutType_Copy_DefinedCorrectly() {
      let shortcut = KeyboardShortcutType.copy
      XCTAssertEqual(shortcut.keyEquivalent, "c")
      #if os(macOS)
        XCTAssertEqual(shortcut.modifiers, .command)
      #else
        XCTAssertEqual(shortcut.modifiers, .control)
      #endif
    }

    /// Test that Paste shortcut is defined correctly with platform-specific modifiers
    func testKeyboardShortcutType_Paste_DefinedCorrectly() {
      let shortcut = KeyboardShortcutType.paste
      XCTAssertEqual(shortcut.keyEquivalent, "v")
      #if os(macOS)
        XCTAssertEqual(shortcut.modifiers, .command)
      #else
        XCTAssertEqual(shortcut.modifiers, .control)
      #endif
    }

    /// Test that Cut shortcut is defined correctly with platform-specific modifiers
    func testKeyboardShortcutType_Cut_DefinedCorrectly() {
      let shortcut = KeyboardShortcutType.cut
      XCTAssertEqual(shortcut.keyEquivalent, "x")
      #if os(macOS)
        XCTAssertEqual(shortcut.modifiers, .command)
      #else
        XCTAssertEqual(shortcut.modifiers, .control)
      #endif
    }

    /// Test that SelectAll shortcut is defined correctly
    func testKeyboardShortcutType_SelectAll_DefinedCorrectly() {
      let shortcut = KeyboardShortcutType.selectAll
      XCTAssertEqual(shortcut.keyEquivalent, "a")
      #if os(macOS)
        XCTAssertEqual(shortcut.modifiers, .command)
      #else
        XCTAssertEqual(shortcut.modifiers, .control)
      #endif
    }

    /// Test that all standard shortcuts are defined
    func testKeyboardShortcutType_AllStandardShortcuts_AreDefined() {
      // Verify all standard shortcuts exist
      let shortcuts: [KeyboardShortcutType] = [
        .copy,
        .paste,
        .cut,
        .selectAll,
        .undo,
        .redo,
        .save,
        .find,
        .newItem,
        .close,
        .refresh,
      ]

      XCTAssertEqual(shortcuts.count, 11, "All 11 standard shortcuts should be defined")
    }

    // MARK: - Platform-Specific Modifier Tests

    /// Test that Command key returns .command on macOS
    func testKeyboardShortcutModifiers_Command_macOS_ReturnsCommandKey() {
      #if os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.command, .command)
      #endif
    }

    /// Test that Command key returns .control on non-macOS platforms
    func testKeyboardShortcutModifiers_Command_NonMacOS_ReturnsControlKey() {
      #if !os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.command, .control)
      #endif
    }

    /// Test that Command+Shift combination is correct on macOS
    func testKeyboardShortcutModifiers_CommandShift_macOS_ReturnsCorrectCombination() {
      #if os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.commandShift, [.command, .shift])
      #endif
    }

    /// Test that Option key abstraction works correctly
    func testKeyboardShortcutModifiers_Option_ReturnsCorrectModifier() {
      #if os(macOS)
        XCTAssertEqual(KeyboardShortcutModifiers.option, .option)
      #else
        XCTAssertEqual(KeyboardShortcutModifiers.option, .option)
      #endif
    }

    // MARK: - Display String Tests

    /// Test that Copy shortcut displays correctly on macOS with command symbol
    func testKeyboardShortcutType_DisplayString_macOS_ReturnsSymbol() {
      #if os(macOS)
        let copy = KeyboardShortcutType.copy
        XCTAssertEqual(copy.displayString, "⌘C")
      #endif
    }

    /// Test that Copy shortcut displays correctly on non-macOS platforms
    func testKeyboardShortcutType_DisplayString_NonMacOS_ReturnsCtrlFormat() {
      #if !os(macOS)
        let copy = KeyboardShortcutType.copy
        XCTAssertTrue(copy.displayString.contains("Ctrl"))
        XCTAssertTrue(copy.displayString.contains("C"))
      #endif
    }

    /// Test that Redo shortcut displays correctly with Shift modifier
    func testKeyboardShortcutType_DisplayString_Redo_IncludesShift() {
      let redo = KeyboardShortcutType.redo
      #if os(macOS)
        XCTAssertEqual(redo.displayString, "⌘⇧Z")
      #else
        XCTAssertTrue(redo.displayString.contains("Shift"))
      #endif
    }

    // MARK: - Accessibility Tests

    /// Test that accessibility labels are provided for all shortcuts
    func testKeyboardShortcutType_AccessibilityLabel_AllShortcuts_HaveLabels() {
      let shortcuts: [KeyboardShortcutType] = [
        .copy,
        .paste,
        .cut,
        .selectAll,
      ]

      for shortcut in shortcuts {
        XCTAssertFalse(
          shortcut.accessibilityLabel.isEmpty,
          "Accessibility label should not be empty for \(shortcut)"
        )
      }
    }

    /// Test that accessibility labels are descriptive
    func testKeyboardShortcutType_AccessibilityLabel_Copy_IsDescriptive() {
      let copy = KeyboardShortcutType.copy
      let label = copy.accessibilityLabel

      #if os(macOS)
        XCTAssertTrue(label.contains("Command") || label.contains("⌘"))
      #else
        XCTAssertTrue(label.contains("Control") || label.contains("Ctrl"))
      #endif
      XCTAssertTrue(label.contains("C"))
    }

    // MARK: - Integration Test

    /// Test that shortcuts can be applied to SwiftUI views
    func testViewExtension_Shortcut_CanBeApplied() {
      struct TestView: View {
        @State private var actionTriggered = false

        var body: some View {
          Text("Test")
            .shortcut(.copy) {
              actionTriggered = true
            }
        }
      }

      // If we can compile this, the View extension is working
      let view = TestView()
      XCTAssertNotNil(view)
    }
  }

#endif
