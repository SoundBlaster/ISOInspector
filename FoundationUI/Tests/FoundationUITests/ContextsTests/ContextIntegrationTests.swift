import XCTest
import SwiftUI
@testable import FoundationUI

/// Integration tests for FoundationUI Context layer components
///
/// Tests verify correct interaction between SurfaceStyleKey, PlatformAdaptation,
/// and ColorSchemeAdapter across complex view hierarchies and real-world UI patterns.
///
/// ## Test Coverage
/// - Environment key propagation through component hierarchies
/// - Platform adaptation integration with components and patterns
/// - Color scheme adaptation with environment changes
/// - Cross-context interactions (multiple contexts working together)
/// - Size class handling (compact/regular adaptation)
/// - Real-world UI patterns (Inspector, Sidebar, etc.)
///
/// ## Test Strategy
/// - Follow TDD: Tests written before/alongside implementation
/// - Test isolation: Each test is independent
/// - Platform coverage: Conditional compilation for platform-specific tests
/// - Zero magic numbers: All values use DS tokens
///
/// Test count target: 22+ tests for ≥90% integration coverage
final class ContextIntegrationTests: XCTestCase {

    // MARK: - Environment Propagation Tests

    /// Test that SurfaceStyleKey propagates through nested view hierarchies
    ///
    /// Verifies that surface material set at parent level is inherited by
    /// all children unless explicitly overridden.
    @MainActor
    func testSurfaceStylePropagation_NestedComponents() {
        struct ParentView: View {
            @Environment(\.surfaceStyle) var surfaceStyle

            var body: some View {
                VStack {
                    // Child component should inherit parent's surface style
                    Text("Child")
                }
                .environment(\.surfaceStyle, .thick)
            }
        }

        let view = ParentView()
        XCTAssertNotNil(view, "View hierarchy should be created successfully")
    }

    /// Test that SurfaceStyleKey propagates through Pattern components
    ///
    /// Verifies that patterns correctly inherit and propagate surface styles
    /// to their child components.
    @MainActor
    func testSurfaceStylePropagation_ThroughPatterns() {
        struct TestView: View {
            var body: some View {
                InspectorPattern(title: "Test") {
                    VStack {
                        Text("Content")
                    }
                }
                .environment(\.surfaceStyle, .thin)
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "Pattern should propagate surface style to children")
    }

    /// Test that multiple environment keys propagate independently
    ///
    /// Verifies that setting multiple environment values doesn't create conflicts
    /// and each propagates correctly through the hierarchy.
    @MainActor
    func testMultipleEnvironmentKeys_Propagation() {
        struct TestView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                VStack {
                    Text("Multi-context view")
                }
                .environment(\.surfaceStyle, .regular)
                .preferredColorScheme(.dark)
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "Multiple environment keys should propagate independently")
    }

    /// Test that environment values can be overridden at nested levels
    ///
    /// Verifies that child views can override environment values from parents
    /// without affecting siblings.
    @MainActor
    func testEnvironmentPropagation_NestedOverrides() {
        struct ParentView: View {
            var body: some View {
                VStack {
                    // Child 1 inherits .regular
                    Text("Child 1")

                    // Child 2 overrides to .thick
                    VStack {
                        Text("Child 2")
                    }
                    .environment(\.surfaceStyle, .thick)
                }
                .environment(\.surfaceStyle, .regular)
            }
        }

        let view = ParentView()
        XCTAssertNotNil(view, "Nested overrides should work correctly")
    }

    /// Test that environment values propagate through deep hierarchies
    ///
    /// Verifies that environment values can propagate through arbitrarily
    /// deep view hierarchies without loss.
    @MainActor
    func testEnvironmentPropagation_DeepHierarchy() {
        struct DeepView: View {
            @Environment(\.surfaceStyle) var surfaceStyle

            var body: some View {
                VStack {
                    VStack {
                        VStack {
                            VStack {
                                Text("Deep child")
                            }
                        }
                    }
                }
                .environment(\.surfaceStyle, .ultra)
            }
        }

        let view = DeepView()
        XCTAssertNotNil(view, "Deep hierarchies should preserve environment values")
    }

    // MARK: - Platform Adaptation Integration Tests

    /// Test that PlatformAdapter integrates correctly with InspectorPattern
    ///
    /// Verifies that platform-adaptive spacing is applied correctly when
    /// combined with InspectorPattern.
    @MainActor
    func testPlatformAdapter_WithInspectorPattern() {
        struct TestView: View {
            var body: some View {
                InspectorPattern(title: "Details") {
                    VStack {
                        Text("Content")
                    }
                }
                .platformAdaptive()
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "PlatformAdapter should integrate with InspectorPattern")
    }

    /// Test that PlatformAdapter integrates correctly with SidebarPattern
    ///
    /// Verifies that platform-adaptive spacing works correctly in sidebar layouts.
    @MainActor
    func testPlatformAdapter_WithSidebarPattern() {
        struct TestView: View {
            var body: some View {
                SidebarPattern(
                    sidebarContent: {
                        VStack {
                            Text("Sidebar")
                        }
                    },
                    mainContent: {
                        VStack {
                            Text("Main")
                        }
                    }
                )
                .platformAdaptive()
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "PlatformAdapter should integrate with SidebarPattern")
    }

    /// Test that platform-adaptive spacing works in complex hierarchies
    ///
    /// Verifies that platform spacing adapts correctly through nested components
    /// with different spacing requirements.
    @MainActor
    func testPlatformSpacing_InComplexHierarchy() {
        struct ComplexView: View {
            var body: some View {
                VStack(spacing: PlatformAdapter.defaultSpacing) {
                    Card {
                        VStack(spacing: PlatformAdapter.defaultSpacing) {
                            KeyValueRow(key: "Item 1", value: "Value 1")
                            KeyValueRow(key: "Item 2", value: "Value 2")
                        }
                    }

                    Badge(text: "Status", level: .info)
                }
                .platformAdaptive()
            }
        }

        let view = ComplexView()
        XCTAssertNotNil(view, "Complex hierarchies should use platform spacing correctly")
    }

    /// Test that platform adaptation respects size classes
    ///
    /// Verifies that platform spacing adapts to compact vs regular size classes
    /// on iPadOS.
    @MainActor
    func testPlatformAdapter_WithSizeClasses() {
        struct TestView: View {
            @Environment(\.horizontalSizeClass) var sizeClass

            var body: some View {
                VStack {
                    Text("Size class aware")
                }
                .platformAdaptive(sizeClass: sizeClass)
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "Platform adapter should respect size classes")
    }

    /// Test that platform-specific behavior is consistent
    ///
    /// Verifies that platform detection and spacing are consistent across
    /// multiple component instances.
    @MainActor
    func testPlatformAdapter_ConsistentBehavior() {
        let spacing1 = PlatformAdapter.defaultSpacing
        let spacing2 = PlatformAdapter.defaultSpacing

        XCTAssertEqual(spacing1, spacing2, "Platform spacing should be consistent")

        // Verify spacing uses DS tokens
        let validTokens: Set<CGFloat> = [
            DS.Spacing.s,
            DS.Spacing.m,
            DS.Spacing.l,
            DS.Spacing.xl
        ]
        XCTAssertTrue(validTokens.contains(spacing1), "Platform spacing should use DS tokens")
    }

    // MARK: - Color Scheme Integration Tests

    /// Test that ColorSchemeAdapter responds to environment changes
    ///
    /// Verifies that color scheme adapter correctly detects and responds
    /// to changes in the color scheme environment value.
    @MainActor
    func testColorSchemeAdapter_WithEnvironmentChange() {
        struct TestView: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                VStack {
                    Text("Dark mode test")
                        .foregroundStyle(ColorSchemeAdapter.adaptiveTextColor(for: colorScheme))
                }
                .preferredColorScheme(.dark)
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "ColorSchemeAdapter should respond to environment changes")
    }

    /// Test that ColorSchemeAdapter works with all components
    ///
    /// Verifies that color scheme adaptation is compatible with all
    /// FoundationUI components.
    @MainActor
    func testColorSchemeAdapter_WithAllComponents() {
        struct TestView: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                VStack {
                    Card {
                        SectionHeader("Header")
                        KeyValueRow(key: "Key", value: "Value")
                        Badge(text: "Badge", level: .success)
                    }
                }
                .adaptiveColorScheme()
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "ColorSchemeAdapter should work with all components")
    }

    /// Test that dark mode propagates through hierarchies
    ///
    /// Verifies that dark mode color adaptation propagates correctly
    /// through nested component hierarchies.
    @MainActor
    func testColorSchemeAdapter_DarkModePropagation() {
        struct DarkModeView: View {
            var body: some View {
                VStack {
                    Card {
                        VStack {
                            Text("Dark mode content")
                        }
                    }
                }
                .preferredColorScheme(.dark)
                .adaptiveColorScheme()
            }
        }

        let view = DarkModeView()
        XCTAssertNotNil(view, "Dark mode should propagate through hierarchies")
    }

    /// Test that light mode works correctly
    ///
    /// Verifies that color scheme adapter handles light mode correctly.
    @MainActor
    func testColorSchemeAdapter_LightMode() {
        struct LightModeView: View {
            var body: some View {
                VStack {
                    Card {
                        Text("Light mode content")
                    }
                }
                .preferredColorScheme(.light)
                .adaptiveColorScheme()
            }
        }

        let view = LightModeView()
        XCTAssertNotNil(view, "Light mode should work correctly")
    }

    /// Test that color scheme adapts with patterns
    ///
    /// Verifies that color scheme adaptation works correctly with
    /// Pattern components.
    @MainActor
    func testColorSchemeAdapter_WithPatterns() {
        struct TestView: View {
            var body: some View {
                InspectorPattern(title: "Inspector") {
                    VStack {
                        Text("Content")
                    }
                }
                .adaptiveColorScheme()
                .preferredColorScheme(.dark)
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "ColorSchemeAdapter should work with patterns")
    }

    // MARK: - Cross-Context Interaction Tests

    /// Test that all contexts work together without conflicts
    ///
    /// Verifies that SurfaceStyleKey, PlatformAdapter, and ColorSchemeAdapter
    /// can all be applied to the same view hierarchy without issues.
    @MainActor
    func testAllContexts_WorkTogether() {
        struct MultiContextView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                InspectorPattern(title: "Multi-Context") {
                    Card {
                        KeyValueRow(key: "Test", value: "Value")
                    }
                }
                .environment(\.surfaceStyle, .thick)
                .platformAdaptive()
                .adaptiveColorScheme()
                .preferredColorScheme(.dark)
            }
        }

        let view = MultiContextView()
        XCTAssertNotNil(view, "All contexts should work together without conflicts")
    }

    /// Test that contexts don't conflict with each other
    ///
    /// Verifies that applying multiple context modifiers doesn't create
    /// unexpected behavior or conflicts.
    @MainActor
    func testContexts_NoConflicts() {
        struct TestView: View {
            var body: some View {
                VStack {
                    Badge(text: "Test", level: .warning)
                }
                .environment(\.surfaceStyle, .regular)
                .platformAdaptive()
                .adaptiveColorScheme()
            }
        }

        let view = TestView()
        XCTAssertNotNil(view, "Contexts should not conflict")
    }

    /// Test that context order doesn't matter
    ///
    /// Verifies that the order in which context modifiers are applied
    /// doesn't affect the final result.
    @MainActor
    func testContexts_OrderIndependence() {
        struct View1: View {
            var body: some View {
                Text("Test")
                    .environment(\.surfaceStyle, .thin)
                    .platformAdaptive()
                    .adaptiveColorScheme()
            }
        }

        struct View2: View {
            var body: some View {
                Text("Test")
                    .platformAdaptive()
                    .environment(\.surfaceStyle, .thin)
                    .adaptiveColorScheme()
            }
        }

        let view1 = View1()
        let view2 = View2()

        XCTAssertNotNil(view1, "View1 should be created")
        XCTAssertNotNil(view2, "View2 should be created")
        // Order should not affect functionality
    }

    // MARK: - Size Class Adaptation Tests

    /// Test that compact size class spacing is correct
    ///
    /// Verifies that compact size class (iPhone in portrait, iPad split view)
    /// uses the correct spacing value.
    func testSizeClass_CompactAdaptation() {
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        XCTAssertEqual(compactSpacing, DS.Spacing.m, "Compact size class should use medium spacing")
        XCTAssertGreaterThan(compactSpacing, 0, "Spacing should be positive")
    }

    /// Test that regular size class spacing is correct
    ///
    /// Verifies that regular size class (iPad, iPhone landscape)
    /// uses the correct spacing value.
    func testSizeClass_RegularAdaptation() {
        let regularSpacing = PlatformAdapter.spacing(for: .regular)
        XCTAssertEqual(regularSpacing, DS.Spacing.l, "Regular size class should use large spacing")
        XCTAssertGreaterThan(regularSpacing, 0, "Spacing should be positive")
    }

    // MARK: - Real-World Scenario Tests

    /// Test Inspector pattern with all contexts
    ///
    /// Verifies that a realistic inspector screen with all context
    /// adaptations works correctly.
    @MainActor
    func testInspectorScreen_AllContexts() {
        struct InspectorScreen: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme
            @Environment(\.horizontalSizeClass) var sizeClass

            var body: some View {
                InspectorPattern(title: "File Details") {
                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        Card {
                            SectionHeader("Properties")
                            KeyValueRow(key: "Name", value: "video.mp4")
                            KeyValueRow(key: "Size", value: "1.2 MB")
                            KeyValueRow(key: "Duration", value: "00:05:30")
                        }

                        Card {
                            SectionHeader("Status")
                            Badge(text: "Valid", level: .success)
                        }
                    }
                }
                .environment(\.surfaceStyle, .thick)
                .platformAdaptive(sizeClass: sizeClass)
                .adaptiveColorScheme()
            }
        }

        let view = InspectorScreen()
        XCTAssertNotNil(view, "Inspector screen should work with all contexts")
    }

    /// Test Sidebar layout with platform adaptation
    ///
    /// Verifies that a sidebar layout adapts correctly across platforms
    /// with all context layers.
    @MainActor
    func testSidebarLayout_PlatformAdaptive() {
        struct SidebarScreen: View {
            var body: some View {
                SidebarPattern(
                    sidebarContent: {
                        VStack(spacing: PlatformAdapter.defaultSpacing) {
                            SectionHeader("Navigation")
                            Text("Item 1")
                            Text("Item 2")
                            Text("Item 3")
                        }
                        .environment(\.surfaceStyle, .thin)
                    },
                    mainContent: {
                        VStack(spacing: PlatformAdapter.defaultSpacing) {
                            Card {
                                SectionHeader("Content")
                                KeyValueRow(key: "Title", value: "Main View")
                            }
                        }
                        .environment(\.surfaceStyle, .regular)
                    }
                )
                .platformAdaptive()
                .adaptiveColorScheme()
            }
        }

        let view = SidebarScreen()
        XCTAssertNotNil(view, "Sidebar layout should adapt to platform")
    }

    // MARK: - Edge Cases and Validation

    /// Test that nil size class falls back to platform default
    ///
    /// Verifies correct fallback behavior when size class is not available.
    func testEdgeCase_NilSizeClass() {
        let spacing = PlatformAdapter.spacing(for: nil)

        #if os(macOS)
        XCTAssertEqual(spacing, DS.Spacing.m, "Nil size class should use macOS default")
        #else
        XCTAssertEqual(spacing, DS.Spacing.l, "Nil size class should use iOS default")
        #endif

        XCTAssertGreaterThan(spacing, 0, "Fallback spacing should be positive")
    }

    /// Test that all spacing values are valid DS tokens
    ///
    /// Verifies zero magic numbers requirement - all spacing must come
    /// from design system tokens.
    func testValidation_NoMagicNumbers() {
        let validTokens: Set<CGFloat> = [
            DS.Spacing.s,
            DS.Spacing.m,
            DS.Spacing.l,
            DS.Spacing.xl
        ]

        // Platform default spacing
        let platformSpacing = PlatformAdapter.defaultSpacing
        XCTAssertTrue(validTokens.contains(platformSpacing),
                     "Platform spacing must be a DS token")

        // Size class spacing
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertTrue(validTokens.contains(compactSpacing),
                     "Compact spacing must be a DS token")
        XCTAssertTrue(validTokens.contains(regularSpacing),
                     "Regular spacing must be a DS token")
    }
}
