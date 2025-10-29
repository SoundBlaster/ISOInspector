import Foundation
import XCTest

@testable import ISOInspectorApp
@testable import ISOInspectorKit

#if canImport(SwiftUI)
    import SwiftUI
#endif

final class ISOInspectorAppThemeTests: XCTestCase {
    func testAccentAssetMatchesBrandPalette() throws {
        #if canImport(AppKit) && canImport(SwiftUI)
            let palette = ISOInspectorBrandPalette.production
            let lightAccent = NSColor(ISOInspectorAppTheme.accentColor(for: .light))

            let light = try lightAccent.rgbComponents(appearance: .aqua)
            XCTAssertEqual(light.red, palette.lightModeAccent.red, accuracy: 0.005)
            XCTAssertEqual(light.green, palette.lightModeAccent.green, accuracy: 0.005)
            XCTAssertEqual(light.blue, palette.lightModeAccent.blue, accuracy: 0.005)

            let darkAccent = NSColor(ISOInspectorAppTheme.accentColor(for: .dark))
            let dark = try darkAccent.rgbComponents(appearance: .darkAqua)
            XCTAssertEqual(dark.red, palette.darkModeAccent.red, accuracy: 0.005)
            XCTAssertEqual(dark.green, palette.darkModeAccent.green, accuracy: 0.005)
            XCTAssertEqual(dark.blue, palette.darkModeAccent.blue, accuracy: 0.005)
        #else
            throw XCTSkip("Accent asset validation requires AppKit.")
        #endif
    }
}

#if canImport(AppKit)
    import AppKit

    extension NSColor {
        fileprivate struct RGB {
            let red: Double
            let green: Double
            let blue: Double
        }

        fileprivate func rgbComponents(appearance: NSAppearance.Name) throws -> RGB {
            guard let resolvedAppearance = NSAppearance(named: appearance) else {
                throw NSError(domain: "ISOInspectorAppThemeTests", code: 1)
            }

            var resolved: NSColor?
            resolvedAppearance.performAsCurrentDrawingAppearance {
                resolved = self.usingColorSpace(.deviceRGB)
            }

            guard let rgb = resolved else {
                throw NSError(domain: "ISOInspectorAppThemeTests", code: 2)
            }

            return RGB(
                red: Double(rgb.redComponent),
                green: Double(rgb.greenComponent),
                blue: Double(rgb.blueComponent)
            )
        }
    }
#endif
