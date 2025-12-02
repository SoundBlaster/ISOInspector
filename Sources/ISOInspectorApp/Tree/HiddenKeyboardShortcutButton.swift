import ISOInspectorKit
import SwiftUI

extension ParseTreeExplorerView {
    struct HiddenKeyboardShortcutButton: View {
        let title: LocalizedStringKey
        let key: KeyEquivalent
        let modifiers: EventModifiers
        let action: () -> Void

        var body: some View {
            Button(title) { action() }.keyboardShortcut(key, modifiers: modifiers).buttonStyle(
                .plain
            ).frame(width: 0, height: 0).opacity(0.001).allowsHitTesting(false).accessibilityHidden(
                true)
        }
    }
}
