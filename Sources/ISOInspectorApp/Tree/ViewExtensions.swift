import SwiftUI

extension View {
    @ViewBuilder func accessibilityValue(optional value: String?) -> some View {
        if let value { accessibilityValue(value) } else { self }
    }

    @ViewBuilder func accessibilityHint(optional hint: String?) -> some View {
        if let hint { accessibilityHint(hint) } else { self }
    }

    @ViewBuilder func compatibilityFocusable() -> some View {
        #if os(iOS)
            if #available(iOS 17, *) { focusable(true) } else { self }
        #else
            focusable(true)
        #endif
    }

    @ViewBuilder func onChangeCompatibility<Value: Equatable>(
        of value: Value, initial: Bool = false, perform: @escaping (Value) -> Void
    ) -> some View {
        if #available(iOS 17, macOS 14, *) {
            onChange(of: value, initial: initial) { _, newValue in perform(newValue) }
        } else {
            onChange(of: value, perform: perform)
        }
    }
}
