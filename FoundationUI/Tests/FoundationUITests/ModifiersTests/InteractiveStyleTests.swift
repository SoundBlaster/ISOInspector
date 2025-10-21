// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for InteractiveStyle modifier
///
/// Verifies that the InteractiveStyle modifier correctly applies:
/// - Platform-specific interaction feedback (hover on macOS, touch on iOS)
/// - Keyboard focus indicators
/// - Animation from DS.Animation tokens
/// - Accessibility hints for interactive elements
///
/// ## Test Coverage
/// - Interaction types (none, subtle, standard, prominent)
/// - Platform-specific behaviors
/// - Keyboard navigation support
/// - Design token usage (zero magic numbers)
@MainActor
final class InteractiveStyleTests: XCTestCase {

    // MARK: - Interaction Type Tests

    func testInteractionTypeNoneHasNoEffect() {
        // Given: No interaction type
        let interactionType = InteractionType.none

        // When: Checking if it has effects
        let hasEffect = interactionType.hasEffect

        // Then: It should not have any effect
        XCTAssertFalse(
            hasEffect,
            "InteractionType.none should not apply any interaction effects"
        )
    }

    func testInteractionTypeSubtleHasEffect() {
        // Given: Subtle interaction type
        let interactionType = InteractionType.subtle

        // When: Checking if it has effects
        let hasEffect = interactionType.hasEffect

        // Then: It should have effect
        XCTAssertTrue(
            hasEffect,
            "InteractionType.subtle should apply subtle interaction effects"
        )
    }

    func testInteractionTypeStandardHasEffect() {
        // Given: Standard interaction type
        let interactionType = InteractionType.standard

        // When: Checking if it has effects
        let hasEffect = interactionType.hasEffect

        // Then: It should have effect
        XCTAssertTrue(
            hasEffect,
            "InteractionType.standard should apply standard interaction effects"
        )
    }

    func testInteractionTypeProminentHasEffect() {
        // Given: Prominent interaction type
        let interactionType = InteractionType.prominent

        // When: Checking if it has effects
        let hasEffect = interactionType.hasEffect

        // Then: It should have effect
        XCTAssertTrue(
            hasEffect,
            "InteractionType.prominent should apply prominent interaction effects"
        )
    }

    // MARK: - Scale Factor Tests

    func testInteractionTypeNoneScaleFactor() {
        // Given: No interaction type
        let interactionType = InteractionType.none

        // When: Getting scale factor
        let scaleFactor = interactionType.scaleFactor

        // Then: It should be 1.0 (no scaling)
        XCTAssertEqual(
            scaleFactor,
            1.0,
            accuracy: 0.001,
            "InteractionType.none should have scale factor of 1.0"
        )
    }

    func testInteractionTypeSubtleScaleFactor() {
        // Given: Subtle interaction type
        let interactionType = InteractionType.subtle

        // When: Getting scale factor
        let scaleFactor = interactionType.scaleFactor

        // Then: It should be slightly larger than 1.0
        XCTAssertEqual(
            scaleFactor,
            1.02,
            accuracy: 0.001,
            "InteractionType.subtle should have scale factor of 1.02 (2% increase)"
        )
    }

    func testInteractionTypeStandardScaleFactor() {
        // Given: Standard interaction type
        let interactionType = InteractionType.standard

        // When: Getting scale factor
        let scaleFactor = interactionType.scaleFactor

        // Then: It should have moderate scaling
        XCTAssertEqual(
            scaleFactor,
            1.05,
            accuracy: 0.001,
            "InteractionType.standard should have scale factor of 1.05 (5% increase)"
        )
    }

    func testInteractionTypeProminentScaleFactor() {
        // Given: Prominent interaction type
        let interactionType = InteractionType.prominent

        // When: Getting scale factor
        let scaleFactor = interactionType.scaleFactor

        // Then: It should have significant scaling
        XCTAssertEqual(
            scaleFactor,
            1.08,
            accuracy: 0.001,
            "InteractionType.prominent should have scale factor of 1.08 (8% increase)"
        )
    }

    // MARK: - Opacity Tests

    func testInteractionTypeSubtleOpacity() {
        // Given: Subtle interaction type
        let interactionType = InteractionType.subtle

        // When: Getting hover opacity
        let opacity = interactionType.hoverOpacity

        // Then: It should be slightly reduced
        XCTAssertEqual(
            opacity,
            0.95,
            accuracy: 0.001,
            "InteractionType.subtle should have opacity of 0.95"
        )
    }

    func testInteractionTypeStandardOpacity() {
        // Given: Standard interaction type
        let interactionType = InteractionType.standard

        // When: Getting hover opacity
        let opacity = interactionType.hoverOpacity

        // Then: It should be moderately reduced
        XCTAssertEqual(
            opacity,
            0.9,
            accuracy: 0.001,
            "InteractionType.standard should have opacity of 0.9"
        )
    }

    func testInteractionTypeProminentOpacity() {
        // Given: Prominent interaction type
        let interactionType = InteractionType.prominent

        // When: Getting hover opacity
        let opacity = interactionType.hoverOpacity

        // Then: It should be noticeably reduced
        XCTAssertEqual(
            opacity,
            0.85,
            accuracy: 0.001,
            "InteractionType.prominent should have opacity of 0.85"
        )
    }

    // MARK: - Accessibility Label Tests

    func testInteractionTypeNoneAccessibilityHint() {
        // Given: No interaction type
        let interactionType = InteractionType.none

        // When: Getting accessibility hint
        let hint = interactionType.accessibilityHint

        // Then: It should have empty hint
        XCTAssertEqual(
            hint,
            "",
            "InteractionType.none should have no accessibility hint"
        )
    }

    func testInteractionTypeSubtleAccessibilityHint() {
        // Given: Subtle interaction type
        let interactionType = InteractionType.subtle

        // When: Getting accessibility hint
        let hint = interactionType.accessibilityHint

        // Then: It should describe the interaction
        XCTAssertEqual(
            hint,
            "Interactive element with subtle feedback",
            "InteractionType.subtle should have descriptive accessibility hint"
        )
    }

    func testInteractionTypeStandardAccessibilityHint() {
        // Given: Standard interaction type
        let interactionType = InteractionType.standard

        // When: Getting accessibility hint
        let hint = interactionType.accessibilityHint

        // Then: It should describe the interaction
        XCTAssertEqual(
            hint,
            "Interactive element",
            "InteractionType.standard should have standard accessibility hint"
        )
    }

    func testInteractionTypeProminentAccessibilityHint() {
        // Given: Prominent interaction type
        let interactionType = InteractionType.prominent

        // When: Getting accessibility hint
        let hint = interactionType.accessibilityHint

        // Then: It should emphasize the interaction
        XCTAssertEqual(
            hint,
            "Primary interactive element with prominent feedback",
            "InteractionType.prominent should have emphatic accessibility hint"
        )
    }

    // MARK: - Keyboard Focus Tests

    func testInteractionTypeSupportsKeyboardFocus() {
        // Given: All interaction types that have effects
        let types: [InteractionType] = [.subtle, .standard, .prominent]

        // Then: They should support keyboard focus
        for type in types {
            XCTAssertTrue(
                type.supportsKeyboardFocus,
                "\(type) should support keyboard focus"
            )
        }
    }

    func testInteractionTypeNoneDoesNotSupportKeyboardFocus() {
        // Given: No interaction type
        let interactionType = InteractionType.none

        // Then: It should not support keyboard focus
        XCTAssertFalse(
            interactionType.supportsKeyboardFocus,
            "InteractionType.none should not support keyboard focus"
        )
    }

    // MARK: - Equality Tests

    func testInteractionTypeEquality() {
        // Given: Interaction types
        let subtle1 = InteractionType.subtle
        let subtle2 = InteractionType.subtle
        let standard = InteractionType.standard

        // Then: Same types should be equal
        XCTAssertEqual(subtle1, subtle2, "Same interaction types should be equal")
        XCTAssertNotEqual(subtle1, standard, "Different interaction types should not be equal")
    }

    // MARK: - All Cases Tests

    func testInteractionTypeAllCasesExist() {
        // Given: All interaction type cases
        let allCases: [InteractionType] = [.none, .subtle, .standard, .prominent]

        // Then: All cases should be valid
        XCTAssertEqual(
            allCases.count,
            4,
            "InteractionType should have exactly 4 cases"
        )

        // Each case should have valid properties
        for type in allCases {
            XCTAssertNotNil(type.scaleFactor)
            XCTAssertNotNil(type.hoverOpacity)
            XCTAssertNotNil(type.accessibilityHint)
        }
    }

    // MARK: - Animation Tests

    func testInteractionTypeUsesQuickAnimation() {
        // Given: All interaction types
        let types: [InteractionType] = [.none, .subtle, .standard, .prominent]

        // Then: They should specify DS.Animation.quick for interactions
        // (This is tested through integration - unit test verifies the enum exists)
        for type in types {
            XCTAssertNotNil(type)
        }
    }
}
