import XCTest
@testable import ISOInspectorKit

final class ISOInspectorBrandPaletteTests: XCTestCase {
    func testLightModeAccentContrast() {
        let palette = ISOInspectorBrandPalette.production
        let contrast = palette.lightModeAccent.contrastRatio(against: palette.lightBackground)
        XCTAssertGreaterThanOrEqual(contrast, 4.5, "Light mode accent should meet WCAG AA contrast against light background")
    }

    func testDarkModeAccentContrast() {
        let palette = ISOInspectorBrandPalette.production
        let contrast = palette.darkModeAccent.contrastRatio(against: palette.darkBackground)
        XCTAssertGreaterThanOrEqual(contrast, 4.5, "Dark mode accent should meet WCAG AA contrast against dark background")
    }
}
