import Foundation

struct InspectorFocusShortcutDescriptor: Equatable, Identifiable {
  let target: InspectorFocusTarget
  let key: String
  let paneName: String

  var id: InspectorFocusTarget { target }

  var title: String {
    "Focus \(paneName) Pane"
  }

  var discoverabilityTitle: String { title }
}

struct InspectorFocusShortcutCatalog {
  let shortcuts: [InspectorFocusShortcutDescriptor]

  func descriptor(for target: InspectorFocusTarget) -> InspectorFocusShortcutDescriptor? {
    shortcuts.first(where: { $0.target == target })
  }
}

extension InspectorFocusShortcutCatalog {
  static let `default` = InspectorFocusShortcutCatalog(
    shortcuts: [
      InspectorFocusShortcutDescriptor(target: .outline, key: "1", paneName: "Outline"),
      InspectorFocusShortcutDescriptor(target: .detail, key: "2", paneName: "Detail"),
      InspectorFocusShortcutDescriptor(target: .notes, key: "3", paneName: "Notes"),
      InspectorFocusShortcutDescriptor(target: .hex, key: "4", paneName: "Hex"),
    ]
  )
}
