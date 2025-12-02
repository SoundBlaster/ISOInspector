#if canImport(SwiftUI)
    import SwiftUI

    extension View {
        @ViewBuilder func onChangeCompat<Value: Equatable>(
            of value: Value, perform action: @escaping (Value) -> Void
        ) -> some View {
            if #available(iOS 17.0, macOS 14.0, *) {
                self.onChange(of: value, initial: false) { _, newValue in action(newValue) }
            } else {
                self.onChange(of: value) { newValue in action(newValue) }
            }
        }
    }
#endif
