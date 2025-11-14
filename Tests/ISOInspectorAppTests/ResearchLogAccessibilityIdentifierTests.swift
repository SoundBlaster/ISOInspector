#if canImport(SwiftUI) && canImport(UIKit) && os(macOS)
    import SwiftUI
    import XCTest
    @testable import ISOInspectorApp
    import ISOInspectorKit

    /// Accessibility identifier tests for ResearchLog preview views.
    ///
    /// ## Important: These are UI Tests Disguised as Unit Tests
    ///
    /// **Current State:**
    /// - These tests create UIHostingController and UIWindow instances
    /// - They render full SwiftUI view hierarchies
    /// - They traverse rendered UIView trees to find accessibility identifiers
    /// - They only work on macOS (iOS rendering behaves differently)
    ///
    /// **Why This Is Problematic:**
    /// - **Not unit tests**: Unit tests should test view model logic without rendering
    /// - **Platform-specific**: Requires macOS guards, doesn't work on iOS
    /// - **Fragile**: Depends on SwiftUI → UIKit translation implementation details
    /// - **Slow**: Full rendering + layout + RunLoop overhead
    ///
    /// **Recommended Migration Path:**
    /// @todo #221 Migrate to proper XCUITest UI tests
    /// 1. Create a dedicated UITests target in Project.swift
    /// 2. Rewrite tests using XCUIApplication for proper UI testing
    /// 3. Benefits: Works on iOS/macOS, tests actual accessibility, more reliable
    ///
    /// **Alternative: Convert to View Model Unit Tests**
    /// See: DocumentViewModelTests.swift, ParseTreeOutlineViewModelTests.swift
    /// for examples of proper unit tests that don't render UI.
    @MainActor
    final class ResearchLogAccessibilityIdentifierTests: XCTestCase {
        func testPreviewAppliesRootIdentifier() {
            let hosted = hostPreview(snapshot: ResearchLogPreviewProvider.validFixture())
            defer { hosted.window.isHidden = true }

            XCTAssertEqual(
                hosted.controller.view.accessibilityIdentifier, ResearchLogAccessibilityID.root)
        }

        func testDiagnosticsReceiveNestedIdentifiers() {
            let hosted = hostPreview(snapshot: ResearchLogPreviewProvider.validFixture())
            defer { hosted.window.isHidden = true }

            let identifier = ResearchLogAccessibilityID.path(
                ResearchLogAccessibilityID.root,
                ResearchLogAccessibilityID.Diagnostics.root,
                ResearchLogAccessibilityID.Diagnostics.row(0)
            )
            let diagnosticRow = findView(in: hosted.controller.view, withIdentifier: identifier)

            XCTAssertNotNil(
                diagnosticRow, "Expected to find diagnostic row with identifier \(identifier)")
        }

        func testMissingFixtureStatusAppliesNestedIdentifier() {
            let hosted = hostPreview(snapshot: ResearchLogPreviewProvider.missingFixture())
            defer { hosted.window.isHidden = true }

            let identifier = ResearchLogAccessibilityID.path(
                ResearchLogAccessibilityID.root,
                ResearchLogAccessibilityID.Header.root,
                ResearchLogAccessibilityID.Header.Status.root,
                ResearchLogAccessibilityID.Header.Status.missingFixture
            )

            let statusView = findView(in: hosted.controller.view, withIdentifier: identifier)

            XCTAssertNotNil(
                statusView, "Expected missing fixture status view with identifier \(identifier)")
        }

        func testSchemaMismatchStatusAppliesNestedIdentifier() {
            let hosted = hostPreview(snapshot: ResearchLogPreviewProvider.schemaMismatchFixture())
            defer { hosted.window.isHidden = true }

            let identifier = ResearchLogAccessibilityID.path(
                ResearchLogAccessibilityID.root,
                ResearchLogAccessibilityID.Header.root,
                ResearchLogAccessibilityID.Header.Status.root,
                ResearchLogAccessibilityID.Header.Status.schemaMismatch
            )

            let statusView = findView(in: hosted.controller.view, withIdentifier: identifier)

            XCTAssertNotNil(
                statusView, "Expected schema mismatch status view with identifier \(identifier)")
        }

        // MARK: - Helpers

        private func hostPreview(snapshot: ResearchLogPreviewSnapshot) -> HostedPreview {
            let hostedView = ResearchLogAuditPreview(snapshot: snapshot)
                .frame(width: 480, height: 320)

            let controller = UIHostingController(rootView: hostedView)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()

            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

            return HostedPreview(controller: controller, window: window)
        }

        private func findView(in root: UIView, withIdentifier identifier: String) -> UIView? {
            if root.accessibilityIdentifier == identifier {
                return root
            }
            if let elements = root.accessibilityElements as? [UIAccessibilityIdentification],
                elements.contains(where: { $0.accessibilityIdentifier == identifier })
            {
                return root
            }
            for subview in root.subviews {
                if let match = findView(in: subview, withIdentifier: identifier) {
                    return match
                }
            }
            return nil
        }

        private struct HostedPreview {
            let controller: UIViewController
            let window: UIWindow
        }
    }
#endif
