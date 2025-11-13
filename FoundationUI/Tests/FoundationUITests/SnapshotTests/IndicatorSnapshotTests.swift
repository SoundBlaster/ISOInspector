#if canImport(SnapshotTesting) && !os(Linux)
    import Foundation
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
            #if os(macOS)
                let controller = NSHostingController(rootView: view)
                controller.view.frame.size = controller.view.fittingSize
                enforceRetinaScaleIfPossible(on: controller.view)

                assertSnapshot(
                    of: controller,
                    as: .image,
                    named: snapshotPlatformName,
                    record: shouldRecordSnapshots,
                    file: file,
                    testName: testName,
                    line: line
                )
            #else
                let traitCollection = UITraitCollection(displayScale: targetDisplayScale)

                assertSnapshot(
                    of: view,
                    as: .image(layout: .sizeThatFits, traits: traitCollection),
                    named: snapshotPlatformName,
                    record: shouldRecordSnapshots,
                    file: file,
                    testName: testName,
                    line: line
                )
            #endif
        }

        private var snapshotPlatformName: String {
            #if os(macOS)
                return "macOS"
            #elseif os(tvOS)
                return "tvOS"
            #elseif os(iOS)
                #if targetEnvironment(macCatalyst)
                    return "macCatalyst"
                #else
                    switch UIDevice.current.userInterfaceIdiom {
                    case .pad:
                        return "iPadOS"
                    case .phone:
                        return "iOS"
                    case .mac:
                        return "macCatalyst"
                    case .tv:
                        return "tvOS"
                    case .carPlay:
                        return "carPlay"
                    default:
                        return "iOS"
                    }
                #endif
            #else
                return "unknown"
            #endif
        }

        private var shouldRecordSnapshots: Bool {
            ProcessInfo.processInfo.environment["SNAPSHOT_RECORDING"] == "1"
        }

        #if os(macOS)
            private func enforceRetinaScaleIfPossible(on view: NSView) {
                view.wantsLayer = true
                guard let layer = view.layer else { return }
                layer.contentsScale = targetDisplayScale
                layer.rasterizationScale = targetDisplayScale
            }
        #endif

        private var targetDisplayScale: CGFloat {
            #if os(macOS)
                return NSScreen.main?.backingScaleFactor ?? 2.0
            #elseif os(iOS) || os(tvOS)
                return UIScreen.main.scale
            #else
                return 1.0
            #endif
        }
    }
#endif
