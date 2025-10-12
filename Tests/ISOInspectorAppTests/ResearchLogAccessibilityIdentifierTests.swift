#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import XCTest
@testable import ISOInspectorApp
import ISOInspectorKit

@MainActor
final class ResearchLogAccessibilityIdentifierTests: XCTestCase {
    func testPreviewAppliesRootIdentifier() {
        let snapshot = ResearchLogPreviewProvider.validFixture()
        let view = ResearchLogAuditPreview(snapshot: snapshot)
            .frame(width: 480, height: 320)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        XCTAssertEqual(controller.view.accessibilityIdentifier, ResearchLogAccessibilityID.root)
    }

    func testDiagnosticsReceiveNestedIdentifiers() {
        let snapshot = ResearchLogPreviewProvider.validFixture()
        let view = ResearchLogAuditPreview(snapshot: snapshot)
            .frame(width: 480, height: 320)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let identifier = ResearchLogAccessibilityID.path(
            ResearchLogAccessibilityID.root,
            ResearchLogAccessibilityID.Diagnostics.root,
            ResearchLogAccessibilityID.Diagnostics.row(0)
        )
        let diagnosticRow = findView(in: controller.view, withIdentifier: identifier)

        XCTAssertNotNil(diagnosticRow, "Expected to find diagnostic row with identifier \(identifier)")
    }

    // MARK: - Helpers

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
}
#endif
