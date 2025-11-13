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
                assertSnapshot(
                    of: renderImage(for: view, scale: targetDisplayScale),
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

        private var targetDisplayScale: CGFloat {
            #if os(macOS)
                return max(NSScreen.main?.backingScaleFactor ?? 2.0, 2.0)
            #elseif os(iOS) || os(tvOS)
                return UIScreen.main.scale
            #else
                return 1.0
            #endif
        }

        #if os(macOS)
            private func renderImage<V: View>(for view: V, scale: CGFloat) -> NSImage {
                let hostingView = NSHostingView(rootView: view)
                hostingView.frame.size = hostingView.fittingSize
                hostingView.layoutSubtreeIfNeeded()
                hostingView.wantsLayer = true
                hostingView.layer?.contentsScale = scale

                let size = hostingView.bounds.size
                let pixelWidth = Int(size.width * scale)
                let pixelHeight = Int(size.height * scale)

                guard
                    let context = CGContext(
                        data: nil,
                        width: max(pixelWidth, 1),
                        height: max(pixelHeight, 1),
                        bitsPerComponent: 8,
                        bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    )
                else {
                    fatalError("Unable to allocate CGContext for snapshot.")
                }

                context.scaleBy(x: scale, y: scale)
                hostingView.layer?.render(in: context)

                guard let cgImage = context.makeImage() else {
                    fatalError("Unable to capture snapshot image.")
                }

                let image = NSImage(size: size)
                image.addRepresentation(NSBitmapImageRep(cgImage: cgImage))
                return image
            }
        #endif
    }
#endif
