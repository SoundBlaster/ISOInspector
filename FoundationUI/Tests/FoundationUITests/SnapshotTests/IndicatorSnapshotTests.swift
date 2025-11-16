#if canImport(SnapshotTesting) && !os(Linux)
  import Foundation
  import SwiftUI
  import XCTest
  #if os(iOS) || os(tvOS)
    import UIKit
  #elseif os(macOS)
    import AppKit
  #endif
  @testable import FoundationUI
  import SnapshotTesting

  /// Snapshot coverage for the Indicator component.
  ///
  /// Records visual baselines for all badge levels and size variants in
  /// both light and dark appearances. Executed on Apple platforms only.
  ///
  /// Note: macOS snapshot tests are disabled due to rendering inconsistencies
  /// between local machines and CI headless virtual machines (different display
  /// scales, font rendering, and color profiles).
  @MainActor
  final class IndicatorSnapshotTests: XCTestCase {
    func testIndicatorCatalogLightMode() throws {
      #if os(macOS)
        throw XCTSkip("macOS snapshot tests disabled due to CI rendering inconsistencies")
      #else
        let view = indicatorCatalog()
          .padding(DS.Spacing.l)

        assertIndicatorSnapshot(view, testName: #function)
      #endif
    }

    func testIndicatorCatalogDarkMode() throws {
      #if os(macOS)
        throw XCTSkip("macOS snapshot tests disabled due to CI rendering inconsistencies")
      #else
        let view = indicatorCatalog()
          .padding(DS.Spacing.l)
          .preferredColorScheme(.dark)

        assertIndicatorSnapshot(view, testName: #function)
      #endif
    }

    func testIndicatorSingleLightMode() throws {
      #if os(macOS)
        throw XCTSkip("macOS snapshot tests disabled due to CI rendering inconsistencies")
      #else
        let view = Indicator(
          level: .warning,
          size: .medium,
          reason: "Preview",
          tooltip: .text("Preview")
        )
        .padding(DS.Spacing.l)

        assertIndicatorSnapshot(view, testName: #function)
      #endif
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
        let renderResult = renderImage(for: view, scale: targetDisplayScale)
        logSnapshotMetadata(
          platformName: snapshotPlatformName,
          viewSize: renderResult.viewSize,
          pixelWidth: renderResult.pixelWidth,
          pixelHeight: renderResult.pixelHeight,
          scale: renderResult.scale,
          colorSpace: renderResult.colorSpaceDescription,
          screenScale: NSScreen.main?.backingScaleFactor
        )

        assertSnapshot(
          of: renderResult.image,
          as: .image,
          named: snapshotPlatformName,
          record: shouldRecordSnapshots,
          file: file,
          testName: testName,
          line: line
        )
      #else
        let traitCollection = UITraitCollection(displayScale: targetDisplayScale)
        logSnapshotMetadata(
          platformName: snapshotPlatformName,
          viewSize: nil,
          pixelWidth: nil,
          pixelHeight: nil,
          scale: traitCollection.displayScale,
          colorSpace: "UIKit default",
          screenScale: traitCollection.displayScale
        )

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
      private struct SnapshotRenderResult {
        let image: NSImage
        let viewSize: CGSize
        let pixelWidth: Int
        let pixelHeight: Int
        let scale: CGFloat
        let colorSpaceDescription: String
      }

      private func renderImage(for view: some View, scale: CGFloat) -> SnapshotRenderResult {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame.size = hostingView.fittingSize
        hostingView.layoutSubtreeIfNeeded()
        hostingView.wantsLayer = true
        hostingView.layer?.contentsScale = scale

        let size = hostingView.bounds.size
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)

        let colorSpace =
          CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let colorSpaceName = (colorSpace.name as String?) ?? "Device RGB"

        guard
          let context = CGContext(
            data: nil,
            width: max(pixelWidth, 1),
            height: max(pixelHeight, 1),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
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

        let representation = NSBitmapImageRep(cgImage: cgImage)
        representation.size = size
        let image = NSImage(size: size)
        image.addRepresentation(representation)
        return SnapshotRenderResult(
          image: image,
          viewSize: size,
          pixelWidth: pixelWidth,
          pixelHeight: pixelHeight,
          scale: scale,
          colorSpaceDescription: colorSpaceName
        )
      }
    #endif

    private func logSnapshotMetadata(
      platformName: String,
      viewSize: CGSize?,
      pixelWidth: Int?,
      pixelHeight: Int?,
      scale: CGFloat,
      colorSpace: String,
      screenScale: CGFloat?
    ) {
      #if canImport(XCTest)
        XCTContext.runActivity(named: "Snapshot context (\(platformName))") { activity in
          var lines: [String] = []
          if let size = viewSize {
            lines.append(
              String(format: "View size: %.2fx%.2fpt", size.width, size.height))
          }
          if let px = pixelWidth, let py = pixelHeight {
            lines.append("Pixel size: \(px)x\(py)")
          }
          lines.append(String(format: "Target scale: %.2f", scale))
          if let screenScale {
            lines.append(String(format: "Screen scale: %.2f", screenScale))
          }
          lines.append("Color space: \(colorSpace)")
          let env = ProcessInfo.processInfo.environment
          lines.append("SNAPSHOT_RECORDING=\(env["SNAPSHOT_RECORDING"] ?? "0")")
          lines.append("CI=\(env["CI"] ?? "nil")")
          lines.append("Host=\(ProcessInfo.processInfo.hostName)")
          let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
          attachment.name = "Snapshot metadata"
          activity.add(attachment)
          print(lines)
        }
      #endif
    }
  }
#endif
