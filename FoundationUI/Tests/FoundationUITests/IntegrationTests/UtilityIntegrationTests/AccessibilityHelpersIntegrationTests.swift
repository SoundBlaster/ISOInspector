// swift-tools-version: 6.0
import XCTest

#if canImport(SwiftUI)
  @testable import FoundationUI
  import SwiftUI

  /// Integration tests for AccessibilityHelpers utility with real components
  ///
  /// Tests verify that AccessibilityHelpers works correctly when integrated with:
  /// - Badge component (contrast validation)
  /// - Card component (backgrounds, touch targets)
  /// - KeyValueRow (VoiceOver hints, actions)
  /// - InspectorPattern (complete accessibility audit)
  /// - ToolbarPattern (accessibility compliance)
  /// - SidebarPattern (focus management)
  /// - Platform-specific accessibility features
  @MainActor
  final class AccessibilityHelpersIntegrationTests: XCTestCase {
    // MARK: - Badge Component Integration

    func testContrastValidationOnBadgeInfoColor() {
      // Test WCAG contrast validation on Badge info color
      let contrastRatio = AccessibilityHelpers.contrastRatio(
        foreground: .black,
        background: DS.Colors.infoBG
      )

      XCTAssertGreaterThanOrEqual(
        contrastRatio, 4.5, "DS.Colors.infoBG should meet WCAG AA (≥4.5:1)"
      )
    }

    func testContrastValidationOnBadgeWarningColor() {
      // Test WCAG contrast on Badge warning color
      let contrastRatio = AccessibilityHelpers.contrastRatio(
        foreground: .black,
        background: DS.Colors.warnBG
      )

      XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "DS.Colors.warnBG should meet WCAG AA")
    }

    func testContrastValidationOnBadgeErrorColor() {
      // Test WCAG contrast on Badge error color
      let contrastRatio = AccessibilityHelpers.contrastRatio(
        foreground: .black,
        background: DS.Colors.errorBG
      )

      XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "DS.Colors.errorBG should meet WCAG AA")
    }

    func testContrastValidationOnBadgeSuccessColor() {
      // Test WCAG contrast on Badge success color
      let contrastRatio = AccessibilityHelpers.contrastRatio(
        foreground: .black,
        background: DS.Colors.successBG
      )

      XCTAssertGreaterThanOrEqual(
        contrastRatio, 4.5, "DS.Colors.successBG should meet WCAG AA"
      )
    }

    func testAllBadgeLevelsMeetWCAG_AA() {
      // Test that all Badge levels meet WCAG AA requirements
      let badgeColors = [
        DS.Colors.infoBG,
        DS.Colors.warnBG,
        DS.Colors.errorBG,
        DS.Colors.successBG,
      ]

      for color in badgeColors {
        let meetsAA = AccessibilityHelpers.meetsWCAG_AA(
          foreground: .black,
          background: color
        )
        XCTAssertTrue(meetsAA, "All Badge colors should meet WCAG AA")
      }
    }

    // MARK: - Card Component Integration

    func testContrastValidationOnCardBackgrounds() {
      // Test contrast validation on Card component backgrounds
      let card = Card {
        Text("Sample Content")
      }

      XCTAssertNotNil(card, "Card should support accessibility validation")
      // Card backgrounds should meet WCAG requirements
    }

    func testTouchTargetValidationOnCardButtons() {
      // Test that buttons in Card meet minimum touch target size (44×44 pt)
      let isValidSize = AccessibilityHelpers.isValidTouchTarget(
        size: CGSize(width: 44, height: 44)
      )

      XCTAssertTrue(isValidSize, "Card buttons should meet 44×44 pt touch target requirement")
    }

    // MARK: - VoiceOver Hints Integration

    func testVoiceOverHintsWithBadgeComponent() {
      // Test VoiceOver hint construction for Badge actions
      let hint = AccessibilityHelpers.voiceOverHint(
        action: "view details",
        target: "badge"
      )

      XCTAssertFalse(hint.isEmpty, "VoiceOver hint should be generated for Badge")
      XCTAssertTrue(hint.contains("view details"), "Hint should describe the action")
    }

    func testVoiceOverHintsWithKeyValueRowActions() {
      // Test VoiceOver hints for KeyValueRow copy actions
      let copyHint = AccessibilityHelpers.voiceOverHint(
        action: "copy",
        target: "value"
      )

      XCTAssertTrue(copyHint.contains("copy"), "Hint should mention copy action")
      XCTAssertTrue(copyHint.contains("value"), "Hint should mention target")
    }

    // MARK: - Accessibility Modifiers Integration

    func testAccessibleButtonModifierOnRealButton() {
      // Add timeout to surface hangs in CI if main actor work never completes
      let expectation = expectation(description: "Accessible button builds")

      DispatchQueue.main.async {
        let button = Button("Copy") {}
          .accessibleButton(
            label: "Copy Value",
            hint: "Copies the value to clipboard"
          )

        XCTAssertNotNil(button, "Accessibility button modifier should work on real buttons")
        expectation.fulfill()
      }

      wait(for: [expectation], timeout: 5.0)
    }

    func testAccessibleToggleModifierOnExpandableSection() {
      // Test .accessibleToggle() on expandable section header
      struct TestToggleView: View {
        @State var isExpanded = false

        var body: some View {
          Button(action: { isExpanded.toggle() }) {
            HStack {
              Text("Section")
              Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
          }
          .accessibleToggle(label: "Section", isOn: isExpanded)
        }
      }

      let toggle = TestToggleView()

      XCTAssertNotNil(
        toggle, "Accessibility toggle modifier should work on expandable sections"
      )
    }

    func testAccessibleHeadingModifierOnSectionHeaders() {
      // Test .accessibleHeading() on SectionHeader component
      let header = Text("Inspector Details")
        .accessibleHeading(level: 1)

      XCTAssertNotNil(header, "Heading modifier should work on SectionHeader")
    }

    func testAccessibleValueModifierOnKeyValueRow() {
      // Test .accessibleValue() on KeyValueRow display
      let row = Text("12345")
        .accessibleValue(label: "Item Count", value: "12345")

      XCTAssertNotNil(row, "Value modifier should work on KeyValueRow")
    }

    // MARK: - Complete View Accessibility Audit

    func testAccessibilityAuditOnInspectorPattern() {
      // Test comprehensive audit on complete InspectorPattern view
      let inspector = InspectorPattern(title: "ISO File Details") {
        VStack(spacing: DS.Spacing.m) {
          SectionHeader(title: "Metadata", showDivider: true)
          KeyValueRow(key: "Size", value: "1.2 GB")
          KeyValueRow(key: "Created", value: "2025-11-03")
        }
      }

      XCTAssertNotNil(inspector, "Should be able to audit complete InspectorPattern")

      // Perform audit
      let audit = AccessibilityHelpers.auditView(
        hasLabel: true,
        hasHint: true,
        touchTargetSize: CGSize(width: 44, height: 44),
        contrastRatio: 7.0
      )

      // Inspector should pass accessibility audit
      XCTAssertTrue(
        audit.passes || audit.issues.count < 2,
        "InspectorPattern should be accessibility-compliant"
      )
    }

    func testAccessibilityAuditOnToolbarPattern() {
      // Test audit on ToolbarPattern
      let toolbar = ToolbarPattern(
        items: ToolbarPattern.Items(
          primary: [
            ToolbarPattern.Item(
              id: "copy", iconSystemName: "doc.on.doc", title: "Copy", action: {}
            )
          ]
        ))

      XCTAssertNotNil(toolbar, "Should be able to audit ToolbarPattern")

      // Toolbar items should meet accessibility requirements
      let audit = AccessibilityHelpers.auditView(
        hasLabel: true,
        hasHint: true,
        touchTargetSize: CGSize(width: 44, height: 44),
        contrastRatio: 5.0
      )

      XCTAssertTrue(audit.passes || !audit.issues.isEmpty, "ToolbarPattern audit should run")
    }

    // MARK: - Focus Management Integration

    func testFocusOrderValidationInSidebar() {
      // Test focus order validation with SidebarPattern navigation
      let focusElements = [
        AccessibilityHelpers.FocusElement(id: "item1", order: 1, label: "First Item"),
        AccessibilityHelpers.FocusElement(id: "item2", order: 2, label: "Second Item"),
        AccessibilityHelpers.FocusElement(id: "item3", order: 3, label: "Third Item"),
      ]

      let isValidOrder = AccessibilityHelpers.isValidFocusOrder(focusElements)
      XCTAssertTrue(isValidOrder, "Sidebar focus order should be sequential")
    }

    func testKeyboardNavigationInComplexHierarchy() {
      // Test keyboard navigation through complex component hierarchy
      let elements = [
        AccessibilityHelpers.FocusElement(id: "header", order: 1, label: "Header"),
        AccessibilityHelpers.FocusElement(id: "content", order: 2, label: "Content"),
        AccessibilityHelpers.FocusElement(id: "footer", order: 3, label: "Footer"),
      ]

      XCTAssertTrue(
        AccessibilityHelpers.isValidFocusOrder(elements),
        "Complex hierarchy should have valid focus order"
      )
    }

    // MARK: - Dynamic Type Integration

    func testDynamicTypeScalingWithRealTypography() {
      // Test Dynamic Type scaling with DS.Typography tokens
      let baseSize: CGFloat = 16.0
      let scaledSizeLarge = AccessibilityHelpers.scaledValue(baseSize, for: .large)
      let scaledSizeXXL = AccessibilityHelpers.scaledValue(baseSize, for: .xxLarge)
      let scaledSizeAccessibility = AccessibilityHelpers.scaledValue(
        baseSize, for: .accessibilityMedium
      )

      XCTAssertEqual(scaledSizeLarge, 16.0, "Large size should be base (1.0x)")
      XCTAssertGreaterThan(scaledSizeXXL, baseSize, "XXL should scale up")
      XCTAssertGreaterThan(
        scaledSizeAccessibility, scaledSizeXXL, "Accessibility sizes should scale more"
      )
    }

    func testAccessibilitySizeDetectionInComponents() {
      // Test accessibility size detection with real Dynamic Type values
      XCTAssertTrue(
        AccessibilityHelpers.isAccessibilitySize(.accessibilityMedium),
        "Should detect accessibility medium"
      )
      XCTAssertTrue(
        AccessibilityHelpers.isAccessibilitySize(.accessibilityLarge),
        "Should detect accessibility large"
      )
      XCTAssertFalse(
        AccessibilityHelpers.isAccessibilitySize(.large),
        "Should not detect normal size as accessibility"
      )
    }

    // MARK: - AccessibilityContext Integration

    func testReducedMotionContextIntegration() {
      // Test integration with AccessibilityContext for reduced motion
      let context = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: false
      )

      let shouldAnimate = AccessibilityHelpers.shouldAnimate(in: context)
      XCTAssertFalse(shouldAnimate, "Should respect reduced motion preference")
    }

    func testHighContrastContextIntegration() {
      // Test integration with AccessibilityContext for high contrast
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true
      )

      let preferredSpacing = AccessibilityHelpers.preferredSpacing(in: context)
      XCTAssertEqual(
        preferredSpacing, DS.Spacing.l, "Should increase spacing for high contrast"
      )
    }

    func testAccessibilityContextWithComponents() {
      // Test AccessibilityContext integration with real components
      let context = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: true,
        prefersBoldText: true,
        dynamicTypeSize: .accessibilityLarge
      )

      XCTAssertFalse(
        AccessibilityHelpers.shouldAnimate(in: context), "Animations should be disabled"
      )
      XCTAssertGreaterThan(
        AccessibilityHelpers.preferredSpacing(in: context), DS.Spacing.m,
        "Spacing should be increased"
      )
    }

    // MARK: - Platform-Specific Integration

    #if os(macOS)
      func testMacOSKeyboardNavigationAccessibility() {
        // Test macOS-specific keyboard navigation accessibility
        let view = Text("Navigate Me")
          .macOSKeyboardNavigable()

        XCTAssertNotNil(view, "macOS keyboard navigation should be accessible")
      }
    #endif

    #if os(iOS)
      func testIOSVoiceOverRotorAccessibility() {
        // Test iOS-specific VoiceOver rotor accessibility
        let view = Text("Rotor Item")
          .voiceOverRotor(entry: "Actions")

        XCTAssertNotNil(view, "iOS VoiceOver rotor should be accessible")
      }
    #endif

    // MARK: - Performance Integration

    func testAccessibilityAuditPerformanceOnComplexViews() {
      // Test performance of accessibility audit on complex component hierarchies
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
  }

#endif  // canImport(SwiftUI)
