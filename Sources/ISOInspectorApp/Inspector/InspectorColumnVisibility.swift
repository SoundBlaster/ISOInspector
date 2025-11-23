#if canImport(SwiftUI)
  import SwiftUI

  struct InspectorColumnVisibility: Equatable {
    var columnVisibility: NavigationSplitViewVisibility = .all

    var isInspectorVisible: Bool {
      columnVisibility == .all || columnVisibility == .detailOnly
    }

    mutating func toggleInspectorVisibility() {
      columnVisibility = isInspectorVisible ? .doubleColumn : .all
    }

    mutating func ensureInspectorVisible() {
      columnVisibility = .all
    }
  }
#endif
