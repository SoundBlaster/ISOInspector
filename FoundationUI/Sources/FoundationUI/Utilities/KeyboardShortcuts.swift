#if canImport(SwiftUI)
    import SwiftUI

    // MARK: - KeyboardShortcutType

    /// Defines standard keyboard shortcuts with platform-specific behavior
    ///
    /// KeyboardShortcutType provides predefined shortcuts for common actions like copy, paste, cut, etc.
    /// The shortcuts automatically adapt to platform conventions:
    /// - macOS: Uses Command (⌘) key
    /// - Other platforms: Uses Control (Ctrl) key
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Text("My Content")
    ///     .shortcut(.copy) {
    ///         // Handle copy action
    ///     }
    /// ```
    ///
    /// ## Supported Shortcuts
    ///
    /// - Copy (⌘C / Ctrl+C)
    /// - Paste (⌘V / Ctrl+V)
    /// - Cut (⌘X / Ctrl+X)
    /// - Select All (⌘A / Ctrl+A)
    /// - Undo (⌘Z / Ctrl+Z)
    /// - Redo (⌘⇧Z / Ctrl+Y)
    /// - Save (⌘S / Ctrl+S)
    /// - Find (⌘F / Ctrl+F)
    /// - New Item (⌘N / Ctrl+N)
    /// - Close (⌘W / Ctrl+W)
    /// - Refresh (⌘R / Ctrl+R)
    ///
    /// ## Accessibility
    ///
    /// All shortcuts provide descriptive accessibility labels suitable for VoiceOver and other assistive technologies.
    public enum KeyboardShortcutType: Sendable {
        /// Copy shortcut (⌘C / Ctrl+C)
        case copy

        /// Paste shortcut (⌘V / Ctrl+V)
        case paste

        /// Cut shortcut (⌘X / Ctrl+X)
        case cut

        /// Select All shortcut (⌘A / Ctrl+A)
        case selectAll

        /// Undo shortcut (⌘Z / Ctrl+Z)
        case undo

        /// Redo shortcut (⌘⇧Z / Ctrl+Y)
        case redo

        /// Save shortcut (⌘S / Ctrl+S)
        case save

        /// Find shortcut (⌘F / Ctrl+F)
        case find

        /// New Item shortcut (⌘N / Ctrl+N)
        case newItem

        /// Close shortcut (⌘W / Ctrl+W)
        case close

        /// Refresh shortcut (⌘R / Ctrl+R)
        case refresh

        /// Custom shortcut with specified key and modifiers
        ///
        /// Use this case when you need a shortcut that isn't covered by the standard definitions.
        ///
        /// ## Example
        ///
        /// ```swift
        /// let customShortcut = KeyboardShortcutType.custom(
        ///     key: "g",
        ///     modifiers: KeyboardShortcutModifiers.commandShift
        /// )
        /// ```
        case custom(key: KeyEquivalent, modifiers: EventModifiers)

        /// The key equivalent for this shortcut
        ///
        /// Returns the character key that should be pressed along with modifier keys.
        public var keyEquivalent: KeyEquivalent {
            switch self {
            case .copy: "c"
            case .paste: "v"
            case .cut: "x"
            case .selectAll: "a"
            case .undo: "z"
            case .redo: "z"
            case .save: "s"
            case .find: "f"
            case .newItem: "n"
            case .close: "w"
            case .refresh: "r"
            case .custom(let key, _): key
            }
        }

        /// The modifier keys for this shortcut
        ///
        /// Returns platform-appropriate modifier keys:
        /// - macOS: `.command` for most shortcuts
        /// - Other platforms: `.control` for most shortcuts
        public var modifiers: EventModifiers {
            switch self {
            case .copy, .paste, .cut, .selectAll, .undo, .save, .find, .newItem, .close, .refresh:
                KeyboardShortcutModifiers.command
            case .redo: KeyboardShortcutModifiers.commandShift
            case .custom(_, let modifiers): modifiers
            }
        }

        /// Human-readable display string for the shortcut
        ///
        /// Returns a formatted string showing the shortcut combination:
        /// - macOS: Uses symbols like "⌘C", "⌘⇧Z"
        /// - Other platforms: Uses text like "Ctrl+C", "Ctrl+Shift+Z"
        ///
        /// ## Example
        ///
        /// ```swift
        /// KeyboardShortcutType.copy.displayString  // "⌘C" on macOS, "Ctrl+C" elsewhere
        /// KeyboardShortcutType.redo.displayString  // "⌘⇧Z" on macOS, "Ctrl+Shift+Z" elsewhere
        /// ```
        public var displayString: String {
            #if os(macOS)
                return macOSDisplayString
            #else
                return nonMacOSDisplayString
            #endif
        }

        /// Display string for macOS using symbols
        private var macOSDisplayString: String {
            let keyChar = keyEquivalent.character.uppercased()

            if modifiers.contains(.shift), modifiers.contains(.command) {
                return "⌘⇧\(keyChar)"
            } else if modifiers.contains(.command) {
                return "⌘\(keyChar)"
            } else if modifiers.contains(.control) {
                return "⌃\(keyChar)"
            } else if modifiers.contains(.option) {
                return "⌥\(keyChar)"
            } else {
                return keyChar
            }
        }

        /// Display string for non-macOS platforms using text
        private var nonMacOSDisplayString: String {
            let keyChar = keyEquivalent.character.uppercased()
            var parts: [String] = []

            if modifiers.contains(.control) { parts.append("Ctrl") }
            if modifiers.contains(.shift) { parts.append("Shift") }
            if modifiers.contains(.option) { parts.append("Alt") }

            parts.append(keyChar)
            return parts.joined(separator: "+")
        }

        /// Accessibility label describing the shortcut
        ///
        /// Provides a descriptive label suitable for VoiceOver and other assistive technologies.
        /// Includes both the action name and the keyboard shortcut.
        ///
        /// ## Example
        ///
        /// ```swift
        /// KeyboardShortcutType.copy.accessibilityLabel
        /// // "Copy, Command C" on macOS, "Copy, Control C" elsewhere
        /// ```
        public var accessibilityLabel: String {
            let actionName = actionName
            let keyChar = keyEquivalent.character.uppercased()

            #if os(macOS)
                let modifierText = accessibilityModifierText(macOS: true)
            #else
                let modifierText = accessibilityModifierText(macOS: false)
            #endif

            return "\(actionName), \(modifierText) \(keyChar)"
        }

        /// Returns the human-readable action name for this shortcut
        private var actionName: String {
            switch self {
            case .copy: "Copy"
            case .paste: "Paste"
            case .cut: "Cut"
            case .selectAll: "Select All"
            case .undo: "Undo"
            case .redo: "Redo"
            case .save: "Save"
            case .find: "Find"
            case .newItem: "New"
            case .close: "Close"
            case .refresh: "Refresh"
            case .custom: "Custom Action"
            }
        }

        /// Helper to generate accessibility text for modifiers
        private func accessibilityModifierText(macOS: Bool) -> String {
            var parts: [String] = []

            if macOS {
                if modifiers.contains(.command) { parts.append("Command") }
                if modifiers.contains(.shift) { parts.append("Shift") }
                if modifiers.contains(.option) { parts.append("Option") }
                if modifiers.contains(.control) { parts.append("Control") }
            } else {
                if modifiers.contains(.control) { parts.append("Control") }
                if modifiers.contains(.shift) { parts.append("Shift") }
                if modifiers.contains(.option) { parts.append("Alt") }
            }

            return parts.joined(separator: " ")
        }
    }

    // MARK: - KeyboardShortcutModifiers

    /// Platform-specific keyboard shortcut modifier keys
    ///
    /// Provides abstractions for modifier keys that adapt to platform conventions:
    /// - macOS: Command, Option
    /// - Other platforms: Control, Alt
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // This returns .command on macOS, .control elsewhere
    /// let modifier = KeyboardShortcutModifiers.command
    ///
    /// // This returns [.command, .shift] on macOS, [.control, .shift] elsewhere
    /// let combination = KeyboardShortcutModifiers.commandShift
    /// ```
    public enum KeyboardShortcutModifiers {
        /// Primary modifier key (Command on macOS, Control elsewhere)
        ///
        /// Use this for the primary "command" modifier that should be:
        /// - ⌘ (Command) on macOS
        /// - Ctrl (Control) on other platforms
        public static var command: EventModifiers {
            #if os(macOS)
                return .command
            #else
                return .control
            #endif
        }

        /// Command + Shift combination
        ///
        /// Returns:
        /// - `[.command, .shift]` on macOS
        /// - `[.control, .shift]` on other platforms
        public static var commandShift: EventModifiers {
            #if os(macOS)
                return [.command, .shift]
            #else
                return [.control, .shift]
            #endif
        }

        /// Option/Alt modifier key
        ///
        /// Returns:
        /// - `.option` on macOS
        /// - `.option` on other platforms (maps to Alt)
        public static var option: EventModifiers { .option }

        /// Shift modifier key
        ///
        /// This is consistent across all platforms.
        public static var shift: EventModifiers { .shift }

        /// Control modifier key
        ///
        /// Note: On macOS, Control is less commonly used than Command.
        /// Consider using `command` instead for cross-platform shortcuts.
        public static var control: EventModifiers { .control }
    }

    // MARK: - View Extension

    extension View {
        /// Apply a keyboard shortcut to this view with an action handler
        ///
        /// Adds platform-appropriate keyboard shortcut support to any SwiftUI view.
        ///
        /// ## Usage
        ///
        /// ```swift
        /// Button("Copy") {
        ///     // Button tap action
        /// }
        /// .shortcut(.copy) {
        ///     // Keyboard shortcut action
        ///     copyToClipboard()
        /// }
        /// ```
        ///
        /// ## Platform Behavior
        ///
        /// - macOS: All shortcuts are available
        /// - iOS: Shortcuts only work with hardware keyboards
        /// - iPadOS: Shortcuts work with hardware keyboards and on-screen keyboard with keyboard shortcuts bar
        ///
        /// ## Accessibility
        ///
        /// The shortcut is automatically announced to VoiceOver users via the accessibility label.
        ///
        /// - Parameters:
        ///   - type: The keyboard shortcut type to apply
        ///   - action: The action to perform when the shortcut is triggered
        /// - Returns: A view with the keyboard shortcut applied
        @ViewBuilder public func shortcut(
            _ type: KeyboardShortcutType, action _: @escaping () -> Void
        ) -> some View {
            keyboardShortcut(type.keyEquivalent, modifiers: type.modifiers).accessibilityLabel(
                Text(type.accessibilityLabel))
        }
    }

    /// Convenience alias so DocC references ``KeyboardShortcuts`` resolve to
    /// the canonical ``KeyboardShortcutType`` enum without duplicating APIs.
    public typealias KeyboardShortcuts = KeyboardShortcutType

    // MARK: - Previews

    #Preview("Standard Shortcuts") {
        VStack(spacing: DS.Spacing.l) {
            Text("Standard Keyboard Shortcuts").font(DS.Typography.title).padding(
                .bottom, DS.Spacing.m)

            Group {
                HStack {
                    Text("Copy:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.copy.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.infoBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Paste:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.paste.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.infoBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Cut:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.cut.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.infoBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Select All:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.selectAll.displayString).font(DS.Typography.code)
                        .padding(.horizontal, DS.Spacing.m).background(DS.Colors.infoBG)
                        .cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Undo:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.undo.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.infoBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Redo:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.redo.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.warnBG).cornerRadius(DS.Radius.small)
                }
            }

            Divider().padding(.vertical, DS.Spacing.m)

            Group {
                HStack {
                    Text("Save:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.save.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.successBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("Find:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.find.displayString).font(DS.Typography.code).padding(
                        .horizontal, DS.Spacing.m
                    ).background(DS.Colors.infoBG).cornerRadius(DS.Radius.small)
                }

                HStack {
                    Text("New Item:").font(DS.Typography.body)
                    Spacer()
                    Text(KeyboardShortcutType.newItem.displayString).font(DS.Typography.code)
                        .padding(.horizontal, DS.Spacing.m).background(DS.Colors.infoBG)
                        .cornerRadius(DS.Radius.small)
                }
            }
        }.padding(DS.Spacing.xl)
    }

    #Preview("Platform Modifiers") {
        VStack(spacing: DS.Spacing.l) {
            Text("Platform-Specific Modifiers").font(DS.Typography.title).padding(
                .bottom, DS.Spacing.m)

            #if os(macOS)
                Text("Running on macOS").font(DS.Typography.headline).foregroundColor(
                    DS.Colors.accent
                ).padding(.bottom, DS.Spacing.s)
            #else
                Text("Running on iOS/iPadOS").font(DS.Typography.headline).foregroundColor(
                    DS.Colors.accent
                ).padding(.bottom, DS.Spacing.s)
            #endif

            Group {
                HStack {
                    Text("Command modifier:").font(DS.Typography.body)
                    Spacer()
                    #if os(macOS)
                        Text("⌘ (Command)")
                    #else
                        Text("Ctrl (Control)")
                    #endif
                }

                HStack {
                    Text("Command + Shift:").font(DS.Typography.body)
                    Spacer()
                    #if os(macOS)
                        Text("⌘⇧")
                    #else
                        Text("Ctrl + Shift")
                    #endif
                }

                HStack {
                    Text("Option modifier:").font(DS.Typography.body)
                    Spacer()
                    #if os(macOS)
                        Text("⌥ (Option)")
                    #else
                        Text("Alt")
                    #endif
                }
            }

            Divider().padding(.vertical, DS.Spacing.m)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Platform Behavior:").font(DS.Typography.headline)

                Text("• macOS uses Command (⌘) as primary modifier").font(DS.Typography.caption)

                Text("• Other platforms use Control (Ctrl)").font(DS.Typography.caption)

                Text("• Shortcuts automatically adapt to platform").font(DS.Typography.caption)
            }.padding(DS.Spacing.m).background(DS.Colors.infoBG).cornerRadius(DS.Radius.medium)
        }.padding(DS.Spacing.xl)
    }

    #Preview("Interactive Shortcuts") {
        VStack(spacing: DS.Spacing.l) {
            Text("Interactive Shortcut Demo").font(DS.Typography.title).padding(
                .bottom, DS.Spacing.m)

            Text("Try using keyboard shortcuts:").font(DS.Typography.body)

            Group {
                Button("Copy Text") { print("Button clicked: Copy") }.buttonStyle(.bordered)
                    .shortcut(.copy) { print("Shortcut triggered: Copy") }

                Button("Paste Text") { print("Button clicked: Paste") }.buttonStyle(.bordered)
                    .shortcut(.paste) { print("Shortcut triggered: Paste") }

                Button("Save Document") { print("Button clicked: Save") }.buttonStyle(
                    .borderedProminent
                ).shortcut(.save) { print("Shortcut triggered: Save") }
            }

            Divider().padding(.vertical, DS.Spacing.m)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Accessibility:").font(DS.Typography.headline)

                Text("• Shortcuts announced to VoiceOver users").font(DS.Typography.caption)

                Text("• Hardware keyboard required on iOS").font(DS.Typography.caption)

                Text("• All platforms support keyboard navigation").font(DS.Typography.caption)
            }.padding(DS.Spacing.m).background(DS.Colors.successBG).cornerRadius(DS.Radius.medium)
        }.padding(DS.Spacing.xl)
    }

#endif
