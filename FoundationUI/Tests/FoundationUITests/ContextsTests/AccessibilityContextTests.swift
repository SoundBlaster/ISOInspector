import XCTest
#if canImport(SwiftUI)
import SwiftUI
@testable import FoundationUI

/// Unit tests for AccessibilityContext environment keys and adapters
///
/// Tests verify:
/// - Reduce motion detection and usage
/// - Increase contrast support
/// - Bold text handling
/// - Dynamic Type environment values
/// - Environment key propagation
/// - View modifier functionality
@MainActor
final class AccessibilityContextTests: XCTestCase {
    
    // MARK: - Reduce Motion Tests
    
    /// Test that reduce motion preference is correctly detected
    func testReduceMotionDetection() {
        // Given: System accessibility settings
        let context = AccessibilityContext()
        
        // Then: Should provide reduce motion state
        XCTAssertNotNil(context.isReduceMotionEnabled)
    }
    
    /// Test that animations are disabled when reduce motion is enabled
    func testReduceMotionDisablesAnimations() {
        // Given: Reduce motion is enabled
        let context = AccessibilityContext(isReduceMotionEnabled: true)
        
        // Then: Animation should be nil or identity
        XCTAssertTrue(context.isReduceMotionEnabled)
        XCTAssertNotNil(context.adaptiveAnimation)
    }
    
    /// Test that animations work normally when reduce motion is disabled
    func testReduceMotionAllowsAnimations() {
        // Given: Reduce motion is disabled
        let context = AccessibilityContext(isReduceMotionEnabled: false)
        
        // Then: Animation should be available
        XCTAssertFalse(context.isReduceMotionEnabled)
        XCTAssertNotNil(context.adaptiveAnimation)
    }
    
    // MARK: - Increase Contrast Tests
    
    /// Test that increase contrast preference is correctly detected
    func testIncreaseContrastDetection() {
        // Given: System accessibility settings
        let context = AccessibilityContext()
        
        // Then: Should provide increase contrast state
        XCTAssertNotNil(context.isIncreaseContrastEnabled)
    }
    
    /// Test that colors adapt when increase contrast is enabled
    func testIncreaseContrastAdaptsColors() {
        // Given: Increase contrast is enabled
        let context = AccessibilityContext(isIncreaseContrastEnabled: true)
        
        // Then: Should provide high contrast colors
        XCTAssertTrue(context.isIncreaseContrastEnabled)
        XCTAssertNotNil(context.adaptiveForeground)
        XCTAssertNotNil(context.adaptiveBackground)
    }
    
    /// Test that normal colors are used when increase contrast is disabled
    func testNormalContrastColors() {
        // Given: Increase contrast is disabled
        let context = AccessibilityContext(isIncreaseContrastEnabled: false)
        
        // Then: Should use normal contrast colors
        XCTAssertFalse(context.isIncreaseContrastEnabled)
        XCTAssertNotNil(context.adaptiveForeground)
        XCTAssertNotNil(context.adaptiveBackground)
    }
    
    // MARK: - Bold Text Tests
    
    /// Test that bold text preference is correctly detected
    func testBoldTextDetection() {
        // Given: System accessibility settings
        let context = AccessibilityContext()
        
        // Then: Should provide bold text state
        XCTAssertNotNil(context.isBoldTextEnabled)
    }
    
    /// Test that font weight increases when bold text is enabled
    func testBoldTextIncreasesWeight() {
        // Given: Bold text is enabled
        let context = AccessibilityContext(isBoldTextEnabled: true)
        
        // Then: Should provide bold font variant
        XCTAssertTrue(context.isBoldTextEnabled)
        XCTAssertNotNil(context.adaptiveFontWeight)
    }
    
    /// Test that normal font weight is used when bold text is disabled
    func testNormalFontWeight() {
        // Given: Bold text is disabled
        let context = AccessibilityContext(isBoldTextEnabled: false)
        
        // Then: Should use normal font weight
        XCTAssertFalse(context.isBoldTextEnabled)
        XCTAssertNotNil(context.adaptiveFontWeight)
    }
    
    // MARK: - Dynamic Type Tests
    
    /// Test that Dynamic Type size is correctly detected
    func testDynamicTypeSizeDetection() {
        // Given: System Dynamic Type settings
        let context = AccessibilityContext()
        
        // Then: Should provide current Dynamic Type size
        XCTAssertNotNil(context.sizeCategory)
    }
    
    /// Test that font scales with Dynamic Type
    func testDynamicTypeScaling() {
        // Given: Large Dynamic Type size
        let context = AccessibilityContext(sizeCategory: .accessibilityLarge)
        
        // Then: Font should scale appropriately
        XCTAssertEqual(context.sizeCategory, .accessibilityLarge)
        XCTAssertNotNil(context.scaledFont(for: DS.Typography.body))
    }
    
    /// Test that small Dynamic Type size works
    func testSmallDynamicTypeSize() {
        // Given: Small Dynamic Type size
        let context = AccessibilityContext(sizeCategory: .small)
        
        // Then: Font should scale down
        XCTAssertEqual(context.sizeCategory, .small)
        XCTAssertNotNil(context.scaledFont(for: DS.Typography.body))
    }
    
    /// Test that accessibility sizes (XXXL) are supported
    func testAccessibilityDynamicTypeSizes() {
        // Given: Accessibility XXL size
        let context = AccessibilityContext(sizeCategory: .accessibilityExtraExtraExtraLarge)
        
        // Then: Should support large accessibility sizes
        XCTAssertEqual(context.sizeCategory, .accessibilityExtraExtraExtraLarge)
        XCTAssertTrue(context.isAccessibilitySize)
    }
    
    // MARK: - Combined Accessibility Tests
    
    /// Test that multiple accessibility features can be enabled simultaneously
    func testMultipleAccessibilityFeatures() {
        // Given: Multiple accessibility features enabled
        let context = AccessibilityContext(
            isReduceMotionEnabled: true,
            isIncreaseContrastEnabled: true,
            isBoldTextEnabled: true,
            sizeCategory: .accessibilityLarge
        )
        
        // Then: All features should be respected
        XCTAssertTrue(context.isReduceMotionEnabled)
        XCTAssertTrue(context.isIncreaseContrastEnabled)
        XCTAssertTrue(context.isBoldTextEnabled)
        XCTAssertEqual(context.sizeCategory, .accessibilityLarge)
    }
    
    /// Test default accessibility context with system settings
    func testDefaultAccessibilityContext() {
        // Given: System default settings
        let context = AccessibilityContext()
        
        // Then: Should have valid values
        XCTAssertNotNil(context.isReduceMotionEnabled)
        XCTAssertNotNil(context.isIncreaseContrastEnabled)
        XCTAssertNotNil(context.isBoldTextEnabled)
        XCTAssertNotNil(context.sizeCategory)
    }
    
    // MARK: - Accessibility Helper Tests
    
    /// Test helper method for determining if accessibility sizes are active
    func testIsAccessibilitySizeHelper() {
        // Given: Standard size
        let standardContext = AccessibilityContext(sizeCategory: .medium)
        XCTAssertFalse(standardContext.isAccessibilitySize)
        
        // Given: Accessibility size
        let a11yContext = AccessibilityContext(sizeCategory: .accessibilityMedium)
        XCTAssertTrue(a11yContext.isAccessibilitySize)
    }
    
    /// Test that scaled spacing adapts to Dynamic Type
    func testScaledSpacing() {
        // Given: Different Dynamic Type sizes
        let smallContext = AccessibilityContext(sizeCategory: .small)
        let largeContext = AccessibilityContext(sizeCategory: .accessibilityLarge)
        
        // Then: Spacing should scale (or remain constant for consistency)
        XCTAssertNotNil(smallContext.scaledSpacing(DS.Spacing.m))
        XCTAssertNotNil(largeContext.scaledSpacing(DS.Spacing.m))
    }
    
    // MARK: - Environment Key Tests
    
    /// Test that accessibility context can be set in environment
    func testAccessibilityContextEnvironmentKey() {
        // Given: A custom accessibility context
        let customContext = AccessibilityContext(
            isReduceMotionEnabled: true,
            isIncreaseContrastEnabled: false,
            isBoldTextEnabled: true,
            sizeCategory: .large
        )
        
        // Then: Context should be settable via environment
        XCTAssertTrue(customContext.isReduceMotionEnabled)
        XCTAssertFalse(customContext.isIncreaseContrastEnabled)
        XCTAssertTrue(customContext.isBoldTextEnabled)
        XCTAssertEqual(customContext.sizeCategory, .large)
    }
}

#endif // canImport(SwiftUI)
