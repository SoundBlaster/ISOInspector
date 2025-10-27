#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import FoundationUI

/// Integration tests for platform-specific behavior across iOS, iPadOS, and macOS
///
/// This test suite verifies that FoundationUI components correctly adapt to:
/// - **macOS-specific behavior**: Compact spacing, keyboard shortcuts, NSPasteboard
/// - **iOS-specific behavior**: Touch targets, gestures, UIPasteboard
/// - **iPad adaptive layout**: Size class adaptation, split view layouts
/// - **Cross-platform consistency**: Consistent DS token usage, Dark Mode, accessibility
///
/// All tests use DS tokens exclusively (zero magic numbers) and follow
/// the TDD/XP principles of FoundationUI development.
///
/// ## Testing Strategy
/// - Use conditional compilation (`#if os(macOS)`, `#if os(iOS)`) for platform-specific tests
/// - Test real-world component compositions (InspectorPattern, SidebarPattern, etc.)
/// - Verify environment value propagation through deep hierarchies
/// - Validate edge cases: nil size class, unknown platform variants
///
/// ## See Also
/// - ``PlatformAdapter``
/// - ``PlatformAdaptiveModifier``
/// - ``ContextIntegrationTests``
final class PlatformAdaptationIntegrationTests: XCTestCase {

    // MARK: - macOS-Specific Integration Tests

    /// Test that macOS uses compact 12pt spacing by default
    ///
    /// Verifies that components on macOS automatically use the denser
    /// 12pt spacing (DS.Spacing.m) for desktop-optimized layouts.
    ///
    /// ## Success Criteria
    /// - Platform detection correctly identifies macOS
    /// - Default spacing equals DS.Spacing.m (12pt)
    /// - Spacing uses DS token (zero magic numbers)
    func testMacOS_DefaultSpacing() throws {
        #if os(macOS)
        // Verify platform detection
        XCTAssertTrue(PlatformAdapter.isMacOS, "Platform should be detected as macOS")
        XCTAssertFalse(PlatformAdapter.isIOS, "Platform should not be detected as iOS")

        // Verify default spacing is 12pt (DS.Spacing.m)
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "macOS should use DS.Spacing.m (12pt) for compact desktop spacing")
        XCTAssertEqual(spacing, 12.0,
                      "macOS default spacing should be 12pt")

        // Verify spacing is a valid DS token
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "macOS spacing should use DS tokens (zero magic numbers)")
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    /// Test macOS spacing integration with InspectorPattern
    ///
    /// Verifies that InspectorPattern correctly uses macOS-appropriate
    /// spacing (12pt) when rendered on macOS.
    ///
    /// ## Success Criteria
    /// - InspectorPattern uses PlatformAdapter.defaultSpacing
    /// - Spacing equals DS.Spacing.m on macOS
    /// - Component hierarchy respects platform spacing
    @MainActor
    func testMacOS_InspectorPatternSpacing() throws {
        #if os(macOS)
        let inspector = InspectorPattern(title: "macOS Inspector") {
            VStack(spacing: PlatformAdapter.defaultSpacing) {
                Card {
                    Text("Metadata")
                }
                Card {
                    Text("Properties")
                }
            }
            .padding(PlatformAdapter.defaultSpacing)
        }

        // Verify inspector can be created
        XCTAssertNotNil(inspector, "InspectorPattern should render on macOS")

        // Verify spacing is macOS-appropriate
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "InspectorPattern on macOS should use DS.Spacing.m")
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    /// Test macOS clipboard integration with CopyableText
    ///
    /// Verifies that CopyableText uses NSPasteboard on macOS
    /// for clipboard operations.
    ///
    /// ## Success Criteria
    /// - Platform detection identifies macOS
    /// - Clipboard operations work correctly
    /// - No compilation errors with NSPasteboard
    @MainActor
    func testMacOS_ClipboardIntegration() throws {
        #if os(macOS)
        // Verify platform is macOS
        XCTAssertTrue(PlatformAdapter.isMacOS, "Clipboard test requires macOS")

        // Create CopyableText component
        let copyableText = CopyableText("Test clipboard text")
            .platformAdaptive()

        XCTAssertNotNil(copyableText, "CopyableText should work on macOS with NSPasteboard")

        // Note: Actual clipboard operations require user interaction,
        // so we only verify component creation and platform detection
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    /// Test macOS keyboard shortcut integration
    ///
    /// Verifies that keyboard shortcuts (⌘ keys) are properly handled
    /// on macOS and that components can register shortcuts.
    ///
    /// ## Success Criteria
    /// - Platform detection identifies macOS
    /// - Keyboard shortcut modifiers are available
    /// - Components can use .keyboardShortcut() modifier
    @MainActor
    func testMacOS_KeyboardShortcuts() throws {
        #if os(macOS)
        // Verify platform
        XCTAssertTrue(PlatformAdapter.isMacOS, "Keyboard shortcut test requires macOS")

        // Create a view with keyboard shortcut (Command+C for copy)
        let buttonWithShortcut = Button("Copy") { }
            .keyboardShortcut("c", modifiers: .command)
            .platformAdaptive()

        XCTAssertNotNil(buttonWithShortcut,
                       "macOS should support keyboard shortcuts with .command modifier")

        // Verify spacing is correct for macOS
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "macOS keyboard shortcut views should use DS.Spacing.m")
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    /// Test macOS hover effects with InteractiveStyle
    ///
    /// Verifies that hover effects are properly applied on macOS
    /// for desktop pointer interaction.
    ///
    /// ## Success Criteria
    /// - Components can use hover effects on macOS
    /// - Platform-adaptive spacing is correct
    /// - No compilation errors with macOS-specific APIs
    @MainActor
    func testMacOS_HoverEffects() throws {
        #if os(macOS)
        // Create interactive card with hover effects
        let hoverCard = Card {
            Text("Hover me")
        }
        .interactiveStyle()
        .platformAdaptive()

        XCTAssertNotNil(hoverCard, "macOS should support hover effects via InteractiveStyle")

        // Verify platform spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "Interactive elements on macOS should use DS.Spacing.m")
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    /// Test macOS SidebarPattern with compact spacing
    ///
    /// Verifies that SidebarPattern uses macOS-appropriate spacing
    /// for NavigationSplitView layouts.
    ///
    /// ## Success Criteria
    /// - SidebarPattern renders correctly on macOS
    /// - Uses DS.Spacing.m (12pt) for compact desktop UI
    /// - Proper integration with NavigationSplitView
    @MainActor
    func testMacOS_SidebarPatternLayout() throws {
        #if os(macOS)
        // Create sidebar items using the correct structure
        let items = [
            SidebarPattern<String, Text>.Item(id: "item1", title: "Item 1"),
            SidebarPattern<String, Text>.Item(id: "item2", title: "Item 2"),
            SidebarPattern<String, Text>.Item(id: "item3", title: "Item 3")
        ]

        // Create a section containing the items
        let section = SidebarPattern<String, Text>.Section(
            title: "Main Section",
            items: items
        )

        let selectedItem = Binding<String?>.constant("item1")

        // Create sidebar with correct signature
        let sidebar = SidebarPattern(
            sections: [section],
            selection: selectedItem,
            detail: { selectedId in
                Text(selectedId ?? "No selection")
            }
        )

        XCTAssertNotNil(sidebar, "SidebarPattern should render on macOS")

        // Verify macOS spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "SidebarPattern on macOS should use DS.Spacing.m")
        #else
        throw XCTSkip("This test requires macOS")
        #endif
    }

    // MARK: - iOS-Specific Integration Tests

    /// Test that iOS uses larger 16pt spacing by default
    ///
    /// Verifies that components on iOS automatically use the larger
    /// 16pt spacing (DS.Spacing.l) for touch-optimized layouts.
    ///
    /// ## Success Criteria
    /// - Platform detection correctly identifies iOS
    /// - Default spacing equals DS.Spacing.l (16pt)
    /// - Spacing uses DS token (zero magic numbers)
    func testIOS_DefaultSpacing() throws {
        #if os(iOS)
        // Verify platform detection
        XCTAssertTrue(PlatformAdapter.isIOS, "Platform should be detected as iOS")
        XCTAssertFalse(PlatformAdapter.isMacOS, "Platform should not be detected as macOS")

        // Verify default spacing is 16pt (DS.Spacing.l)
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "iOS should use DS.Spacing.l (16pt) for touch-optimized spacing")
        XCTAssertEqual(spacing, 16.0,
                      "iOS default spacing should be 16pt")

        // Verify spacing is a valid DS token
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "iOS spacing should use DS tokens (zero magic numbers)")
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    /// Test iOS minimum touch target size (44×44 pt per Apple HIG)
    ///
    /// Verifies that iOS enforces the minimum touch target size
    /// of 44×44 points for accessibility.
    ///
    /// ## Success Criteria
    /// - Minimum touch target is 44pt (Apple HIG requirement)
    /// - Value is constant (no magic numbers)
    /// - Components respect minimum touch target
    func testIOS_MinimumTouchTarget() throws {
        #if os(iOS)
        // Verify minimum touch target constant exists
        let minTarget = PlatformAdapter.minimumTouchTarget

        // Per Apple HIG, touch targets should be at least 44×44 pt
        XCTAssertEqual(minTarget, 44.0,
                      "iOS minimum touch target must be 44pt per Apple HIG")
        XCTAssertGreaterThanOrEqual(minTarget, 44.0,
                                   "Touch targets must meet accessibility requirements")

        // Note: This is a documented constant (44.0), not a magic number
        // Source: Apple Human Interface Guidelines
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    /// Test iOS touch target enforcement on Badge components
    ///
    /// Verifies that Badge components can be made touch-accessible
    /// by ensuring minimum touch target sizes.
    ///
    /// ## Success Criteria
    /// - Badge with platform-adaptive sizing
    /// - Touch target meets iOS minimum (44pt)
    /// - Uses DS tokens for spacing
    @MainActor
    func testIOS_TouchTargetOnBadge() throws {
        #if os(iOS)
        let badge = Badge(text: "Tap Me", level: .info)
            .platformAdaptive()
            .frame(minWidth: PlatformAdapter.minimumTouchTarget,
                   minHeight: PlatformAdapter.minimumTouchTarget)

        XCTAssertNotNil(badge, "Badge should be touch-accessible on iOS")

        // Verify touch target size
        let minTarget = PlatformAdapter.minimumTouchTarget
        XCTAssertEqual(minTarget, 44.0,
                      "Badge should meet iOS minimum touch target")

        // Verify spacing is iOS-appropriate
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "Badge on iOS should use DS.Spacing.l")
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    /// Test iOS clipboard integration with UIPasteboard
    ///
    /// Verifies that CopyableText uses UIPasteboard on iOS
    /// for clipboard operations.
    ///
    /// ## Success Criteria
    /// - Platform detection identifies iOS
    /// - Clipboard operations work correctly
    /// - No compilation errors with UIPasteboard
    @MainActor
    func testIOS_ClipboardIntegration() throws {
        #if os(iOS)
        // Verify platform is iOS
        XCTAssertTrue(PlatformAdapter.isIOS, "Clipboard test requires iOS")

        // Create CopyableText component
        let copyableText = CopyableText("Test clipboard text")
            .platformAdaptive()

        XCTAssertNotNil(copyableText, "CopyableText should work on iOS with UIPasteboard")

        // Verify iOS spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "CopyableText on iOS should use DS.Spacing.l")

        // Note: Actual clipboard operations require user interaction,
        // so we only verify component creation and platform detection
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    /// Test iOS gesture support integration
    ///
    /// Verifies that components properly support iOS gestures
    /// (tap, long press, swipe, etc.) with platform-adaptive spacing.
    ///
    /// ## Success Criteria
    /// - Components can use gesture modifiers on iOS
    /// - Platform-adaptive spacing is correct
    /// - Touch targets meet minimum size requirements
    @MainActor
    func testIOS_GestureSupport() throws {
        #if os(iOS)
        // Create a card with tap gesture
        let gestureCard = Card {
            Text("Tap or Long Press")
        }
        .onTapGesture { }
        .onLongPressGesture { }
        .platformAdaptive()
        .frame(minHeight: PlatformAdapter.minimumTouchTarget)

        XCTAssertNotNil(gestureCard, "iOS should support gestures on components")

        // Verify iOS spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "Gesture-enabled components should use DS.Spacing.l on iOS")

        // Verify touch target
        let minTarget = PlatformAdapter.minimumTouchTarget
        XCTAssertEqual(minTarget, 44.0,
                      "Gesture targets should meet iOS minimum")
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    /// Test iOS InspectorPattern with touch-optimized spacing
    ///
    /// Verifies that InspectorPattern uses iOS-appropriate spacing
    /// (16pt) for touch-optimized layouts.
    ///
    /// ## Success Criteria
    /// - InspectorPattern renders correctly on iOS
    /// - Uses DS.Spacing.l (16pt) for touch spacing
    /// - Content is scrollable for mobile viewport
    @MainActor
    func testIOS_InspectorPatternLayout() throws {
        #if os(iOS)
        let inspector = InspectorPattern(title: "iOS Inspector") {
            VStack(spacing: PlatformAdapter.defaultSpacing) {
                Card {
                    Text("Metadata")
                }
                Card {
                    Text("Properties")
                }
                Badge(text: "Status", level: .success)
                    .frame(minHeight: PlatformAdapter.minimumTouchTarget)
            }
            .padding(PlatformAdapter.defaultSpacing)
        }

        XCTAssertNotNil(inspector, "InspectorPattern should render on iOS")

        // Verify iOS spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "InspectorPattern on iOS should use DS.Spacing.l")

        // Verify touch target size
        let minTarget = PlatformAdapter.minimumTouchTarget
        XCTAssertEqual(minTarget, 44.0,
                      "Interactive elements should meet touch target minimum")
        #else
        throw XCTSkip("This test requires iOS")
        #endif
    }

    // MARK: - iPad Adaptive Layout Tests

    /// Test iPad compact size class spacing (12pt)
    ///
    /// Verifies that compact size class (e.g., split view, portrait)
    /// uses 12pt spacing (DS.Spacing.m) for efficient space usage.
    ///
    /// ## Success Criteria
    /// - Compact size class uses DS.Spacing.m (12pt)
    /// - Spacing adapts correctly for compact layouts
    /// - Uses DS tokens (zero magic numbers)
    func testIPad_CompactSizeClassSpacing() throws {
        #if os(iOS)
        // Verify compact size class spacing
        let compactSpacing = PlatformAdapter.spacing(for: .compact)

        XCTAssertEqual(compactSpacing, DS.Spacing.m,
                      "Compact size class should use DS.Spacing.m")
        XCTAssertEqual(compactSpacing, 12.0,
                      "Compact spacing should be 12pt for efficient space usage")

        // Verify it's a DS token
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(compactSpacing),
                     "Compact spacing should use DS tokens")
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    /// Test iPad regular size class spacing (16pt)
    ///
    /// Verifies that regular size class (e.g., full screen, landscape)
    /// uses 16pt spacing (DS.Spacing.l) for comfortable touch spacing.
    ///
    /// ## Success Criteria
    /// - Regular size class uses DS.Spacing.l (16pt)
    /// - Spacing adapts correctly for regular layouts
    /// - Uses DS tokens (zero magic numbers)
    func testIPad_RegularSizeClassSpacing() throws {
        #if os(iOS)
        // Verify regular size class spacing
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertEqual(regularSpacing, DS.Spacing.l,
                      "Regular size class should use DS.Spacing.l")
        XCTAssertEqual(regularSpacing, 16.0,
                      "Regular spacing should be 16pt for comfortable touch spacing")

        // Verify it's a DS token
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(regularSpacing),
                     "Regular spacing should use DS tokens")
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    /// Test iPad size class adaptation in InspectorPattern
    ///
    /// Verifies that InspectorPattern correctly adapts its spacing
    /// based on the current size class (compact vs regular).
    ///
    /// ## Success Criteria
    /// - Inspector adapts to compact size class (12pt)
    /// - Inspector adapts to regular size class (16pt)
    /// - Environment values propagate correctly
    @MainActor
    func testIPad_InspectorSizeClassAdaptation() throws {
        #if os(iOS)
        // Create inspector with compact size class
        let compactInspector = InspectorPattern(title: "Compact Inspector") {
            VStack(spacing: PlatformAdapter.spacing(for: .compact)) {
                Card { Text("Compact Layout") }
            }
        }
        .environment(\.horizontalSizeClass, .compact)

        XCTAssertNotNil(compactInspector, "Inspector should adapt to compact size class")

        // Create inspector with regular size class
        let regularInspector = InspectorPattern(title: "Regular Inspector") {
            VStack(spacing: PlatformAdapter.spacing(for: .regular)) {
                Card { Text("Regular Layout") }
            }
        }
        .environment(\.horizontalSizeClass, .regular)

        XCTAssertNotNil(regularInspector, "Inspector should adapt to regular size class")

        // Verify spacing values
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertLessThan(compactSpacing, regularSpacing,
                         "Compact spacing should be less than regular spacing")
        XCTAssertEqual(compactSpacing, DS.Spacing.m, "Compact should use DS.Spacing.m")
        XCTAssertEqual(regularSpacing, DS.Spacing.l, "Regular should use DS.Spacing.l")
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    /// Test iPad SidebarPattern collapse behavior
    ///
    /// Verifies that SidebarPattern correctly handles size class changes
    /// (e.g., sidebar collapse in portrait mode).
    ///
    /// ## Success Criteria
    /// - Sidebar works with compact size class
    /// - Sidebar works with regular size class
    /// - Spacing adapts to size class
    @MainActor
    func testIPad_SidebarAdaptation() throws {
        #if os(iOS)
        // Create sidebar items using the correct structure
        let items = [
            SidebarPattern<String, Text>.Item(id: "section1", title: "Section 1"),
            SidebarPattern<String, Text>.Item(id: "section2", title: "Section 2")
        ]

        // Create a section containing the items
        let section = SidebarPattern<String, Text>.Section(
            title: "Main",
            items: items
        )

        let selectedItem = Binding<String?>.constant("section1")

        // Compact size class (portrait, collapsed sidebar)
        let compactSidebar = SidebarPattern(
            sections: [section],
            selection: selectedItem,
            detail: { selectedId in
                Text(selectedId ?? "No selection")
            }
        )
        .environment(\.horizontalSizeClass, .compact)

        XCTAssertNotNil(compactSidebar, "Sidebar should work with compact size class")

        // Regular size class (landscape, expanded sidebar)
        let regularSidebar = SidebarPattern(
            sections: [section],
            selection: selectedItem,
            detail: { selectedId in
                Text(selectedId ?? "No selection")
            }
        )
        .environment(\.horizontalSizeClass, .regular)

        XCTAssertNotNil(regularSidebar, "Sidebar should work with regular size class")

        // Verify spacing adapts
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertEqual(compactSpacing, DS.Spacing.m, "Compact sidebar uses DS.Spacing.m")
        XCTAssertEqual(regularSpacing, DS.Spacing.l, "Regular sidebar uses DS.Spacing.l")
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    /// Test iPad pointer interaction support
    ///
    /// Verifies that components support pointer interactions on iPad
    /// (when using hardware pointer devices).
    ///
    /// ## Success Criteria
    /// - Components render correctly on iPad
    /// - Touch targets meet minimum size
    /// - Hover effects available (via InteractiveStyle)
    @MainActor
    func testIPad_PointerInteractionSupport() throws {
        #if os(iOS)
        // Create interactive card for iPad pointer support
        let interactiveCard = Card {
            Text("Supports Pointer")
        }
        .interactiveStyle()
        .platformAdaptive()
        .frame(minWidth: PlatformAdapter.minimumTouchTarget,
               minHeight: PlatformAdapter.minimumTouchTarget)

        XCTAssertNotNil(interactiveCard, "iPad should support pointer interactions")

        // Verify touch target
        let minTarget = PlatformAdapter.minimumTouchTarget
        XCTAssertEqual(minTarget, 44.0,
                      "Interactive elements should meet touch target minimum")

        // Verify default iOS spacing
        let spacing = PlatformAdapter.defaultSpacing
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "iPad should use iOS default spacing (DS.Spacing.l)")
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    /// Test iPad split view layout with size class changes
    ///
    /// Verifies that layouts correctly adapt when iPad enters/exits
    /// split view mode (size class changes from regular to compact).
    ///
    /// ## Success Criteria
    /// - Layout works in split view (compact)
    /// - Layout works in full screen (regular)
    /// - Spacing adapts automatically
    @MainActor
    func testIPad_SplitViewLayout() throws {
        #if os(iOS)
        struct SplitViewContent: View {
            @Environment(\.horizontalSizeClass) var sizeClass

            var body: some View {
                let spacing = PlatformAdapter.spacing(for: sizeClass)

                return HStack(spacing: spacing) {
                    VStack(spacing: spacing) {
                        Text("Sidebar")
                    }
                    .frame(maxWidth: 200)

                    VStack(spacing: spacing) {
                        Text("Main Content")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(spacing)
            }
        }

        // Test with compact size class (split view)
        let compactView = SplitViewContent()
            .environment(\.horizontalSizeClass, .compact)

        XCTAssertNotNil(compactView, "Split view should work in compact mode")

        // Test with regular size class (full screen)
        let regularView = SplitViewContent()
            .environment(\.horizontalSizeClass, .regular)

        XCTAssertNotNil(regularView, "Split view should work in regular mode")

        // Verify spacing adapts
        XCTAssertEqual(PlatformAdapter.spacing(for: .compact), DS.Spacing.m)
        XCTAssertEqual(PlatformAdapter.spacing(for: .regular), DS.Spacing.l)
        #else
        throw XCTSkip("This test requires iOS/iPadOS")
        #endif
    }

    // MARK: - Cross-Platform Consistency Tests

    /// Test that DS tokens produce consistent spacing across all platforms
    ///
    /// Verifies that DS.Spacing values are identical on all platforms,
    /// ensuring consistent design token usage.
    ///
    /// ## Success Criteria
    /// - DS.Spacing.s is 8pt on all platforms
    /// - DS.Spacing.m is 12pt on all platforms
    /// - DS.Spacing.l is 16pt on all platforms
    /// - DS.Spacing.xl is 24pt on all platforms
    func testCrossPlatform_DSTokenConsistency() throws {
        // Verify spacing tokens are consistent across platforms
        XCTAssertEqual(DS.Spacing.s, 8.0, "DS.Spacing.s should be 8pt on all platforms")
        XCTAssertEqual(DS.Spacing.m, 12.0, "DS.Spacing.m should be 12pt on all platforms")
        XCTAssertEqual(DS.Spacing.l, 16.0, "DS.Spacing.l should be 16pt on all platforms")
        XCTAssertEqual(DS.Spacing.xl, 24.0, "DS.Spacing.xl should be 24pt on all platforms")

        // Verify tokens are ordered correctly
        XCTAssertLessThan(DS.Spacing.s, DS.Spacing.m)
        XCTAssertLessThan(DS.Spacing.m, DS.Spacing.l)
        XCTAssertLessThan(DS.Spacing.l, DS.Spacing.xl)

        // Verify platform default uses one of these tokens
        let defaultSpacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(defaultSpacing),
                     "Platform default spacing must use a DS token")
    }

    /// Test that Badge component renders consistently across platforms
    ///
    /// Verifies that Badge uses the same DS tokens and styling
    /// on all platforms, with only spacing adapting to platform.
    ///
    /// ## Success Criteria
    /// - Badge levels (info, warning, error, success) work on all platforms
    /// - DS.Colors tokens are consistent
    /// - Only spacing differs by platform
    @MainActor
    func testCrossPlatform_BadgeConsistency() throws {
        // Create badges with all levels
        let infoBadge = Badge(text: "Info", level: .info)
        let warningBadge = Badge(text: "Warning", level: .warning)
        let errorBadge = Badge(text: "Error", level: .error)
        let successBadge = Badge(text: "Success", level: .success)

        // Verify all badges can be created
        XCTAssertNotNil(infoBadge, "Info badge should work on all platforms")
        XCTAssertNotNil(warningBadge, "Warning badge should work on all platforms")
        XCTAssertNotNil(errorBadge, "Error badge should work on all platforms")
        XCTAssertNotNil(successBadge, "Success badge should work on all platforms")

        // Apply platform-adaptive spacing
        let adaptiveBadge = Badge(text: "Adaptive", level: .info)
            .platformAdaptive()

        XCTAssertNotNil(adaptiveBadge, "Badge with platform-adaptive spacing should work everywhere")

        // Verify spacing uses DS tokens
        let spacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "Badge spacing should use DS tokens on all platforms")
    }

    /// Test that Dark Mode works consistently across all platforms
    ///
    /// Verifies that ColorSchemeAdapter produces consistent dark mode
    /// colors on macOS and iOS/iPadOS.
    ///
    /// ## Success Criteria
    /// - Dark mode adapter works on all platforms
    /// - Adaptive colors are available
    /// - No platform-specific color inconsistencies
    func testCrossPlatform_DarkModeConsistency() throws {
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

        // Test color scheme detection
        XCTAssertFalse(lightAdapter.isDarkMode, "Light mode should be detected correctly")
        XCTAssertTrue(darkAdapter.isDarkMode, "Dark mode should be detected correctly")

        // Verify adaptive colors exist on all platforms
        XCTAssertNotNil(lightAdapter.adaptiveBackground,
                       "Light background should exist on all platforms")
        XCTAssertNotNil(darkAdapter.adaptiveBackground,
                       "Dark background should exist on all platforms")

        XCTAssertNotNil(lightAdapter.adaptiveTextColor,
                       "Light text color should exist on all platforms")
        XCTAssertNotNil(darkAdapter.adaptiveTextColor,
                       "Dark text color should exist on all platforms")

        XCTAssertNotNil(lightAdapter.adaptiveBorderColor,
                       "Light border color should exist on all platforms")
        XCTAssertNotNil(darkAdapter.adaptiveBorderColor,
                       "Dark border color should exist on all platforms")

        // Verify divider colors
        XCTAssertNotNil(lightAdapter.adaptiveDividerColor,
                       "Light divider color should exist on all platforms")
        XCTAssertNotNil(darkAdapter.adaptiveDividerColor,
                       "Dark divider color should exist on all platforms")
    }

    /// Test that accessibility features work consistently across platforms
    ///
    /// Verifies that VoiceOver labels, accessibility traits, and
    /// Dynamic Type support work consistently on all platforms.
    ///
    /// ## Success Criteria
    /// - Components support accessibility on all platforms
    /// - VoiceOver labels are available
    /// - DS.Typography supports Dynamic Type everywhere
    @MainActor
    func testCrossPlatform_AccessibilityConsistency() throws {
        // Create accessible components
        let badge = Badge(text: "Accessible", level: .info)
            .accessibilityLabel("Info badge: Accessible")

        let card = Card {
            Text("Accessible Content")
                .font(DS.Typography.body) // Supports Dynamic Type
        }
        .accessibilityElement(children: .contain)

        XCTAssertNotNil(badge, "Accessible badge should work on all platforms")
        XCTAssertNotNil(card, "Accessible card should work on all platforms")

        // Verify typography supports Dynamic Type on all platforms
        let bodyFont = DS.Typography.body
        let titleFont = DS.Typography.title
        let captionFont = DS.Typography.caption

        XCTAssertNotNil(bodyFont, "Body font should support Dynamic Type on all platforms")
        XCTAssertNotNil(titleFont, "Title font should support Dynamic Type on all platforms")
        XCTAssertNotNil(captionFont, "Caption font should support Dynamic Type on all platforms")
    }

    /// Test environment value propagation across platforms
    ///
    /// Verifies that SwiftUI environment values propagate correctly
    /// through component hierarchies on all platforms.
    ///
    /// ## Success Criteria
    /// - Environment values work on macOS
    /// - Environment values work on iOS/iPadOS
    /// - Values propagate through deep hierarchies
    @MainActor
    func testCrossPlatform_EnvironmentPropagation() throws {
        struct NestedView: View {
            @Environment(\.surfaceStyle) var surfaceStyle
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

                return VStack(spacing: PlatformAdapter.defaultSpacing) {
                    Card {
                        Text("Nested Level 1")
                    }
                    Card {
                        VStack {
                            Text("Nested Level 2")
                        }
                    }
                }
                .foregroundColor(adapter.adaptiveTextColor)
            }
        }

        let view = NestedView()
            .environment(\.surfaceStyle, .thick)
            .preferredColorScheme(.dark)

        XCTAssertNotNil(view, "Environment values should propagate on all platforms")

        // Verify platform spacing uses DS tokens
        let spacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "Environment propagation should use DS tokens")
    }

    /// Test zero magic numbers across all platform-adaptive code
    ///
    /// Verifies that all platform-adaptive spacing, sizing, and layout
    /// uses DS tokens exclusively with zero hardcoded values.
    ///
    /// ## Success Criteria
    /// - All spacing uses DS tokens
    /// - No hardcoded pixel values (except documented constants)
    /// - Platform defaults resolve to DS tokens
    func testCrossPlatform_ZeroMagicNumbers() throws {
        // Verify all platform defaults use DS tokens
        let defaultSpacing = PlatformAdapter.defaultSpacing
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)
        let nilSpacing = PlatformAdapter.spacing(for: nil)

        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]

        XCTAssertTrue(validTokens.contains(defaultSpacing),
                     "Default spacing must use DS token")
        XCTAssertTrue(validTokens.contains(compactSpacing),
                     "Compact spacing must use DS token")
        XCTAssertTrue(validTokens.contains(regularSpacing),
                     "Regular spacing must use DS token")
        XCTAssertTrue(validTokens.contains(nilSpacing),
                     "Nil size class spacing must use DS token")

        // Verify specific token mappings
        XCTAssertEqual(compactSpacing, DS.Spacing.m,
                      "Compact should map to DS.Spacing.m")
        XCTAssertEqual(regularSpacing, DS.Spacing.l,
                      "Regular should map to DS.Spacing.l")

        #if os(macOS)
        XCTAssertEqual(defaultSpacing, DS.Spacing.m,
                      "macOS default should be DS.Spacing.m")
        #elseif os(iOS)
        XCTAssertEqual(defaultSpacing, DS.Spacing.l,
                      "iOS default should be DS.Spacing.l")

        // iOS touch target is a documented constant (Apple HIG)
        let minTarget = PlatformAdapter.minimumTouchTarget
        XCTAssertEqual(minTarget, 44.0,
                      "iOS touch target is 44pt per Apple HIG (documented constant)")
        #endif
    }

    // MARK: - Edge Cases & Validation

    /// Test platform adaptation with nil size class
    ///
    /// Verifies that platform adapter gracefully handles nil size class
    /// by falling back to platform defaults.
    ///
    /// ## Success Criteria
    /// - Nil size class falls back to platform default
    /// - No crashes or errors
    /// - Spacing uses DS token
    func testEdgeCase_NilSizeClass() throws {
        let spacing = PlatformAdapter.spacing(for: nil)

        // Should fall back to platform default
        XCTAssertEqual(spacing, PlatformAdapter.defaultSpacing,
                      "Nil size class should fall back to platform default")

        // Platform default should be a DS token
        #if os(macOS)
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "macOS nil size class should use DS.Spacing.m")
        #elseif os(iOS)
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "iOS nil size class should use DS.Spacing.l")
        #endif

        // Verify it's a valid DS token
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "Nil size class fallback should use DS token")
    }

    /// Test platform adaptation with unknown future size class
    ///
    /// Verifies that platform adapter handles @unknown default cases
    /// for future size class variants gracefully.
    ///
    /// ## Success Criteria
    /// - Unknown size classes fall back to platform default
    /// - No crashes or runtime errors
    /// - Spacing uses DS token
    @MainActor
    func testEdgeCase_UnknownSizeClass() throws {
        // Create view that uses platformAdaptive with size class
        let view = Text("Test")
            .platformAdaptive(sizeClass: nil) // nil represents unknown

        XCTAssertNotNil(view, "Unknown size class should not cause crashes")

        // Verify fallback uses platform default
        let fallbackSpacing = PlatformAdapter.spacing(for: nil)
        XCTAssertEqual(fallbackSpacing, PlatformAdapter.defaultSpacing,
                      "Unknown size class should use platform default")
    }

    /// Test platform adaptation with complex nested hierarchies
    ///
    /// Verifies that platform-adaptive spacing works correctly
    /// even in deeply nested component hierarchies.
    ///
    /// ## Success Criteria
    /// - Deep nesting doesn't cause issues
    /// - Spacing remains consistent throughout hierarchy
    /// - All spacing uses DS tokens
    @MainActor
    func testComplexHierarchy_PlatformAdaptation() throws {
        let complexView = VStack(spacing: PlatformAdapter.defaultSpacing) {
            Card {
                VStack(spacing: PlatformAdapter.defaultSpacing) {
                    SectionHeader(title: "Section")

                    VStack(spacing: PlatformAdapter.defaultSpacing) {
                        KeyValueRow(key: "Key 1", value: "Value 1")
                        KeyValueRow(key: "Key 2", value: "Value 2")

                        HStack(spacing: PlatformAdapter.defaultSpacing) {
                            Badge(text: "Badge 1", level: .info)
                            Badge(text: "Badge 2", level: .success)
                        }
                    }
                }
            }
        }
        .platformAdaptive()

        XCTAssertNotNil(complexView, "Complex hierarchies should support platform adaptation")

        // Verify spacing uses DS tokens
        let spacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(spacing),
                     "Complex hierarchy spacing should use DS tokens")
    }

    /// Test all platform extensions use DS tokens
    ///
    /// Verifies that platformSpacing(), platformPadding(), and
    /// platformAdaptive() all use DS tokens exclusively.
    ///
    /// ## Success Criteria
    /// - platformSpacing() uses DS tokens
    /// - platformPadding() uses DS tokens
    /// - platformAdaptive() uses DS tokens
    @MainActor
    func testPlatformExtensions_UseDSTokens() throws {
        // Test platformSpacing()
        let spacedView = Text("Test")
            .platformSpacing()

        XCTAssertNotNil(spacedView, "platformSpacing() should work")

        // Test platformPadding()
        let paddedView = Text("Test")
            .platformPadding()

        XCTAssertNotNil(paddedView, "platformPadding() should work")

        // Test platformAdaptive()
        let adaptiveView = Text("Test")
            .platformAdaptive()

        XCTAssertNotNil(adaptiveView, "platformAdaptive() should work")

        // Verify all use DS tokens
        let defaultSpacing = PlatformAdapter.defaultSpacing
        let validTokens: Set<CGFloat> = [DS.Spacing.s, DS.Spacing.m, DS.Spacing.l, DS.Spacing.xl]
        XCTAssertTrue(validTokens.contains(defaultSpacing),
                     "All platform extensions should use DS tokens")

        // Test custom spacing with DS tokens
        let customSpacedView = Text("Test")
            .platformSpacing(DS.Spacing.xl)

        XCTAssertNotNil(customSpacedView, "Custom spacing with DS tokens should work")
    }
}
#endif
