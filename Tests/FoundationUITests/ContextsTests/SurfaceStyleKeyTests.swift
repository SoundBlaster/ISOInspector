#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import FoundationUI

/// Tests that exercise the SurfaceStyleKey environment integration.
///
/// These tests intentionally compare `Material` values by their textual
/// representation because SwiftUI does not expose Equatable conformance.
/// The string descriptions are stable across platforms and ensure that we
/// propagate the expected material through EnvironmentValues.
final class SurfaceStyleKeyTests: XCTestCase {

    // MARK: - Helpers

    private func description(of material: Material) -> String {
        String(describing: material)
    }

    // MARK: - Default Value

    func testDefaultValueIsRegularMaterial() {
        XCTAssertEqual(
            description(of: SurfaceStyleKey.defaultValue),
            description(of: .regular),
            "Default material should match .regular"
        )
    }

    // MARK: - EnvironmentValues

    func testEnvironmentValueDefaultsToRegular() {
        let environment = EnvironmentValues()

        XCTAssertEqual(
            description(of: environment.surfaceStyle),
            description(of: .regular),
            "Environment should default to .regular material"
        )
    }

    func testEnvironmentValueSetAndGet() {
        var environment = EnvironmentValues()
        environment.surfaceStyle = .thick

        XCTAssertEqual(
            description(of: environment.surfaceStyle),
            description(of: .thick),
            "Environment should return the custom material that was set"
        )
    }

    // MARK: - View Extension

    func testSurfaceStyleModifierProducesModifiedContent() {
        let view = Text("Surface Style Test").surfaceStyle(.ultraThick)
        let typeName = String(describing: type(of: view))

        XCTAssertTrue(
            typeName.contains("ModifiedContent"),
            "surfaceStyle(_:) should return a ModifiedContent view"
        )
    }
}
#endif
