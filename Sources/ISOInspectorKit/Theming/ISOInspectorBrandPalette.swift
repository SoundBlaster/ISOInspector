import Foundation

public struct ISOInspectorBrandPalette: Sendable {
  public struct BrandColor: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public static func sRGB(red: Double, green: Double, blue: Double) -> BrandColor {
      BrandColor(red: red, green: green, blue: blue)
    }

    public func contrastRatio(against other: BrandColor) -> Double {
      let luminanceSelf = relativeLuminance()
      let luminanceOther = other.relativeLuminance()
      let brighter = max(luminanceSelf, luminanceOther)
      let darker = min(luminanceSelf, luminanceOther)
      return (brighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance() -> Double {
      func transform(_ channel: Double) -> Double {
        if channel <= 0.03928 {
          return channel / 12.92
        } else {
          return pow((channel + 0.055) / 1.055, 2.4)
        }
      }
      let r = transform(red)
      let g = transform(green)
      let b = transform(blue)
      return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
  }

  public let lightModeAccent: BrandColor
  public let darkModeAccent: BrandColor
  public let lightBackground: BrandColor
  public let darkBackground: BrandColor

  public static let production = ISOInspectorBrandPalette(
    lightModeAccent: .sRGB(red: 15.0 / 255.0, green: 98.0 / 255.0, blue: 254.0 / 255.0),
    darkModeAccent: .sRGB(red: 44.0 / 255.0, green: 120.0 / 255.0, blue: 1.0),
    lightBackground: .sRGB(red: 243.0 / 255.0, green: 246.0 / 255.0, blue: 251.0 / 255.0),
    darkBackground: .sRGB(red: 13.0 / 255.0, green: 20.0 / 255.0, blue: 31.0 / 255.0)
  )
}
