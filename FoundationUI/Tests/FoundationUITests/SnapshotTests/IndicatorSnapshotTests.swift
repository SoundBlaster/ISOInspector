#if canImport(SnapshotTesting) && !os(Linux)
import XCTest
import SwiftUI
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

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func testIndicatorCatalogDarkMode() {
        let view = indicatorCatalog()
            .padding(DS.Spacing.l)
            .preferredColorScheme(.dark)

        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13)))
    }

    private func indicatorCatalog() -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            ForEach(Array(BadgeLevel.allCases.enumerated()), id: \.offset) { _, level in
                HStack(spacing: DS.Spacing.m) {
                    ForEach(Array(Indicator.Size.allCases.enumerated()), id: \.offset) { _, size in
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
}
#endif
