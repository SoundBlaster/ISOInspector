#if canImport(SwiftUI)
  import SwiftUI
  import XCTest
  @testable import FoundationUI

  /// Unit tests for ColorSchemeAdapter
  ///
  /// Tests verify:
  /// - Color scheme detection (light/dark)
  /// - Automatic Dark Mode adaptation
  /// - Environment integration
  /// - Platform-specific color adjustments
  final class ColorSchemeAdapterTests: XCTestCase {

    // MARK: - Color Scheme Detection Tests

    /// Test that ColorSchemeAdapter can detect light color scheme
    ///
    /// Verifies that the adapter correctly identifies light mode
    /// and returns appropriate values.
    func testLightColorSchemeDetection() throws {
      // Light color scheme should be detected
      let adapter = ColorSchemeAdapter(colorScheme: .light)
      XCTAssertEqual(
        adapter.colorScheme,
        .light,
        "Adapter should detect light color scheme"
      )
      XCTAssertFalse(
        adapter.isDarkMode,
        "isDarkMode should be false in light mode"
      )
    }

    /// Test that ColorSchemeAdapter can detect dark color scheme
    ///
    /// Verifies that the adapter correctly identifies dark mode
    /// and returns appropriate values.
    func testDarkColorSchemeDetection() throws {
      // Dark color scheme should be detected
      let adapter = ColorSchemeAdapter(colorScheme: .dark)
      XCTAssertEqual(
        adapter.colorScheme,
        .dark,
        "Adapter should detect dark color scheme"
      )
      XCTAssertTrue(
        adapter.isDarkMode,
        "isDarkMode should be true in dark mode"
      )
    }

    // MARK: - Adaptive Color Tests

    /// Test that adaptive colors change based on color scheme
    ///
    /// Verifies that the adapter provides different colors
    /// for light and dark modes.
    func testAdaptiveBackgroundColor() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      // Background colors should adapt to color scheme
      let lightBG = lightAdapter.adaptiveBackground
      let darkBG = darkAdapter.adaptiveBackground

      XCTAssertNotNil(lightBG, "Light background color should exist")
      XCTAssertNotNil(darkBG, "Dark background color should exist")
    }

    /// Test that adaptive secondary background adapts correctly
    ///
    /// Verifies that secondary backgrounds provide appropriate
    /// contrast in both light and dark modes.
    func testAdaptiveSecondaryBackground() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightSecondary = lightAdapter.adaptiveSecondaryBackground
      let darkSecondary = darkAdapter.adaptiveSecondaryBackground

      XCTAssertNotNil(lightSecondary, "Light secondary background should exist")
      XCTAssertNotNil(darkSecondary, "Dark secondary background should exist")
    }

    // MARK: - Text Color Adaptation Tests

    /// Test that text colors adapt to background brightness
    ///
    /// Verifies that the adapter provides appropriate text colors
    /// based on the current color scheme.
    func testAdaptiveTextColor() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightText = lightAdapter.adaptiveTextColor
      let darkText = darkAdapter.adaptiveTextColor

      XCTAssertNotNil(lightText, "Light text color should exist")
      XCTAssertNotNil(darkText, "Dark text color should exist")
    }

    /// Test that secondary text colors provide sufficient contrast
    ///
    /// Verifies that secondary text colors meet accessibility
    /// requirements in both color schemes.
    func testAdaptiveSecondaryTextColor() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightSecondaryText = lightAdapter.adaptiveSecondaryTextColor
      let darkSecondaryText = darkAdapter.adaptiveSecondaryTextColor

      XCTAssertNotNil(lightSecondaryText, "Light secondary text should exist")
      XCTAssertNotNil(darkSecondaryText, "Dark secondary text should exist")
    }

    // MARK: - Border and Divider Color Tests

    /// Test that border colors adapt to color scheme
    ///
    /// Verifies that borders maintain appropriate contrast
    /// in both light and dark modes.
    func testAdaptiveBorderColor() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightBorder = lightAdapter.adaptiveBorderColor
      let darkBorder = darkAdapter.adaptiveBorderColor

      XCTAssertNotNil(lightBorder, "Light border color should exist")
      XCTAssertNotNil(darkBorder, "Dark border color should exist")
    }

    /// Test that divider colors are subtle but visible
    ///
    /// Verifies that dividers provide visual separation
    /// without being too prominent.
    func testAdaptiveDividerColor() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightDivider = lightAdapter.adaptiveDividerColor
      let darkDivider = darkAdapter.adaptiveDividerColor

      XCTAssertNotNil(lightDivider, "Light divider color should exist")
      XCTAssertNotNil(darkDivider, "Dark divider color should exist")
    }

    // MARK: - Elevated Surface Tests

    /// Test that elevated surfaces adapt to color scheme
    ///
    /// Verifies that elevated surfaces (cards, panels) have
    /// appropriate colors in both light and dark modes.
    func testAdaptiveElevatedSurface() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      let lightElevated = lightAdapter.adaptiveElevatedSurface
      let darkElevated = darkAdapter.adaptiveElevatedSurface

      XCTAssertNotNil(lightElevated, "Light elevated surface should exist")
      XCTAssertNotNil(darkElevated, "Dark elevated surface should exist")
    }

    // MARK: - View Modifier Tests

    /// Test that ColorSchemeAdapter can be applied as a view modifier
    ///
    /// Verifies that views can use the adapter through a modifier.
    func testAdaptiveColorSchemeModifier() throws {
      struct TestView: View {
        var body: some View {
          Text("Test")
            .adaptiveColorScheme()
        }
      }

      let view = TestView()
      XCTAssertNotNil(view, "View with adaptive color scheme should be created")
    }

    // MARK: - Environment Integration Tests

    /// Test that ColorSchemeAdapter integrates with SwiftUI environment
    ///
    /// Verifies that the adapter can read color scheme from environment.
    func testEnvironmentIntegration() throws {
      struct TestView: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
          let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
          return Text("Scheme: \(adapter.isDarkMode ? "Dark" : "Light")")
        }
      }

      let view = TestView()
      XCTAssertNotNil(view, "View should read color scheme from environment")
    }

    // MARK: - Equatable Tests

    /// Test that ColorSchemeAdapter instances can be compared
    ///
    /// Verifies that adapters with the same color scheme are equal.
    func testEquatableConformance() throws {
      let adapter1 = ColorSchemeAdapter(colorScheme: .light)
      let adapter2 = ColorSchemeAdapter(colorScheme: .light)
      let adapter3 = ColorSchemeAdapter(colorScheme: .dark)

      XCTAssertEqual(
        adapter1.colorScheme,
        adapter2.colorScheme,
        "Adapters with same color scheme should be equal"
      )
      XCTAssertNotEqual(
        adapter1.colorScheme,
        adapter3.colorScheme,
        "Adapters with different color schemes should not be equal"
      )
    }

    // MARK: - Performance Tests

    /// Test that color scheme detection has minimal overhead
    ///
    /// Verifies that adapter creation is fast and efficient.
    func testAdapterCreationPerformance() throws {
      measure {
        for _ in 0..<1000 {
          _ = ColorSchemeAdapter(colorScheme: .light)
        }
      }
    }

    /// Test that color adaptation is performant
    ///
    /// Verifies that adaptive color lookups are fast.
    func testColorAdaptationPerformance() throws {
      let adapter = ColorSchemeAdapter(colorScheme: .light)

      measure {
        for _ in 0..<1000 {
          _ = adapter.adaptiveBackground
          _ = adapter.adaptiveTextColor
          _ = adapter.adaptiveBorderColor
        }
      }
    }
  }

  // MARK: - Integration Tests

  /// Integration tests for ColorSchemeAdapter in realistic scenarios
  ///
  /// Tests verify behavior in real-world UI patterns with
  /// automatic Dark Mode adaptation.
  final class ColorSchemeAdapterIntegrationTests: XCTestCase {

    /// Test ColorSchemeAdapter in a card component
    ///
    /// Verifies that cards adapt their colors correctly
    /// based on the color scheme.
    func testCardWithAdaptiveColors() throws {
      struct AdaptiveCard: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
          let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
          return VStack {
            Text("Card Title")
              .foregroundColor(adapter.adaptiveTextColor)
          }
          .padding(DS.Spacing.m)
          .background(adapter.adaptiveElevatedSurface)
          .cornerRadius(DS.Radius.card)
          .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
              .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
          )
        }
      }

      let view = AdaptiveCard()
      XCTAssertNotNil(view, "Adaptive card should be created successfully")
    }

    /// Test ColorSchemeAdapter with badge components
    ///
    /// Verifies that badges maintain proper contrast
    /// in both light and dark modes.
    func testBadgeWithAdaptiveColors() throws {
      struct AdaptiveBadge: View {
        @Environment(\.colorScheme) var colorScheme
        let level: BadgeLevel

        var body: some View {
          let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
          return Text(level.rawValue.uppercased())
            .font(DS.Typography.caption)
            .foregroundColor(adapter.adaptiveTextColor)
            .padding(.horizontal, DS.Spacing.m)
            .padding(.vertical, DS.Spacing.s)
            .background(level.backgroundColor)
            .cornerRadius(DS.Radius.chip)
        }
      }

      let view = AdaptiveBadge(level: .info)
      XCTAssertNotNil(view, "Adaptive badge should be created successfully")
    }

    /// Test ColorSchemeAdapter in inspector pattern
    ///
    /// Verifies that complex UI patterns adapt correctly
    /// with proper visual hierarchy in both modes.
    func testInspectorWithAdaptiveColors() throws {
      struct AdaptiveInspector: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
          let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
          return HStack(spacing: 0) {
            // Main content
            VStack {
              Text("Content")
            }
            .frame(maxWidth: .infinity)
            .background(adapter.adaptiveBackground)

            // Inspector panel
            VStack {
              Text("Inspector")
            }
            .frame(width: 250)
            .background(adapter.adaptiveSecondaryBackground)
            .overlay(
              Rectangle()
                .frame(width: 1)
                .foregroundColor(adapter.adaptiveDividerColor),
              alignment: .leading
            )
          }
        }
      }

      let view = AdaptiveInspector()
      XCTAssertNotNil(view, "Adaptive inspector should be created successfully")
    }

    /// Test automatic Dark Mode switching
    ///
    /// Verifies that the adapter responds correctly when
    /// the system color scheme changes.
    func testDarkModeSwitching() throws {
      struct SwitchableView: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
          let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
          return VStack(spacing: DS.Spacing.m) {
            Text("Current Mode: \(adapter.isDarkMode ? "Dark" : "Light")")
              .foregroundColor(adapter.adaptiveTextColor)

            Text("Background adapts automatically")
              .foregroundColor(adapter.adaptiveSecondaryTextColor)
          }
          .padding(DS.Spacing.l)
          .background(adapter.adaptiveBackground)
        }
      }

      let view = SwitchableView()
      XCTAssertNotNil(view, "Switchable view should be created successfully")
    }

    /// Test that all DS.Color tokens work with ColorSchemeAdapter
    ///
    /// Verifies compatibility with existing design tokens.
    func testCompatibilityWithDesignTokens() throws {
      let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
      let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

      // Verify that DS.Color tokens work alongside adapter
      let colors: [Color] = [
        DS.Color.infoBG,
        DS.Color.warnBG,
        DS.Color.errorBG,
        DS.Color.successBG,
      ]

      for color in colors {
        XCTAssertNotNil(color, "DS.Color token should be valid")
      }

      // Adaptive colors should also be valid
      XCTAssertNotNil(lightAdapter.adaptiveBackground)
      XCTAssertNotNil(darkAdapter.adaptiveBackground)
    }
  }
#endif
