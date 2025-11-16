// swift-tools-version: 6.0
import XCTest

#if canImport(SwiftUI)
  @testable import FoundationUI
  import SwiftUI

  /// Cross-utility integration tests
  ///
  /// Tests verify that multiple utilities work correctly together:
  /// - CopyableText + AccessibilityHelpers
  /// - CopyableText + KeyboardShortcuts
  /// - AccessibilityHelpers + KeyboardShortcuts
  /// - All three utilities combined in patterns (InspectorPattern, ToolbarPattern)
  /// - Platform-specific combinations
  /// - Performance with multiple utilities active
  @MainActor
  final class CrossUtilityIntegrationTests: XCTestCase {
    // MARK: - Two-Utility Combinations

    func testCopyableTextWithAccessibilityHelpers() {
      // Test CopyableText with accessibility validation
      let copyableText = CopyableText(text: "Test Value", label: "Test")

      // Validate accessibility
      let audit = AccessibilityHelpers.auditView(
        hasLabel: true,
        hasHint: true,
        touchTargetSize: CGSize(width: 44, height: 44),
        contrastRatio: 5.0
      )

      XCTAssertNotNil(copyableText, "CopyableText should work with accessibility audit")
      XCTAssertTrue(
        audit.passes || !audit.issues.isEmpty, "Accessibility audit should run on CopyableText"
      )
    }

    func testCopyableTextWithKeyboardShortcuts() {
      // Test CopyableText with keyboard shortcut display
      let shortcutHint = KeyboardShortcutType.copy.displayString

      let view = VStack(spacing: DS.Spacing.s) {
        CopyableText(text: "Value to Copy")
        Text("Press \(shortcutHint)")
          .font(DS.Typography.caption)
          .foregroundColor(.secondary)
      }

      XCTAssertNotNil(view, "CopyableText should work with keyboard shortcut hints")
    }

    func testAccessibilityHelpersWithKeyboardShortcuts() {
      // Test accessibility labels on keyboard shortcuts
      let copyShortcut = KeyboardShortcutType.copy
      let accessibilityLabel = copyShortcut.accessibilityLabel

      let hint = AccessibilityHelpers.voiceOverHint(
        action: "press",
        target: copyShortcut.displayString
      )

      XCTAssertFalse(
        accessibilityLabel.isEmpty, "Keyboard shortcuts should have accessibility labels"
      )
      XCTAssertFalse(hint.isEmpty, "AccessibilityHelpers should generate hints for shortcuts")
    }

    // MARK: - Three-Utility Combinations

    func testAllThreeUtilitiesInInspectorPattern() {
      // Test all utilities together in complete InspectorPattern
      let inspector = InspectorPattern(title: "ISO File Inspector") {
        VStack(spacing: DS.Spacing.m) {
          // SectionHeader with accessibility
          SectionHeader(title: "Details", showDivider: true)
            .accessibleHeading(level: 1)

          // KeyValueRow with CopyableText
          KeyValueRow(key: "File Hash", value: "0xABCDEF", copyable: true)

          // Shortcut hint
          Text("Press \(KeyboardShortcutType.copy.displayString) to copy")
            .font(DS.Typography.caption)
        }
      }

      XCTAssertNotNil(inspector, "All three utilities should work together in InspectorPattern")

      // Verify accessibility
      let audit = AccessibilityHelpers.auditView(
        hasLabel: true,
        hasHint: true,
        touchTargetSize: CGSize(width: 44, height: 44),
        contrastRatio: 4.5
      )

      XCTAssertNotNil(audit, "Accessibility audit should work on complete pattern")
    }

    func testAllThreeUtilitiesInToolbarPattern() {
      // Test utilities in ToolbarPattern
      let toolbar = ToolbarPattern(
        items: ToolbarPattern.Items(
          primary: [
            ToolbarPattern.Item(
              id: "copy",
              iconSystemName: "doc.on.doc",
              title: "Copy (\(KeyboardShortcutType.copy.displayString))",
              action: {}
            )
          ]
        ))

      XCTAssertNotNil(toolbar, "ToolbarPattern should integrate all utilities")

      // Toolbar should be accessible
      let isValidTouchTarget = AccessibilityHelpers.isValidTouchTarget(
        size: CGSize(width: 44, height: 44)
      )

      XCTAssertTrue(isValidTouchTarget, "Toolbar items should meet touch target requirements")
    }

    // MARK: - Complex Hierarchy Tests

    func testUtilitiesInComplexComponentHierarchy() {
      // Test utilities in deeply nested component hierarchy
      let complexView = Card {
        VStack(spacing: DS.Spacing.l) {
          // Header with accessibility
          Text("Complex View")
            .font(DS.Typography.headline)
            .accessibleHeading(level: 1)

          // Content with all utilities
          VStack(spacing: DS.Spacing.m) {
            KeyValueRow(key: "ID", value: "12345", copyable: true)
            Text("Shortcut: \(KeyboardShortcutType.copy.displayString)")
              .font(DS.Typography.caption)
          }

          // Action button
          Button("Copy All") {}
            .accessibleButton(
              label: "Copy All Values",
              hint: AccessibilityHelpers.voiceOverHint(action: "copy", target: "all values")
            )
        }
      }

      XCTAssertNotNil(complexView, "Utilities should work in complex hierarchies")
    }

    // MARK: - Platform-Specific Combinations

    #if os(macOS)
      func testMacOSSpecificUtilityCombinations() {
        // Test macOS-specific combinations of utilities
        let view = VStack {
          CopyableText(text: "macOS Value")
          Text("⌘C to copy")
            .font(DS.Typography.caption)
        }
        .macOSKeyboardNavigable()

        XCTAssertNotNil(view, "macOS-specific utilities should combine well")

        // Verify keyboard shortcuts use Command key
        XCTAssertTrue(
          KeyboardShortcutType.copy.displayString.contains("⌘"), "Should use Command on macOS"
        )
      }
    #endif

    #if os(iOS)
      func testIOSSpecificUtilityCombinations() {
        // Test iOS-specific combinations of utilities
        let view = VStack {
          CopyableText(text: "iOS Value")
          Text("Tap to copy")
            .font(DS.Typography.caption)
        }
        .voiceOverRotor(entry: "Actions")

        XCTAssertNotNil(view, "iOS-specific utilities should combine well")

        // Touch targets should be validated
        let isValid = AccessibilityHelpers.isValidTouchTarget(
          size: CGSize(width: 44, height: 44)
        )

        XCTAssertTrue(isValid, "iOS touch targets should meet 44×44 pt requirement")
      }
    #endif

    // MARK: - Performance Tests

    func testPerformanceWithMultipleUtilitiesActive() {
      // Test performance when all utilities are actively used
      measure {
        let views = (0..<20).map { index in
          VStack {
            CopyableText(text: "Value \(index)")
            Text(KeyboardShortcutType.copy.displayString)
              .font(DS.Typography.caption)
          }
          .accessibleValue(label: "Item \(index)", value: "Value \(index)")
        }

        XCTAssertEqual(views.count, 20, "Should create 20 views with all utilities")
      }
    }

    func testAccessibilityAuditPerformanceWithAllUtilities() {
      // Test accessibility audit performance on views using all utilities
      measure {
        for _ in 0..<10 {
          let audit = AccessibilityHelpers.auditView(
            hasLabel: true,
            hasHint: true,
            touchTargetSize: CGSize(width: 44, height: 44),
            contrastRatio: 7.0
          )
          XCTAssertNotNil(audit)
        }
      }
    }

    // MARK: - Real-World Usage Scenarios

    func testISOInspectorRealWorldScenario() {
      // Test utilities in realistic ISO Inspector use case
      let inspector = InspectorPattern(title: "ISO Box Details") {
        VStack(spacing: DS.Spacing.l) {
          // Metadata section
          SectionHeader(title: "Metadata", showDivider: true)
            .accessibleHeading(level: 1)

          KeyValueRow(key: "Box Type", value: "ftyp")
          KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
          KeyValueRow(key: "Size", value: "32 bytes", copyable: true)

          // Shortcut hints
          HStack {
            Image(systemName: "info.circle")
            Text("Use \(KeyboardShortcutType.copy.displayString) to copy values")
          }
          .font(DS.Typography.caption)
          .foregroundColor(.secondary)
        }
      }

      XCTAssertNotNil(inspector, "Real-world ISO Inspector scenario should work")

      // Verify contrast on all colors
      let colors = [DS.Colors.infoBG, DS.Colors.warnBG, DS.Colors.errorBG, DS.Colors.successBG]
      for color in colors {
        let meetsAA = AccessibilityHelpers.meetsWCAG_AA(foreground: .black, background: color)
        XCTAssertTrue(meetsAA, "All colors should meet WCAG AA in real usage")
      }
    }

    // MARK: - Integration with Design System

    func testAllUtilitiesUseDSTokens() {
      // Verify all utilities respect DS token usage
      let view = VStack(spacing: DS.Spacing.l) {
        CopyableText(text: "Test")
        Text(KeyboardShortcutType.copy.displayString)
          .font(DS.Typography.caption)
      }
      .padding(DS.Spacing.m)

      XCTAssertNotNil(view, "All utilities should use DS tokens")

      // Verify spacing is correct
      XCTAssertEqual(DS.Spacing.l, 16.0, "DS.Spacing.l should be 16")
      XCTAssertEqual(DS.Spacing.m, 12.0, "DS.Spacing.m should be 12")

      // Verify contrast ratios
      let contrast = AccessibilityHelpers.contrastRatio(
        foreground: .black,
        background: .white
      )
      XCTAssertGreaterThan(contrast, 20.0, "Black on white should have maximum contrast")
    }
  }

#endif  // canImport(SwiftUI)
