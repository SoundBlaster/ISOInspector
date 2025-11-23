#if canImport(SwiftUI)
  import SwiftUI

  struct InspectorColumnVisibility: Equatable {
    var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var isInspectorVisible: Bool {
      columnVisibility != .sidebarOnly
    }

    mutating func toggleInspectorVisibility() {
      columnVisibility = isInspectorVisible ? .sidebarOnly : .doubleColumn
    }

    mutating func ensureInspectorVisible() {
      columnVisibility = .doubleColumn
    }
  }
#endif
