#if canImport(SwiftUI)
  import SwiftUI

  private struct InspectorFocusTargetBindingKey: FocusedValueKey {
    typealias Value = Binding<InspectorFocusTarget?>
  }

  extension FocusedValues {
    var inspectorFocusTarget: Binding<InspectorFocusTarget?>? {
      get { self[InspectorFocusTargetBindingKey.self] }
      set { self[InspectorFocusTargetBindingKey.self] = newValue }
    }
  }
#endif
