#if canImport(SwiftUI) && canImport(Combine)
  import SwiftUI

  /// A platform-adaptive scene for presenting the Settings Panel
  ///
  /// This scene provides platform-specific presentation for the floating settings panel:
  /// - macOS: Sheet with keyboard shortcut support (⌘,)
  /// - iPadOS: Modal sheet with detents (.medium, .large)
  /// - iOS: Full-screen modal sheet
  struct SettingsPanelScene: View {
    @Binding var isPresented: Bool

    // @todo #222 Replace with proper dependency injection from app-level
    // Currently uses in-memory mock store; production needs real FileBackedUserPreferencesStore
    @StateObject private var viewModel = SettingsPanelViewModel(
      preferencesStore: InMemoryUserPreferencesStore()
    )

    var body: some View {
      #if os(macOS)
        macOSPresentation
      #elseif os(iOS)
        iOSPresentation
      #endif
    }

    // MARK: - Platform-Specific Presentations

    #if os(macOS)
      // @todo #222 Replace sheet with NSPanel window controller for floating window behavior
      // @todo #222 Remember panel frame/position in UserPreferences
      // @todo #222 NSPanel benefits: always-on-top, floating, better positioning control
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
        // @todo #222 Add fullScreenCover for iPhone based on horizontalSizeClass
        // @todo #222 Platform detection: if UIDevice.current.userInterfaceIdiom == .pad
        self.sheet(isPresented: isPresented) {
          SettingsPanelScene(isPresented: isPresented)
          // Detents for iPad (iOS 16+)
          // .presentationDetents([.medium, .large])
          // .presentationDragIndicator(.visible)
        }
      #else
        self
      #endif
    }

    /// Adds keyboard shortcut for toggling settings panel (⌘,)
    ///
    /// - Parameter isPresented: Binding controlling panel visibility
    /// - Returns: Modified view with keyboard shortcut
    ///
    /// ## Implementation Status
    ///
    /// **Partial Implementation (Puzzle #222.4)**
    ///
    /// Current status:
    /// - ✅ Scene infrastructure ready (SettingsPanelScene)
    /// - ✅ Platform-specific presentation (sheet modifiers)
    /// - ⏳ Keyboard shortcut binding (stub via NotificationCenter)
    /// - ❌ CommandGroup integration in ISOInspectorApp
    /// - ❌ Focus restoration after toggle
    ///
    /// ## Full Implementation Required
    ///
    /// To complete keyboard shortcut support:
    ///
    /// 1. Add CommandGroup to ISOInspectorApp.body.commands:
    ///    ```swift
    ///    .commands {
    ///        CommandGroup(replacing: .appSettings) {
    ///            Button("Settings...") {
    ///                NotificationCenter.default.post(
    ///                    name: NSNotification.Name("ToggleSettingsPanel"),
    ///                    object: nil
    ///                )
    ///            }
    ///            .keyboardShortcut(",", modifiers: .command)
    ///        }
    ///    }
    ///    ```
    ///
    /// 2. Add @State var isSettingsPanelPresented = false to AppShellView
    ///
    /// 3. Wire sheet presentation in AppShellView:
    ///    ```swift
    ///    .settingsPanelSheet(isPresented: $isSettingsPanelPresented)
    ///    .settingsPanelKeyboardShortcut(isPresented: $isSettingsPanelPresented)
    ///    ```
    ///
    /// 4. Implement focus restoration on dismiss (store last focused element)
    ///
    /// @todo #222 Add CommandGroup to ISOInspectorApp for Settings menu item with ⌘, shortcut
    /// @todo #222 Wire isSettingsPanelPresented state through AppShellView
    /// @todo #222 Implement focus restoration when panel toggles
    /// @todo #222 Test keyboard shortcut across macOS, iPad, iPhone
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

  // MARK: - In-Memory Mock Store

  /// Temporary in-memory store for SettingsPanelScene
  /// @todo #222 Replace with proper dependency injection of FileBackedUserPreferencesStore from app level
  private final class InMemoryUserPreferencesStore: UserPreferencesPersisting {
    private var preferences: UserPreferences?

    func loadPreferences() throws -> UserPreferences? {
      preferences
    }

    func savePreferences(_ preferences: UserPreferences) throws {
      self.preferences = preferences
    }

    func reset() throws {
      preferences = nil
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
