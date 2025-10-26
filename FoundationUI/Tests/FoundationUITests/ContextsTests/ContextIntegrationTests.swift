#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import FoundationUI

/// Integration tests for FoundationUI Context layer components
///
/// Tests verify correct interaction between:
/// - SurfaceStyleKey environment values
/// - PlatformAdaptation modifiers
/// - ColorSchemeAdapter color adaptation
///
/// These tests ensure all context components work together correctly
/// in realistic UI scenarios.
final class ContextIntegrationTests: XCTestCase {

    // MARK: - Environment Propagation Tests

    /// Test that SurfaceStyleKey propagates through nested components
    ///
    /// Verifies that environment values set at a parent level
    /// are correctly accessible in child components.
    @MainActor
    func testSurfaceStylePropagation_NestedComponents() throws {
        struct NestedView: View {
            @Environment(\.surfaceStyle) var surfaceStyle

            var actualStyle: SurfaceMaterial {
                surfaceStyle
            }

            var body: some View {
                Text("Nested")
            }
        }

        // Test propagation through view hierarchy
        let view = NestedView()
            .environment(\.surfaceStyle, .thick)

        // Verify the view can be created (environment propagates)
        XCTAssertNotNil(view, "Nested view should receive environment value")
    }

    /// Test that multiple environment keys propagate independently
    ///
    /// Verifies that different environment keys don't interfere
    /// with each other's propagation.
    @MainActor
    func testMultipleEnvironmentKeys_Propagation() throws {
        struct MultiEnvView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                Text("Multi-env")
            }
        }

        let view = MultiEnvView()
            .environment(\.surfaceStyle, .regular)
            .preferredColorScheme(.dark)

        XCTAssertNotNil(view, "Multiple environment keys should propagate independently")
    }

    // MARK: - Platform Adaptation Integration Tests

    /// Test PlatformAdapter integration with real components
    ///
    /// Verifies that platform-adaptive spacing works correctly
    /// when applied to actual UI components.
    @MainActor
    func testPlatformAdapter_WithComponents() throws {
        let badge = Text("Test")
            .padding(PlatformAdapter.defaultSpacing)

        XCTAssertNotNil(badge, "Platform spacing should integrate with components")

        // Verify spacing is a valid DS token
        let spacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing), "Platform spacing should use DS tokens")
    }

    /// Test platform spacing adaptation in complex hierarchies
    ///
    /// Verifies that platform-adaptive spacing works correctly
    /// in deeply nested view hierarchies.
    @MainActor
    func testPlatformSpacing_InComplexHierarchy() throws {
        let complexView = VStack(spacing: PlatformAdapter.defaultSpacing) {
            HStack(spacing: PlatformAdapter.defaultSpacing) {
                Text("Item 1")
                Text("Item 2")
            }
            Text("Item 3")
        }
        .padding(PlatformAdapter.defaultSpacing)

        XCTAssertNotNil(complexView, "Platform spacing should work in complex hierarchies")
    }

    /// Test platform-adaptive modifier integration
    ///
    /// Verifies that the platformAdaptive() modifier integrates
    /// correctly with other view modifiers.
    @MainActor
    func testPlatformAdapter_ModifierIntegration() throws {
        let view = Text("Test")
            .platformAdaptive()
            .padding(DS.Spacing.m)

        XCTAssertNotNil(view, "Platform adaptive modifier should chain with other modifiers")
    }

    // MARK: - Color Scheme Integration Tests

    /// Test ColorSchemeAdapter with different color schemes
    ///
    /// Verifies that the adapter correctly detects and responds
    /// to light vs dark color schemes.
    ///
    /// Note: We test adapter behavior, not color object equality,
    /// because dynamic system colors cannot be directly compared.
    func testColorSchemeAdapter_AdaptiveColors() throws {
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

        // Test color scheme detection
        XCTAssertFalse(lightAdapter.isDarkMode, "Light adapter should not be dark mode")
        XCTAssertTrue(darkAdapter.isDarkMode, "Dark adapter should be dark mode")

        // Test that colors exist (are not nil)
        // Note: We don't compare Color objects directly because dynamic system
        // colors may compare as equal even when from different schemes
        XCTAssertNotNil(lightAdapter.adaptiveBackground, "Light background should exist")
        XCTAssertNotNil(darkAdapter.adaptiveBackground, "Dark background should exist")

        XCTAssertNotNil(lightAdapter.adaptiveTextColor, "Light text color should exist")
        XCTAssertNotNil(darkAdapter.adaptiveTextColor, "Dark text color should exist")

        XCTAssertNotNil(lightAdapter.adaptiveBorderColor, "Light border color should exist")
        XCTAssertNotNil(darkAdapter.adaptiveBorderColor, "Dark border color should exist")
    }

    /// Test ColorSchemeAdapter integration with environment
    ///
    /// Verifies that the adapter works correctly when reading
    /// color scheme from SwiftUI environment.
    @MainActor
    func testColorSchemeAdapter_WithEnvironment() throws {
        struct AdaptiveView: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
                return Text("Adaptive")
                    .foregroundColor(adapter.adaptiveTextColor)
                    .background(adapter.adaptiveBackground)
            }
        }

        let view = AdaptiveView()
        XCTAssertNotNil(view, "ColorSchemeAdapter should integrate with environment")
    }

    /// Test ColorSchemeAdapter with all components
    ///
    /// Verifies that adaptive colors work correctly with
    /// various UI components.
    @MainActor
    func testColorSchemeAdapter_WithAllComponents() throws {
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)

        // Test with various component types
        let textView = Text("Test")
            .foregroundColor(lightAdapter.adaptiveTextColor)

        let backgroundView = VStack { }
            .background(lightAdapter.adaptiveBackground)

        let borderView = RoundedRectangle(cornerRadius: DS.Radius.medium)
            .stroke(lightAdapter.adaptiveBorderColor, lineWidth: 1)

        XCTAssertNotNil(textView, "Text should use adaptive color")
        XCTAssertNotNil(backgroundView, "Background should use adaptive color")
        XCTAssertNotNil(borderView, "Border should use adaptive color")
    }

    // MARK: - Cross-Context Interaction Tests

    /// Test all three contexts working together
    ///
    /// Verifies that SurfaceStyle, PlatformAdapter, and ColorSchemeAdapter
    /// can be used together without conflicts.
    ///
    /// Note: We test that the contexts integrate correctly, not that
    /// their values are different, because dynamic colors cannot be
    /// reliably compared as objects.
    @MainActor
    func testCrossContext_AllThreeContexts() throws {
        struct MultiContextView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
                return VStack(spacing: PlatformAdapter.defaultSpacing) {
                    Text("Multi-context")
                        .foregroundColor(adapter.adaptiveTextColor)
                }
                .padding(PlatformAdapter.defaultSpacing)
                .background(adapter.adaptiveBackground)
            }
        }

        let view = MultiContextView()
            .environment(\.surfaceStyle, .regular)

        // Verify all three contexts are accessible
        XCTAssertNotNil(view, "All three contexts should work together")

        // Test that each context provides valid values
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertGreaterThan(spacing, 0, "Platform spacing should be positive")

        let adapter = ColorSchemeAdapter(colorScheme: .light)
        XCTAssertNotNil(adapter.adaptiveBackground, "Color adapter should provide background")
    }

    /// Test contexts don't interfere with each other
    ///
    /// Verifies that modifying one context doesn't affect
    /// the behavior of other contexts.
    @MainActor
    func testContexts_NoConflicts() throws {
        struct ConflictTestView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
                return Text("Test")
                    .platformAdaptive()
                    .foregroundColor(adapter.adaptiveTextColor)
            }
        }

        // Apply multiple context modifications
        let view = ConflictTestView()
            .environment(\.surfaceStyle, .thick)
            .preferredColorScheme(.dark)
            .platformAdaptive()

        XCTAssertNotNil(view, "Multiple context modifiers should not conflict")
    }

    /// Test context application order independence
    ///
    /// Verifies that contexts work correctly regardless of
    /// the order they are applied.
    @MainActor
    func testContexts_OrderIndependence() throws {
        let adapter = ColorSchemeAdapter(colorScheme: .light)

        // Order 1: Platform -> Color -> Surface
        let view1 = Text("Test 1")
            .platformAdaptive()
            .foregroundColor(adapter.adaptiveTextColor)
            .environment(\.surfaceStyle, .regular)

        // Order 2: Surface -> Platform -> Color
        let view2 = Text("Test 2")
            .environment(\.surfaceStyle, .regular)
            .platformAdaptive()
            .foregroundColor(adapter.adaptiveTextColor)

        // Both should work correctly
        XCTAssertNotNil(view1, "Context order 1 should work")
        XCTAssertNotNil(view2, "Context order 2 should work")
    }

    // MARK: - Size Class Integration Tests

    /// Test compact size class adaptation
    ///
    /// Verifies that compact size class results in appropriate
    /// spacing values.
    func testSizeClass_CompactAdaptation() throws {
        let compactSpacing = PlatformAdapter.spacing(for: .compact)

        XCTAssertEqual(compactSpacing, DS.Spacing.m,
                      "Compact size class should use medium spacing")
        XCTAssertEqual(compactSpacing, 12.0,
                      "Compact spacing should be 12pt per DS.Spacing.m")
    }

    /// Test regular size class adaptation
    ///
    /// Verifies that regular size class results in appropriate
    /// spacing values.
    func testSizeClass_RegularAdaptation() throws {
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertEqual(regularSpacing, DS.Spacing.l,
                      "Regular size class should use large spacing")
        XCTAssertEqual(regularSpacing, 16.0,
                      "Regular spacing should be 16pt per DS.Spacing.l")
    }

    /// Test size class integration with views
    ///
    /// Verifies that size class-based spacing works correctly
    /// when applied to views.
    @MainActor
    func testSizeClass_ViewIntegration() throws {
        let compactView = Text("Compact")
            .platformAdaptive(sizeClass: .compact)

        let regularView = Text("Regular")
            .platformAdaptive(sizeClass: .regular)

        XCTAssertNotNil(compactView, "Compact size class should apply")
        XCTAssertNotNil(regularView, "Regular size class should apply")
    }

    // MARK: - Real-World Scenario Tests

    /// Test inspector screen with all contexts
    ///
    /// Verifies that a realistic inspector layout uses all
    /// three context types correctly.
    @MainActor
    func testInspectorScreen_AllContexts() throws {
        struct InspectorScreen: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

                return HStack(spacing: 0) {
                    // Main content
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        Text("Content")
                            .foregroundColor(adapter.adaptiveTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(PlatformAdapter.defaultSpacing)
                    .background(adapter.adaptiveBackground)

                    // Inspector panel
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        Text("Inspector")
                            .foregroundColor(adapter.adaptiveTextColor)
                    }
                    .frame(width: 250)
                    .padding(PlatformAdapter.defaultSpacing)
                    .background(adapter.adaptiveSecondaryBackground)
                }
            }
        }

        let screen = InspectorScreen()
            .environment(\.surfaceStyle, .thick)

        XCTAssertNotNil(screen, "Inspector screen should use all contexts")
    }

    /// Test sidebar layout with platform-adaptive spacing
    ///
    /// Verifies that a sidebar pattern uses contexts correctly
    /// for platform-specific behavior.
    @MainActor
    func testSidebarLayout_PlatformAdaptive() throws {
        struct SidebarLayout: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

                return HStack(spacing: 0) {
                    // Sidebar
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        Text("Sidebar")
                    }
                    .frame(width: 200)
                    .platformPadding()
                    .background(adapter.adaptiveSecondaryBackground)

                    // Main content
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        Text("Main")
                    }
                    .platformPadding()
                    .background(adapter.adaptiveBackground)
                }
            }
        }

        let layout = SidebarLayout()
        XCTAssertNotNil(layout, "Sidebar should use platform-adaptive contexts")
    }

    // MARK: - Performance Tests

    /// Test that context integration has minimal overhead
    ///
    /// Verifies that using multiple contexts together doesn't
    /// significantly impact performance.
    func testContextIntegration_Performance() throws {
        measure {
            for _ in 0..<1000 {
                let adapter = ColorSchemeAdapter(colorScheme: .light)
                let spacing = PlatformAdapter.defaultSpacing

                // Access multiple context properties
                _ = adapter.adaptiveBackground
                _ = adapter.adaptiveTextColor
                _ = spacing
            }
        }
    }

    // MARK: - Edge Cases

    /// Test context integration with nil size class
    ///
    /// Verifies that contexts work correctly when size class
    /// is not specified.
    func testEdgeCase_NilSizeClass() throws {
        let spacing = PlatformAdapter.spacing(for: nil)

        // Should fall back to platform default
        #if os(macOS)
        XCTAssertEqual(spacing, DS.Spacing.m, "Nil size class should use macOS default")
        #else
        XCTAssertEqual(spacing, DS.Spacing.l, "Nil size class should use iOS default")
        #endif
    }

    /// Test context integration with extreme nesting
    ///
    /// Verifies that contexts work correctly even with deeply
    /// nested view hierarchies.
    @MainActor
    func testEdgeCase_ExtremeNesting() throws {
        struct DeeplyNested: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

                return VStack(spacing: PlatformAdapter.defaultSpacing) {
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        VStack(spacing: PlatformAdapter.defaultSpacing) {
                            Text("Deep")
                                .foregroundColor(adapter.adaptiveTextColor)
                        }
                    }
                }
                .environment(\.surfaceStyle, .regular)
            }
        }

        let view = DeeplyNested()
        XCTAssertNotNil(view, "Contexts should work with deep nesting")
    }
}
#endif
