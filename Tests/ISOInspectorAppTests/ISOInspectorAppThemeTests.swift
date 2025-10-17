import Foundation
import XCTest
@testable import ISOInspectorKit

final class ISOInspectorAppThemeTests: XCTestCase {
    func testAccentAssetMatchesBrandPalette() throws {
        let accentURL = URL(fileURLWithPath: "Sources/ISOInspectorApp/Resources/Assets.xcassets/AccentColor.colorset/Contents.json")
        let data = try Data(contentsOf: accentURL)
        let asset = try JSONDecoder().decode(ColorAsset.self, from: data)
        let palette = ISOInspectorBrandPalette.production

        let lightEntry = try XCTUnwrap(asset.colors.first { $0.appearances?.isEmpty ?? true })
        XCTAssertEqual(lightEntry.color.components.red, palette.lightModeAccent.red, accuracy: 0.005)
        XCTAssertEqual(lightEntry.color.components.green, palette.lightModeAccent.green, accuracy: 0.005)
        XCTAssertEqual(lightEntry.color.components.blue, palette.lightModeAccent.blue, accuracy: 0.005)

        let darkEntry = try XCTUnwrap(asset.colors.first { entry in
            entry.appearances?.contains(where: { $0.appearance == "luminosity" && $0.value == "dark" }) == true
        })
        XCTAssertEqual(darkEntry.color.components.red, palette.darkModeAccent.red, accuracy: 0.005)
        XCTAssertEqual(darkEntry.color.components.green, palette.darkModeAccent.green, accuracy: 0.005)
        XCTAssertEqual(darkEntry.color.components.blue, palette.darkModeAccent.blue, accuracy: 0.005)
    }
}

private struct ColorAsset: Decodable {
    let colors: [ColorEntry]
}

private struct ColorEntry: Decodable {
    let appearances: [Appearance]?
    let color: ColorValue
}

private struct Appearance: Decodable {
    let appearance: String
    let value: String
}

private struct ColorValue: Decodable {
    let components: Components
}

private struct Components: Decodable {
    let alpha: Double
    let blue: Double
    let green: Double
    let red: Double

    private enum CodingKeys: String, CodingKey {
        case alpha
        case blue
        case green
        case red
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alpha = try Self.parse(component: container.decode(String.self, forKey: .alpha))
        blue = try Self.parse(component: container.decode(String.self, forKey: .blue))
        green = try Self.parse(component: container.decode(String.self, forKey: .green))
        red = try Self.parse(component: container.decode(String.self, forKey: .red))
    }

    private static func parse(component: String) throws -> Double {
        guard let value = Double(component) else {
            throw NSError(domain: "ISOInspectorAppThemeTests", code: 0)
        }
        return value
    }
}
