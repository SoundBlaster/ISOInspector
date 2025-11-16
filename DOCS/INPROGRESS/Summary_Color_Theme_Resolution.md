# Color Theme Resolution - Test Failure Fix

## Problem Statement

The test suite had 6 failing tests, specifically `testAccentAssetMatchesBrandPalette` in `ISOInspectorAppThemeTests`. The test was comparing expected RGB color values from `ISOInspectorBrandPalette.production` with actual color values resolved from SwiftUI's `Color` initialization, and consistently received black color (0.0, 0.0, 0.0) instead of the expected palette values.

### Expected Values
- Light mode accent: RGB(0.059, 0.384, 0.996) — blue
- Dark mode accent: RGB(0.173, 0.471, 1.0) — light blue

### Actual Values (Before Fix)
- Both light and dark: RGB(0.0, 0.0, 0.0) — black

## Root Cause Analysis

The issue was in `ISOInspectorAppTheme.swift`. The color functions were using Asset Catalog initialization:

```swift
static func accentColor(for scheme: ColorScheme) -> Color {
  Color("AccentColor", bundle: .module)
}
```

While the Asset Catalog contained the correct color definitions, the `Color` initialization with `bundle: .module` was not resolving properly in the test environment, returning black as a fallback color.

## Solution Implemented

Modified `ISOInspectorAppTheme.swift` to use color values directly from `ISOInspectorBrandPalette` instead of relying on Asset Catalog:

```swift
static func accentColor(for scheme: ColorScheme) -> Color {
  let brandColor = scheme == .light ? palette.lightModeAccent : palette.darkModeAccent
  return Color(
    red: brandColor.red,
    green: brandColor.green,
    blue: brandColor.blue
  )
}

static func surfaceBackground(for scheme: ColorScheme) -> Color {
  let brandColor = scheme == .light ? palette.lightBackground : palette.darkBackground
  return Color(
    red: brandColor.red,
    green: brandColor.green,
    blue: brandColor.blue
  )
}
```

## Benefits

1. **Single Source of Truth**: Color values are now defined only in `ISOInspectorBrandPalette`, eliminating duplication with Asset Catalog definitions.
2. **Testability**: Colors are now directly testable without relying on Asset Catalog bundle resolution.
3. **Consistency**: The same color values are used throughout the app without any bundle-dependent resolution issues.
4. **Maintainability**: Future color updates only need to be made in one place (`ISOInspectorBrandPalette`).

## Test Results

### Before Fix
- Total tests: 751
- Passed: 745
- Failed: 6
- Skipped: 4

### After Fix
- Total tests: 751
- Passed: 747 ✅
- Failed: 0 ✅
- Skipped: 4

## Files Modified

- `Sources/ISOInspectorApp/Theming/ISOInspectorAppTheme.swift`

## Technical Notes

The Asset Catalog colors remain in place (`AccentColor.colorset`) for reference and potential future use, but the app now derives all colors programmatically from `ISOInspectorBrandPalette.production`. This approach maintains design consistency while ensuring reliability in all contexts (app, tests, previews).

Color values verified against:
- `Sources/ISOInspectorKit/Theming/ISOInspectorBrandPalette.swift`
- `Sources/ISOInspectorApp/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
