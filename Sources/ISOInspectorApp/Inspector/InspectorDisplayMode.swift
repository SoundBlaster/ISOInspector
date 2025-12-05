#if canImport(SwiftUI)
    import SwiftUI

    /// Tracks which inspector pane is visible in the Parse Tree experience.
    struct InspectorDisplayMode: Equatable {
        enum Pane: Equatable {
            case selectionDetails
            case integritySummary
        }

        var current: Pane = .selectionDetails

        var isShowingIntegritySummary: Bool { current == .integritySummary }

        var toggleButtonLabel: String {
            isShowingIntegritySummary ? "Show Details" : "Show Integrity"
        }

        mutating func toggle() {
            current = isShowingIntegritySummary ? .selectionDetails : .integritySummary
        }
    }
#endif
