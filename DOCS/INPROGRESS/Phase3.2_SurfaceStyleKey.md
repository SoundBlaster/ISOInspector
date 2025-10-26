# Phase 3.2: Implement SurfaceStyleKey Environment Key

## 🎯 Objective

Implement a SwiftUI EnvironmentKey for Material backgrounds to enable environment-based surface styling throughout the FoundationUI component hierarchy.

## 🧩 Context

- **Phase**: 3.2 Layer 4: Contexts & Platform Adaptation
- **Layer**: Layer 4 (Contexts)
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ Design Tokens (DS namespace) - Phase 1.2 complete
  - ✅ View Modifiers (SurfaceStyle) - Phase 2.1 complete
  - ✅ Components - Phase 2.2 complete
  - ✅ Patterns - Phase 3.1 nearly complete (7/8)

## ✅ Success Criteria

- [ ] Unit tests written and passing
- [ ] SurfaceStyleKey EnvironmentKey implemented
- [ ] EnvironmentValues extension created
- [ ] Default value set to `.regular`
- [ ] View extension for environment modifier
- [ ] SwiftUI Preview included
- [ ] DocC documentation complete
- [ ] Zero magic numbers (use Material enum values)
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes

### Purpose

The `SurfaceStyleKey` provides a centralized way to propagate Material background preferences through the SwiftUI environment hierarchy. This allows child views to automatically adapt their surface styling based on parent context without explicit parameter passing.

### Architecture

```
Environment propagation:
  ParentView
    .environment(\.surfaceStyle, .thick)
      ↓
  ChildView (reads environment)
    .background(Material(environment.surfaceStyle))
```

### Files to Create/Modify

#### Create
- `Sources/FoundationUI/Contexts/SurfaceStyleKey.swift` - Main EnvironmentKey implementation
- `Tests/FoundationUITests/ContextsTests/SurfaceStyleKeyTests.swift` - Unit tests

### Design Token Usage

This feature uses SwiftUI's built-in `Material` type:
- `.thin` - Lightweight backgrounds
- `.regular` - Standard backgrounds (default)
- `.thick` - Prominent backgrounds
- `.ultraThin` - Minimal backgrounds
- `.ultraThick` - Heavy backgrounds

No custom DS tokens required, as Material is a system type.

### Implementation Structure

```swift
// Sources/FoundationUI/Contexts/SurfaceStyleKey.swift

import SwiftUI

/// Environment key for Material background styling
///
/// This key allows views to read and write the preferred Material style
/// for surface backgrounds throughout the view hierarchy.
///
/// ## Usage
///
/// Set the surface style in a parent view:
/// ```swift
/// VStack {
///     // Child views will inherit .thick material
/// }
/// .environment(\.surfaceStyle, .thick)
/// ```
///
/// Read the surface style in a child view:
/// ```swift
/// struct MyView: View {
///     @Environment(\.surfaceStyle) var surfaceStyle
///
///     var body: some View {
///         Text("Content")
///             .background(surfaceStyle)
///     }
/// }
/// ```
public struct SurfaceStyleKey: EnvironmentKey {
    /// Default Material style for surfaces
    ///
    /// `.regular` provides a balanced background that works well
    /// across both Light and Dark modes.
    public static let defaultValue: Material = .regular
}

extension EnvironmentValues {
    /// The preferred Material style for surface backgrounds
    ///
    /// Use this environment value to propagate surface styling
    /// preferences throughout the view hierarchy.
    ///
    /// - SeeAlso: `SurfaceStyleKey`
    public var surfaceStyle: Material {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the surface style for this view and its children
    ///
    /// This is a convenience method for setting the `surfaceStyle`
    /// environment value.
    ///
    /// - Parameter material: The Material to use for surface backgrounds
    /// - Returns: A view with the surface style set in its environment
    ///
    /// ## Example
    ///
    /// ```swift
    /// Card {
    ///     Text("Content")
    /// }
    /// .surfaceStyle(.thick)
    /// ```
    public func surfaceStyle(_ material: Material) -> some View {
        environment(\.surfaceStyle, material)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Surface Style Hierarchy") {
    VStack(spacing: DS.Spacing.l) {
        Text("Default (.regular)")
            .padding()
            .background(Material.regular)

        VStack {
            Text("Thick Material")
                .padding()
                .background(Material.thick)
        }
        .surfaceStyle(.thick)

        VStack {
            Text("Thin Material")
                .padding()
                .background(Material.thin)
        }
        .surfaceStyle(.thin)
    }
    .padding()
}

#Preview("Environment Propagation") {
    VStack(spacing: DS.Spacing.l) {
        EnvironmentReaderView()
    }
    .surfaceStyle(.ultraThick)
    .padding()
}

private struct EnvironmentReaderView: View {
    @Environment(\.surfaceStyle) var surfaceStyle

    var body: some View {
        VStack {
            Text("Reads surface style from environment")
                .font(DS.Typography.body)
            Text("Material: \(materialName)")
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(surfaceStyle)
    }

    private var materialName: String {
        // Material doesn't expose type info, so this is illustrative
        "inherited from parent"
    }
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Text("Thick Material")
            .padding()
            .background(Material.thick)
    }
    .surfaceStyle(.thick)
    .padding()
    .preferredColorScheme(.dark)
}
#endif
```

### Test Structure

```swift
// Tests/FoundationUITests/ContextsTests/SurfaceStyleKeyTests.swift

import XCTest
import SwiftUI
@testable import FoundationUI

final class SurfaceStyleKeyTests: XCTestCase {

    // MARK: - Default Value Tests

    func testDefaultValueIsRegular() {
        XCTAssertEqual(
            SurfaceStyleKey.defaultValue,
            .regular,
            "Default surface style should be .regular"
        )
    }

    // MARK: - Environment Value Tests

    func testEnvironmentValueSetAndGet() {
        var environment = EnvironmentValues()
        environment.surfaceStyle = .thick

        XCTAssertEqual(
            environment.surfaceStyle,
            .thick,
            "Should be able to set and get surface style from environment"
        )
    }

    func testEnvironmentValueDefaultsToRegular() {
        let environment = EnvironmentValues()

        XCTAssertEqual(
            environment.surfaceStyle,
            .regular,
            "Environment should default to .regular material"
        )
    }

    // MARK: - View Extension Tests

    func testSurfaceStyleModifier() {
        let view = Text("Test")
            .surfaceStyle(.thin)

        // View should apply environment modifier
        XCTAssertNotNil(view, "Surface style modifier should create valid view")
    }

    // MARK: - Material Values Tests

    func testAllMaterialValues() {
        let materials: [Material] = [
            .thin,
            .regular,
            .thick,
            .ultraThin,
            .ultraThick
        ]

        for material in materials {
            var environment = EnvironmentValues()
            environment.surfaceStyle = material

            XCTAssertEqual(
                environment.surfaceStyle,
                material,
                "Should support \(material) material"
            )
        }
    }
}
```

## 🧠 Source References

- [FoundationUI Task Plan § 3.2](../../AI/ISOViewer/FoundationUI_TaskPlan.md#32-layer-4-contexts--platform-adaptation)
- [FoundationUI PRD § Contexts](../../AI/ISOViewer/FoundationUI_PRD.md)
- [Apple SwiftUI Environment Documentation](https://developer.apple.com/documentation/swiftui/environment)
- [Apple Material Documentation](https://developer.apple.com/documentation/swiftui/material)

## 📋 Checklist

- [ ] Read task requirements from Task Plan
- [ ] Create Contexts directory: `Sources/FoundationUI/Contexts/`
- [ ] Create test directory: `Tests/FoundationUITests/ContextsTests/`
- [ ] Create test file and write failing tests
- [ ] Run tests to confirm failure (on macOS)
- [ ] Implement SurfaceStyleKey.swift
- [ ] Implement EnvironmentValues extension
- [ ] Implement View extension for convenience modifier
- [ ] Run tests to confirm pass
- [ ] Add SwiftUI Previews (3+ variations)
- [ ] Add DocC comments
- [ ] Verify zero magic numbers
- [ ] Test on iOS simulator (if available)
- [ ] Test on macOS (if available)
- [ ] Update Task Plan with [x] completion mark
- [ ] Commit with descriptive message

## 🎯 Expected Outcomes

After completing this task:

1. **Environment-Based Styling**: Components can read surface styling preferences from environment
2. **Reduced Prop Drilling**: No need to pass Material values through multiple component layers
3. **Consistent Theming**: Entire view hierarchies can share surface styling
4. **Foundation for Platform Adaptation**: Enables future platform-specific surface adaptations

## 📊 Quality Metrics

- Unit test coverage: 100% of public API
- Documentation completeness: 100%
- SwiftLint compliance: 0 violations
- Preview coverage: 3+ variations (hierarchy, dark mode, all materials)

## 🔄 Next Tasks After Completion

With SurfaceStyleKey complete, the next P0 task in Phase 3.2:

- **Implement PlatformAdaptation modifiers** (P0)
  - Platform-adaptive spacing
  - Conditional compilation for macOS vs iOS
  - Size class adaptation for iPad

---

**Created**: 2025-10-26
**Status**: Ready to implement
**Estimated Effort**: S-M (2-4 hours)
