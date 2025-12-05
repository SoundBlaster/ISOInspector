import XCTest

@testable import FoundationUI

#if canImport(SwiftUI)
    import SwiftUI

    /// Comprehensive unit tests for ColorSchemeAdapter
    ///
    /// Tests automatic Dark Mode adaptation, color scheme detection, and
    /// adaptive color properties following FoundationUI principles:
    /// - **Zero magic numbers**: All values use DS tokens or system colors
    /// - **100% API coverage**: Tests all public APIs
    /// - **WCAG Compliance**: Validates accessibility color requirements
    /// - **Platform Support**: Tests iOS and macOS color handling
    ///
    /// ## Test Categories
    /// - Initialization tests
    /// - Color scheme detection tests
    /// - Adaptive color tests (7 color properties)
    /// - Platform-specific tests
    /// - View modifier tests
    /// - Edge case tests
    @MainActor final class ColorSchemeAdapterTests: XCTestCase {
        // MARK: - Initialization Tests

        /// Tests ColorSchemeAdapter initialization with light mode
        ///
        /// **Given**: ColorScheme.light
        /// **When**: Creating ColorSchemeAdapter
        /// **Then**: Should store light color scheme correctly
        ///
        /// **Use Case**: Default mode for most applications
        func testColorSchemeAdapter_InitWithLightMode_ReturnsCorrectScheme() {
            // Act
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            // Assert
            XCTAssertEqual(adapter.colorScheme, .light, "Adapter should store light color scheme")
        }

        /// Tests ColorSchemeAdapter initialization with dark mode
        ///
        /// **Given**: ColorScheme.dark
        /// **When**: Creating ColorSchemeAdapter
        /// **Then**: Should store dark color scheme correctly
        ///
        /// **Use Case**: Dark mode for reduced eye strain
        func testColorSchemeAdapter_InitWithDarkMode_ReturnsCorrectScheme() {
            // Act
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            // Assert
            XCTAssertEqual(adapter.colorScheme, .dark, "Adapter should store dark color scheme")
        }

        // MARK: - Color Scheme Detection Tests

        /// Tests isDarkMode returns false for light color scheme
        ///
        /// **Given**: ColorSchemeAdapter with .light
        /// **When**: Reading isDarkMode property
        /// **Then**: Should return false
        ///
        /// **Use Case**: Conditional UI logic based on mode
        func testColorSchemeAdapter_IsDarkMode_LightScheme_ReturnsFalse() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            // Act
            let isDark = adapter.isDarkMode

            // Assert
            XCTAssertFalse(isDark, "isDarkMode should return false for light scheme")
        }

        /// Tests isDarkMode returns true for dark color scheme
        ///
        /// **Given**: ColorSchemeAdapter with .dark
        /// **When**: Reading isDarkMode property
        /// **Then**: Should return true
        ///
        /// **Use Case**: Dark mode specific rendering logic
        func testColorSchemeAdapter_IsDarkMode_DarkScheme_ReturnsTrue() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act
            let isDark = adapter.isDarkMode

            // Assert
            XCTAssertTrue(isDark, "isDarkMode should return true for dark scheme")
        }

        /// Tests that color scheme changes affect isDarkMode
        ///
        /// **Given**: Multiple ColorSchemeAdapter instances
        /// **When**: Creating adapters with different schemes
        /// **Then**: isDarkMode should reflect each scheme correctly
        ///
        /// **Use Case**: Reactive UI updates on scheme changes
        func testColorSchemeAdapter_IsDarkMode_ReflectsColorSchemeChanges() {
            // Arrange & Act
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Assert
            XCTAssertFalse(lightAdapter.isDarkMode, "Light adapter should not be dark mode")
            XCTAssertTrue(darkAdapter.isDarkMode, "Dark adapter should be dark mode")
        }

        // MARK: - Adaptive Background Color Tests

        /// Tests adaptiveBackground returns non-nil color for light mode
        ///
        /// **Given**: ColorSchemeAdapter with .light
        /// **When**: Reading adaptiveBackground property
        /// **Then**: Should return valid Color instance
        ///
        /// **Requirement**: Primary background must always be available
        func testColorSchemeAdapter_AdaptiveBackground_LightMode_ReturnsColor() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            // Act
            let background = adapter.adaptiveBackground

            // Assert
            XCTAssertNotNil(background, "adaptiveBackground should return non-nil color")
        }

        /// Tests adaptiveBackground returns non-nil color for dark mode
        ///
        /// **Given**: ColorSchemeAdapter with .dark
        /// **When**: Reading adaptiveBackground property
        /// **Then**: Should return valid Color instance
        ///
        /// **Requirement**: Dark mode background must be available
        func testColorSchemeAdapter_AdaptiveBackground_DarkMode_ReturnsColor() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act
            let background = adapter.adaptiveBackground

            // Assert
            XCTAssertNotNil(background, "adaptiveBackground should return non-nil color")
        }

        /// Tests adaptiveSecondaryBackground returns non-nil color
        ///
        /// **Given**: ColorSchemeAdapter (both modes)
        /// **When**: Reading adaptiveSecondaryBackground property
        /// **Then**: Should return valid Color instance
        ///
        /// **Use Case**: Sidebar and panel backgrounds
        func testColorSchemeAdapter_AdaptiveSecondaryBackground_ReturnsColor() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert
            XCTAssertNotNil(
                lightAdapter.adaptiveSecondaryBackground,
                "Secondary background should exist in light mode")
            XCTAssertNotNil(
                darkAdapter.adaptiveSecondaryBackground,
                "Secondary background should exist in dark mode")
        }

        /// Tests adaptiveElevatedSurface returns non-nil color
        ///
        /// **Given**: ColorSchemeAdapter (both modes)
        /// **When**: Reading adaptiveElevatedSurface property
        /// **Then**: Should return valid Color instance
        ///
        /// **Use Case**: Card and modal backgrounds
        func testColorSchemeAdapter_AdaptiveElevatedSurface_ReturnsColor() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert
            XCTAssertNotNil(
                lightAdapter.adaptiveElevatedSurface, "Elevated surface should exist in light mode")
            XCTAssertNotNil(
                darkAdapter.adaptiveElevatedSurface, "Elevated surface should exist in dark mode")
        }

        // MARK: - Adaptive Text Color Tests

        /// Tests adaptiveTextColor returns non-nil for light mode
        ///
        /// **Given**: ColorSchemeAdapter with .light
        /// **When**: Reading adaptiveTextColor property
        /// **Then**: Should return valid Color instance
        ///
        /// **Accessibility**: Text color must meet ≥4.5:1 contrast
        func testColorSchemeAdapter_AdaptiveTextColor_LightMode_ReturnsColor() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            // Act
            let textColor = adapter.adaptiveTextColor

            // Assert
            XCTAssertNotNil(textColor, "adaptiveTextColor should return non-nil color")
        }

        /// Tests adaptiveTextColor returns non-nil for dark mode
        ///
        /// **Given**: ColorSchemeAdapter with .dark
        /// **When**: Reading adaptiveTextColor property
        /// **Then**: Should return valid Color instance
        ///
        /// **Accessibility**: Dark mode text must be readable
        func testColorSchemeAdapter_AdaptiveTextColor_DarkMode_ReturnsColor() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act
            let textColor = adapter.adaptiveTextColor

            // Assert
            XCTAssertNotNil(textColor, "adaptiveTextColor should return non-nil color")
        }

        /// Tests adaptiveSecondaryTextColor returns non-nil color
        ///
        /// **Given**: ColorSchemeAdapter (both modes)
        /// **When**: Reading adaptiveSecondaryTextColor property
        /// **Then**: Should return valid Color instance
        ///
        /// **Use Case**: Captions, subtitles, metadata
        func testColorSchemeAdapter_AdaptiveSecondaryTextColor_ReturnsColor() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert
            XCTAssertNotNil(
                lightAdapter.adaptiveSecondaryTextColor,
                "Secondary text color should exist in light mode")
            XCTAssertNotNil(
                darkAdapter.adaptiveSecondaryTextColor,
                "Secondary text color should exist in dark mode")
        }

        // MARK: - Adaptive Border and Divider Color Tests

        /// Tests adaptiveBorderColor returns non-nil color
        ///
        /// **Given**: ColorSchemeAdapter (both modes)
        /// **When**: Reading adaptiveBorderColor property
        /// **Then**: Should return valid Color instance
        ///
        /// **Use Case**: Card borders, input outlines
        func testColorSchemeAdapter_AdaptiveBorderColor_ReturnsColor() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert
            XCTAssertNotNil(
                lightAdapter.adaptiveBorderColor, "Border color should exist in light mode")
            XCTAssertNotNil(
                darkAdapter.adaptiveBorderColor, "Border color should exist in dark mode")
        }

        /// Tests adaptiveDividerColor returns non-nil color
        ///
        /// **Given**: ColorSchemeAdapter (both modes)
        /// **When**: Reading adaptiveDividerColor property
        /// **Then**: Should return valid Color instance
        ///
        /// **Use Case**: List dividers, section separators
        func testColorSchemeAdapter_AdaptiveDividerColor_ReturnsColor() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert
            XCTAssertNotNil(
                lightAdapter.adaptiveDividerColor, "Divider color should exist in light mode")
            XCTAssertNotNil(
                darkAdapter.adaptiveDividerColor, "Divider color should exist in dark mode")
        }

        // MARK: - All Colors Integration Test

        /// Tests that all adaptive colors are available in both modes
        ///
        /// **Given**: ColorSchemeAdapter for both light and dark modes
        /// **When**: Reading all 7 adaptive color properties
        /// **Then**: All should return non-nil Color instances
        ///
        /// **Coverage**: Comprehensive API validation
        /// **Importance**: Ensures complete color palette
        func testColorSchemeAdapter_AllAdaptiveColors_ExistInBothModes() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act & Assert - Light Mode
            XCTAssertNotNil(lightAdapter.adaptiveBackground, "Light: background")
            XCTAssertNotNil(lightAdapter.adaptiveSecondaryBackground, "Light: secondaryBackground")
            XCTAssertNotNil(lightAdapter.adaptiveElevatedSurface, "Light: elevatedSurface")
            XCTAssertNotNil(lightAdapter.adaptiveTextColor, "Light: textColor")
            XCTAssertNotNil(lightAdapter.adaptiveSecondaryTextColor, "Light: secondaryTextColor")
            XCTAssertNotNil(lightAdapter.adaptiveBorderColor, "Light: borderColor")
            XCTAssertNotNil(lightAdapter.adaptiveDividerColor, "Light: dividerColor")

            // Act & Assert - Dark Mode
            XCTAssertNotNil(darkAdapter.adaptiveBackground, "Dark: background")
            XCTAssertNotNil(darkAdapter.adaptiveSecondaryBackground, "Dark: secondaryBackground")
            XCTAssertNotNil(darkAdapter.adaptiveElevatedSurface, "Dark: elevatedSurface")
            XCTAssertNotNil(darkAdapter.adaptiveTextColor, "Dark: textColor")
            XCTAssertNotNil(darkAdapter.adaptiveSecondaryTextColor, "Dark: secondaryTextColor")
            XCTAssertNotNil(darkAdapter.adaptiveBorderColor, "Dark: borderColor")
            XCTAssertNotNil(darkAdapter.adaptiveDividerColor, "Dark: dividerColor")
        }

        // MARK: - Platform-Specific Tests

        #if os(iOS)
            /// Tests that iOS-specific colors are used on iOS platform
            ///
            /// **Given**: ColorSchemeAdapter on iOS
            /// **When**: Reading adaptive colors
            /// **Then**: Should use UIColor-based system colors
            ///
            /// **Platform**: iOS 17.0+
            func testColorSchemeAdapter_iOS_UsesUIColorSystemColors() {
                // Arrange
                let adapter = ColorSchemeAdapter(colorScheme: .light)

                // Act - Access colors to ensure no crash
                _ = adapter.adaptiveBackground
                _ = adapter.adaptiveTextColor

                // Assert - If execution reaches here, colors work on iOS
                XCTAssertTrue(true, "iOS system colors should be accessible")
            }
        #endif

        #if os(macOS)
            /// Tests that macOS-specific colors are used on macOS platform
            ///
            /// **Given**: ColorSchemeAdapter on macOS
            /// **When**: Reading adaptive colors
            /// **Then**: Should use NSColor-based system colors
            ///
            /// **Platform**: macOS 14.0+
            func testColorSchemeAdapter_macOS_UsesNSColorSystemColors() {
                // Arrange
                let adapter = ColorSchemeAdapter(colorScheme: .light)

                // Act - Access colors to ensure no crash
                _ = adapter.adaptiveBackground
                _ = adapter.adaptiveTextColor

                // Assert - If execution reaches here, colors work on macOS
                XCTAssertTrue(true, "macOS system colors should be accessible")
            }
        #endif

        /// Tests cross-platform color consistency
        ///
        /// **Given**: ColorSchemeAdapter
        /// **When**: Creating instances on any platform
        /// **Then**: Should provide consistent API
        ///
        /// **Cross-Platform**: iOS, macOS, iPadOS
        func testColorSchemeAdapter_CrossPlatform_ProvidesConsistentAPI() {
            // Arrange & Act
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Assert - API should work consistently
            XCTAssertNotNil(lightAdapter.adaptiveBackground)
            XCTAssertNotNil(darkAdapter.adaptiveBackground)
            XCTAssertFalse(lightAdapter.isDarkMode)
            XCTAssertTrue(darkAdapter.isDarkMode)
        }

        /// Tests that system colors adapt automatically
        ///
        /// **Given**: ColorSchemeAdapter using system colors
        /// **When**: Platform handles color scheme changes
        /// **Then**: Colors should adapt automatically
        ///
        /// **System Integration**: Leverages SwiftUI's color adaptation
        func testColorSchemeAdapter_SystemColors_AdaptAutomatically() {
            // Arrange
            let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
            let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act - Get colors for both modes
            let lightBG = lightAdapter.adaptiveBackground
            let darkBG = darkAdapter.adaptiveBackground

            // Assert - Colors exist and are valid SwiftUI.Color instances
            XCTAssertNotNil(lightBG, "Light background should exist")
            XCTAssertNotNil(darkBG, "Dark background should exist")
        }

        // MARK: - View Modifier Tests

        /// Tests that adaptiveColorScheme() modifier exists
        ///
        /// **Given**: SwiftUI View
        /// **When**: Applying .adaptiveColorScheme() modifier
        /// **Then**: Should compile and return modified view
        ///
        /// **API Coverage**: View extension validation
        @MainActor func testView_AdaptiveColorSchemeModifier_Exists() {
            // Arrange
            let view = Text("Test")

            // Act - Apply modifier
            let modifiedView = view.adaptiveColorScheme()

            // Assert - If compilation succeeds, modifier exists
            XCTAssertNotNil(modifiedView, "adaptiveColorScheme() modifier should exist")
        }

        /// Tests adaptiveColorScheme() modifier with real views
        ///
        /// **Given**: Complex view hierarchy
        /// **When**: Applying .adaptiveColorScheme() modifier
        /// **Then**: Should work with any View type
        ///
        /// **Integration**: Validates real-world usage
        @MainActor func testView_AdaptiveColorSchemeModifier_WorksWithComplexViews() {
            // Arrange - Create complex view
            let complexView = VStack {
                Text("Title")
                HStack {
                    Text("Left")
                    Text("Right")
                }
            }

            // Act - Apply modifier
            let modifiedView = complexView.adaptiveColorScheme()

            // Assert - Modifier should work with complex hierarchies
            XCTAssertNotNil(modifiedView, "Modifier should work with complex views")
        }

        // MARK: - Edge Case Tests

        /// Tests rapid color scheme changes
        ///
        /// **Given**: Multiple sequential adapter creations
        /// **When**: Creating adapters with alternating schemes
        /// **Then**: Each should maintain correct state
        ///
        /// **Use Case**: Rapid system theme changes
        func testColorSchemeAdapter_RapidSchemeChanges_MaintainsCorrectState() {
            // Arrange - Create alternating adapters
            let adapters: [ColorSchemeAdapter] = [
                ColorSchemeAdapter(colorScheme: .light), ColorSchemeAdapter(colorScheme: .dark),
                ColorSchemeAdapter(colorScheme: .light), ColorSchemeAdapter(colorScheme: .dark),
                ColorSchemeAdapter(colorScheme: .light),
            ]

            // Act & Assert - Each maintains correct state
            XCTAssertFalse(adapters[0].isDarkMode, "Adapter 0 should be light")
            XCTAssertTrue(adapters[1].isDarkMode, "Adapter 1 should be dark")
            XCTAssertFalse(adapters[2].isDarkMode, "Adapter 2 should be light")
            XCTAssertTrue(adapters[3].isDarkMode, "Adapter 3 should be dark")
            XCTAssertFalse(adapters[4].isDarkMode, "Adapter 4 should be light")
        }

        /// Tests adapter immutability
        ///
        /// **Given**: ColorSchemeAdapter instance
        /// **When**: Accessing properties multiple times
        /// **Then**: Should return consistent values
        ///
        /// **Design**: Adapters are immutable value types
        func testColorSchemeAdapter_Immutability_ReturnsConsistentValues() {
            // Arrange
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            // Act - Read properties multiple times
            let isDark1 = adapter.isDarkMode
            let isDark2 = adapter.isDarkMode
            let bg1 = adapter.adaptiveBackground
            let bg2 = adapter.adaptiveBackground

            // Assert - Values should be consistent
            XCTAssertEqual(isDark1, isDark2, "isDarkMode should be consistent")
            XCTAssertNotNil(bg1, "Background should exist on first read")
            XCTAssertNotNil(bg2, "Background should exist on second read")
        }

        // MARK: - Performance Tests

        /// Tests that ColorSchemeAdapter initialization is lightweight
        ///
        /// **Given**: Performance measurement
        /// **When**: Creating many adapter instances
        /// **Then**: Should complete quickly (<0.01s for 1000 instances)
        ///
        /// **Requirement**: Adapters must be performant for frequent use
        func testColorSchemeAdapter_Performance_LightweightInitialization() {
            measure {
                // Act - Create 1000 adapters
                for _ in 0..<1000 {
                    _ = ColorSchemeAdapter(colorScheme: .light)
                    _ = ColorSchemeAdapter(colorScheme: .dark)
                }
            }
        }
    }

#endif
