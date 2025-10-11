#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import XCTest
@testable import ISOInspectorApp

@MainActor
final class ParseTreeAccessibilityIdentifierTests: XCTestCase {
    func testExplorerAppliesRootIdentifier() {
        let store = ParseTreeStore()
        let annotations = AnnotationBookmarkSession(store: nil)
        let view = ParseTreeExplorerView(store: store, annotations: annotations)
            .frame(width: 1024, height: 768)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        XCTAssertEqual(controller.view.accessibilityIdentifier, ParseTreeAccessibilityID.root)
    }

    func testExplorerSearchFieldReceivesNestedIdentifier() {
        let store = ParseTreeStore()
        let annotations = AnnotationBookmarkSession(store: nil)
        let view = ParseTreeExplorerView(store: store, annotations: annotations)
            .frame(width: 1024, height: 768)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        let identifier = ParseTreeAccessibilityID.Outline.Filters.searchField
        let searchField = findView(in: controller.view, withIdentifier: identifier)

        XCTAssertNotNil(searchField, "Expected to find search field with identifier \(identifier)")
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
