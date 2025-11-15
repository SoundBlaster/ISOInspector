#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI

/// A platform-adaptive scene for presenting the Settings Panel
///
/// This scene provides platform-specific presentation for the floating settings panel:
/// - macOS: Sheet with keyboard shortcut support (⌘,)
/// - iPadOS: Modal sheet with detents (.medium, .large)
/// - iOS: Full-screen modal sheet
struct SettingsPanelScene: View {
    @StateObject private var viewModel = SettingsPanelViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        #if os(macOS)
            macOSPresentation
        #elseif os(iOS)
            iOSPresentation
        #endif
    }

    // MARK: - Platform-Specific Presentations

    #if os(macOS)
        private var macOSPresentation: some View {
            SettingsPanelView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            isPresented = false
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .accessibilityIdentifier("SettingsPanelScene.macOS")
        }
    #endif

    #if os(iOS)
        private var iOSPresentation: some View {
            NavigationStack {
                SettingsPanelView(viewModel: viewModel)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresented = false
                            }
                        }
                    }
            }
            .accessibilityIdentifier("SettingsPanelScene.iOS")
        }
    #endif
}

// MARK: - Environment Integration

/// Environment key for presenting the settings panel
struct SettingsPanelPresentationKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isSettingsPanelPresented: Binding<Bool> {
        get { self[SettingsPanelPresentationKey.self] }
        set { self[SettingsPanelPresentationKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Presents the settings panel as a modal sheet with platform-adaptive behavior
    ///
    /// - Parameter isPresented: Binding controlling panel visibility
    /// - Returns: Modified view with settings panel presentation
    func settingsPanelSheet(isPresented: Binding<Bool>) -> some View {
        #if os(macOS)
            self.sheet(isPresented: isPresented) {
                SettingsPanelScene(isPresented: isPresented)
            }
        #elseif os(iOS)
            // @todo #222 Add detent support for iPad (.medium, .large)
            // @todo #222 Add fullScreenCover for iPhone
            self.sheet(isPresented: isPresented) {
                SettingsPanelScene(isPresented: isPresented)
            }
        #else
            self
        #endif
    }

    /// Adds keyboard shortcut for toggling settings panel (⌘,)
    ///
    /// - Parameter isPresented: Binding controlling panel visibility
    /// - Returns: Modified view with keyboard shortcut
    func settingsPanelKeyboardShortcut(isPresented: Binding<Bool>) -> some View {
        #if os(macOS)
            self.onReceive(
                NotificationCenter.default.publisher(
                    for: NSNotification.Name("ToggleSettingsPanel"))
            ) { _ in
                isPresented.wrappedValue.toggle()
            }
        #else
            self
        #endif
    }
}

// MARK: - Preview

#if DEBUG
    struct SettingsPanelScene_Previews: PreviewProvider {
        static var previews: some View {
            Text("Main Content")
                .settingsPanelSheet(isPresented: .constant(true))
        }
    }
#endif
#endif
