#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import XCTest
@testable import ISOInspectorApp
import ISOInspectorKit

@MainActor
final class ResearchLogAccessibilityIdentifierTests: XCTestCase {
    func testPreviewAppliesRootIdentifier() {
        let hosted = hostPreview(snapshot: ResearchLogPreviewProvider.validFixture())
        defer { hosted.window.isHidden = true }

        XCTAssertEqual(hosted.controller.view.accessibilityIdentifier, ResearchLogAccessibilityID.root)
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

        XCTAssertNotNil(diagnosticRow, "Expected to find diagnostic row with identifier \(identifier)")
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

        XCTAssertNotNil(statusView, "Expected missing fixture status view with identifier \(identifier)")
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

        XCTAssertNotNil(statusView, "Expected schema mismatch status view with identifier \(identifier)")
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
           elements.contains(where: { $0.accessibilityIdentifier == identifier }) {
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
        let controller: UIHostingController<ResearchLogAuditPreview>
        let window: UIWindow
    }
}
#endif
