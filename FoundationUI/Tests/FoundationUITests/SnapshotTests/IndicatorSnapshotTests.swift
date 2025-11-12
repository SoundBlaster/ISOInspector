#if canImport(SnapshotTesting) && !os(Linux)
    import XCTest
    import SwiftUI
    #if os(iOS) || os(tvOS)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif
    import SnapshotTesting
    @testable import FoundationUI

    /// Snapshot coverage for the Indicator component.
    ///
    /// Records visual baselines for all badge levels and size variants in
    /// both light and dark appearances. Executed on Apple platforms only.
    @MainActor
    final class IndicatorSnapshotTests: XCTestCase {

        func testIndicatorCatalogLightMode() {
            let view = indicatorCatalog()
                .padding(DS.Spacing.l)

            assertIndicatorSnapshot(view, testName: #function)
        }

        func testIndicatorCatalogDarkMode() {
            let view = indicatorCatalog()
                .padding(DS.Spacing.l)
                .preferredColorScheme(.dark)

            assertIndicatorSnapshot(view, testName: #function)
        }

        private func indicatorCatalog() -> some View {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                ForEach(Array(BadgeLevel.allCases.enumerated()), id: \.offset) { _, level in
                    HStack(spacing: DS.Spacing.m) {
                        ForEach(Array(Indicator.Size.allCases.enumerated()), id: \.offset) {
                            _, size in
                            Indicator(
                                level: level,
                                size: size,
                                reason: "Snapshot",
                                tooltip: .text("Snapshot")
                            )
                        }
                    }
                }
            }
        }

        private func assertIndicatorSnapshot(
            _ view: some View,
            testName: String,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            #if os(iOS) || os(tvOS)
                let config: ViewImageConfig = .iPhone13
                let controller = UIHostingController(rootView: view)
                guard let hostingView = controller.view else {
                    XCTFail("UIHostingController missing view hierarchy")
                    return
                }

                hostingView.frame = CGRect(
                    origin: .zero,
                    size: config.size ?? UIScreen.main.bounds.size
                )
                hostingView.layoutIfNeeded()

                assertSnapshot(
                    of: hostingView,
                    as: .image(layout: .device(config: config)),
                    file: file,
                    testName: testName,
                    line: line
                )
            #elseif os(macOS)
                let controller = NSHostingController(rootView: view)
                guard let hostingView = controller.view else {
                    XCTFail("NSHostingController missing view hierarchy")
                    return
                }

                hostingView.frame.size = hostingView.fittingSize
                hostingView.layoutSubtreeIfNeeded()

                assertSnapshot(
                    of: hostingView,
                    as: .image,
                    file: file,
                    testName: testName,
                    line: line
                )
            #else
                assertSnapshot(
                    of: view,
                    as: .image,
                    file: file,
                    testName: testName,
                    line: line
                )
            #endif
        }
    }
#endif
