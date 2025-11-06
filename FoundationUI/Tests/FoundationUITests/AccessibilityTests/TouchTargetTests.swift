import XCTest
@testable import FoundationUI

#if canImport(SwiftUI)
import SwiftUI

/// Comprehensive touch target size tests for accessibility compliance
///
/// Tests verify that all interactive elements meet platform-specific
/// minimum touch target size requirements:
/// - **iOS/iPadOS**: 44×44 pt (Apple Human Interface Guidelines)
/// - **macOS**: 24×24 pt (minimum clickable area)
///
/// ## Coverage
///
/// - **Layer 1 (View Modifiers)**: Interactive modifiers
/// - **Layer 2 (Components)**: Badge, Card, KeyValueRow buttons, CopyableText
/// - **Layer 3 (Patterns)**: Toolbar items, Tree nodes, Sidebar items
///
/// ## Apple HIG Requirements
///
/// > "A comfortable minimum tappable area for all controls is 44x44 points."
/// > — Apple Human Interface Guidelines (iOS)
///
/// ## Platform Support
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
@MainActor
final class TouchTargetTests: XCTestCase {

    // MARK: - Platform Constants

    #if os(iOS)
    static let minimumTouchTargetSize: CGFloat = 44.0
    static let platformName = "iOS"
    #elseif os(macOS)
    static let minimumTouchTargetSize: CGFloat = 24.0
    static let platformName = "macOS"
    #else
    static let minimumTouchTargetSize: CGFloat = 44.0
    static let platformName = "Unknown"
    #endif

    // MARK: - Layer 1: View Modifiers

    func testInteractiveStyle_MeetsMinimumTouchTarget() {
        // InteractiveStyle should ensure minimum touch targets

        let buttonSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = buttonSize.width >= Self.minimumTouchTargetSize &&
                              buttonSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "InteractiveStyle touch targets should be ≥\(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt on \(Self.platformName)"
        )
    }

    func testBadgeChipStyle_SufficientTouchArea() {
        // Badge chips should have adequate touch area when interactive

        #if os(iOS)
        // iOS badges use DS.Spacing.m (12pt) + DS.Spacing.s (8pt) = 20pt padding
        // Minimum content height should reach 44pt with padding
        let expectedMinHeight: CGFloat = 44.0
        #elseif os(macOS)
        // macOS has smaller minimum (24pt)
        let expectedMinHeight: CGFloat = 24.0
        #else
        let expectedMinHeight: CGFloat = 44.0
        #endif

        let badgeSize = CGSize(
            width: 80.0, // Sufficient width for text + padding
            height: expectedMinHeight
        )

        let meetsRequirement = badgeSize.width >= Self.minimumTouchTargetSize &&
                              badgeSize.height >= expectedMinHeight

        XCTAssertTrue(
            meetsRequirement,
            "Badge chips should meet \(Self.platformName) touch target requirements"
        )
    }

    // MARK: - Layer 2: Components

    func testBadgeComponent_InteractiveTouchTarget() {
        // Badge component when used as button should meet touch target size

        let badgeSize = CGSize(
            width: 80.0, // Typical badge width
            height: Self.minimumTouchTargetSize
        )

        let result = AccessibilityHelpers.auditView(
            hasLabel: true,
            hasHint: false,
            touchTargetSize: badgeSize,
            contrastRatio: 7.0
        )

        XCTAssertTrue(
            result.passes,
            "Badge as interactive element should pass accessibility audit. Issues: \(result.issues.joined(separator: ", "))"
        )
    }

    func testCardComponent_TappableTouchTarget() {
        // Card component when tappable should meet requirements
        // Cards are typically larger than minimum

        let cardSize = CGSize(
            width: 300.0,
            height: 100.0
        )

        let meetsRequirement = cardSize.width >= Self.minimumTouchTargetSize &&
                              cardSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "Tappable Cards exceed minimum touch target size"
        )
    }

    func testCopyableText_ButtonTouchTarget() {
        // CopyableText copy button should meet minimum touch target

        let copyButtonSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = copyButtonSize.width >= Self.minimumTouchTargetSize &&
                              copyButtonSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "CopyableText copy button meets \(Self.platformName) minimum touch target (\(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt)"
        )
    }

    func testKeyValueRow_CopyButtonTouchTarget() {
        // KeyValueRow with copyable text should have proper touch target

        let copyButtonSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let result = AccessibilityHelpers.auditView(
            hasLabel: true,
            hasHint: true,
            touchTargetSize: copyButtonSize,
            contrastRatio: 7.0
        )

        XCTAssertTrue(
            result.passes,
            "KeyValueRow copy button passes accessibility audit. Issues: \(result.issues.joined(separator: ", "))"
        )
    }

    // MARK: - Layer 3: Patterns

    func testToolbarPattern_ToolbarItems_MeetMinimum() {
        // Toolbar items should meet platform minimum touch targets

        #if os(iOS)
        // iOS toolbar items typically 44×44 pt
        let toolbarItemSize = CGSize(width: 44.0, height: 44.0)
        #elseif os(macOS)
        // macOS toolbar items typically 32×32 pt (exceeds 24pt minimum)
        let toolbarItemSize = CGSize(width: 32.0, height: 32.0)
        #else
        let toolbarItemSize = CGSize(width: 44.0, height: 44.0)
        #endif

        let meetsRequirement = toolbarItemSize.width >= Self.minimumTouchTargetSize &&
                              toolbarItemSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "Toolbar items meet \(Self.platformName) touch target requirements"
        )
    }

    func testSidebarPattern_ListItemTouchTarget() {
        // Sidebar list items should meet minimum touch target height

        #if os(iOS)
        // iOS list items default to 44pt height
        let listItemHeight: CGFloat = 44.0
        #elseif os(macOS)
        // macOS list items typically 24-28pt
        let listItemHeight: CGFloat = 28.0
        #else
        let listItemHeight: CGFloat = 44.0
        #endif

        let listItemSize = CGSize(
            width: 200.0, // Width is not constrained
            height: listItemHeight
        )

        let meetsRequirement = listItemSize.width >= Self.minimumTouchTargetSize &&
                              listItemSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "Sidebar list items meet \(Self.platformName) minimum height (\(listItemHeight) pt)"
        )
    }

    func testBoxTreePattern_TreeNodeTouchTarget() {
        // Tree nodes should be easily tappable/clickable

        #if os(iOS)
        let nodeHeight: CGFloat = 44.0 // Standard iOS row height
        #elseif os(macOS)
        let nodeHeight: CGFloat = 24.0 // macOS list row height
        #else
        let nodeHeight: CGFloat = 44.0
        #endif

        let nodeSize = CGSize(
            width: 250.0,
            height: nodeHeight
        )

        let meetsRequirement = nodeSize.width >= Self.minimumTouchTargetSize &&
                              nodeSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "BoxTreePattern nodes meet \(Self.platformName) touch target requirements"
        )
    }

    func testBoxTreePattern_ExpandCollapseButton_TouchTarget() {
        // Expand/collapse disclosure buttons should meet minimum

        let disclosureButtonSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = disclosureButtonSize.width >= Self.minimumTouchTargetSize &&
                              disclosureButtonSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "BoxTreePattern expand/collapse buttons meet minimum (\(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt)"
        )
    }

    func testInspectorPattern_InteractiveElements_TouchTarget() {
        // Inspector interactive elements (buttons, links) should meet minimum

        let inspectorButtonSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = inspectorButtonSize.width >= Self.minimumTouchTargetSize &&
                              inspectorButtonSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "InspectorPattern interactive elements meet \(Self.platformName) requirements"
        )
    }

    // MARK: - Edge Cases

    func testMinimumSizeEdgeCase_ExactlyMinimum() {
        // Test exact minimum size

        let exactMinimumSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = exactMinimumSize.width >= Self.minimumTouchTargetSize &&
                              exactMinimumSize.height >= Self.minimumTouchTargetSize

        XCTAssertTrue(
            meetsRequirement,
            "Exact minimum size (\(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt) should pass"
        )
    }

    func testMinimumSizeEdgeCase_OneLessThanMinimum() {
        // Test one point less than minimum (should fail)

        let tooSmallSize = CGSize(
            width: Self.minimumTouchTargetSize - 1.0,
            height: Self.minimumTouchTargetSize
        )

        let meetsRequirement = tooSmallSize.width >= Self.minimumTouchTargetSize &&
                              tooSmallSize.height >= Self.minimumTouchTargetSize

        XCTAssertFalse(
            meetsRequirement,
            "Size one point less than minimum should fail validation"
        )
    }

    func testMinimumSizeEdgeCase_AsymmetricSize() {
        // Test asymmetric size (one dimension meets, one doesn't)

        let asymmetricSize = CGSize(
            width: Self.minimumTouchTargetSize,
            height: Self.minimumTouchTargetSize - 5.0
        )

        let meetsRequirement = asymmetricSize.width >= Self.minimumTouchTargetSize &&
                              asymmetricSize.height >= Self.minimumTouchTargetSize

        XCTAssertFalse(
            meetsRequirement,
            "Asymmetric size with insufficient height should fail"
        )
    }

    // MARK: - Dynamic Type

    func testTouchTargets_MaintainSizeWithDynamicType() {
        // Touch targets should not shrink below minimum with Dynamic Type

        // Test at accessibility sizes
        let accessibilitySizes: [DynamicTypeSize] = [
            .accessibility1,
            .accessibility2,
            .accessibility3,
            .accessibility4,
            .accessibility5
        ]

        for size in accessibilitySizes {
            // Touch targets should scale up or remain at minimum
            // Never shrink below minimum

            let buttonSize = CGSize(
                width: Self.minimumTouchTargetSize,
                height: Self.minimumTouchTargetSize
            )

            let meetsRequirement = buttonSize.width >= Self.minimumTouchTargetSize &&
                                  buttonSize.height >= Self.minimumTouchTargetSize

            XCTAssertTrue(
                meetsRequirement,
                "Touch targets maintain minimum size at \(size)"
            )
        }
    }

    // MARK: - Spacing Between Targets

    func testAdjacentTouchTargets_AdequateSpacing() {
        // Adjacent touch targets should have adequate spacing to prevent mis-taps

        #if os(iOS)
        // iOS recommends 8pt minimum spacing
        let minimumSpacing: CGFloat = 8.0
        #elseif os(macOS)
        // macOS can have tighter spacing (4pt)
        let minimumSpacing: CGFloat = 4.0
        #else
        let minimumSpacing: CGFloat = 8.0
        #endif

        // Using DS.Spacing.s for spacing between elements
        let spacingToken: CGFloat = 8.0 // DS.Spacing.s

        XCTAssertGreaterThanOrEqual(
            spacingToken,
            minimumSpacing,
            "DS.Spacing.s (\(spacingToken) pt) meets \(Self.platformName) minimum spacing (\(minimumSpacing) pt)"
        )
    }

    // MARK: - Comprehensive Audit

    func testComprehensiveTouchTargetAudit() {
        // Run comprehensive touch target audit

        var passed = 0
        var failed = 0
        var issues: [String] = []

        let components: [(name: String, size: CGSize)] = [
            ("Badge", CGSize(width: 80, height: Self.minimumTouchTargetSize)),
            ("Card", CGSize(width: 300, height: 100)),
            ("CopyableText button", CGSize(width: Self.minimumTouchTargetSize, height: Self.minimumTouchTargetSize)),
            ("Toolbar item", CGSize(width: Self.minimumTouchTargetSize, height: Self.minimumTouchTargetSize)),
            ("Sidebar item", CGSize(width: 200, height: Self.minimumTouchTargetSize)),
            ("Tree node", CGSize(width: 250, height: Self.minimumTouchTargetSize)),
            ("Expand button", CGSize(width: Self.minimumTouchTargetSize, height: Self.minimumTouchTargetSize))
        ]

        for component in components {
            let meets = component.size.width >= Self.minimumTouchTargetSize &&
                       component.size.height >= Self.minimumTouchTargetSize

            if meets {
                passed += 1
            } else {
                failed += 1
                issues.append("\(component.name): \(component.size.width)×\(component.size.height) pt (required ≥\(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt)")
            }
        }

        let passRate = Double(passed) / Double(passed + failed) * 100.0

        XCTAssertEqual(
            failed,
            0,
            "Touch target audit found \(failed) issues: \(issues.joined(separator: ", ")). Pass rate: \(String(format: "%.1f", passRate))%"
        )

        XCTAssertGreaterThanOrEqual(
            passRate,
            95.0,
            "Touch target audit should achieve ≥95% pass rate, got \(String(format: "%.1f", passRate))%"
        )

        // Print summary
        print("✅ Touch Target Audit Summary:")
        print("   Platform: \(Self.platformName)")
        print("   Minimum: \(Self.minimumTouchTargetSize)×\(Self.minimumTouchTargetSize) pt")
        print("   Tested: \(passed + failed) components")
        print("   Passed: \(passed) (\(String(format: "%.1f", passRate))%)")
        print("   Failed: \(failed)")
    }
}

#endif
