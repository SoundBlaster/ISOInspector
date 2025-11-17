#if canImport(SwiftUI) && canImport(Combine)
  import SwiftUI
  import NestedA11yIDs
  import ISOInspectorKit
  #if canImport(CoreData)
    import CoreData
  #endif

  @main
  struct ISOInspectorApp: App {
    @StateObject private var controller = ISOInspectorApp.makeDocumentSessionController()

    var body: some Scene {
      WindowGroup {
        AppShellView(appController: controller)
          .isoInspectorAppTheme()
          .a11yRoot(ParseTreeAccessibilityID.root)
      }
      .commands {
        FocusCommands()
        CommandMenu("Export") {
          Button("Export JSON…") {
            Task { await controller.exportJSON(scope: .document) }
          }
          .disabled(!controller.documentViewModel.exportAvailability.canExportDocument)

          Button("Export Issue Summary…") {
            Task { await controller.exportIssueSummary(scope: .document) }
          }
          .disabled(!controller.documentViewModel.exportAvailability.canExportDocument)

          Button("Export Selected JSON…") {
            guard let nodeID = controller.documentViewModel.nodeViewModel.selectedNodeID else {
              return
            }
            Task { await controller.exportJSON(scope: .selection(nodeID)) }
          }
          .disabled(!controller.documentViewModel.exportAvailability.canExportSelection)

          Button("Export Selected Issue Summary…") {
            guard let nodeID = controller.documentViewModel.nodeViewModel.selectedNodeID else {
              return
            }
            Task { await controller.exportIssueSummary(scope: .selection(nodeID)) }
          }
          .disabled(!controller.documentViewModel.exportAvailability.canExportSelection)
        }
      }
      #if os(macOS)
        Settings {
          ValidationSettingsView(controller: controller)
            .isoInspectorAppTheme()
        }
      #endif
    }

    @MainActor
    private static func makeDocumentSessionController() -> DocumentSessionController {
      let recentsStore = DocumentRecentsStore(directory: recentsDirectory())
      let bookmarkStore = BookmarkPersistenceStore(directory: recentsDirectory())
      #if canImport(CoreData)
        let (annotations, sessionStore) = makeAnnotationSession()
      #else
        let annotations = AnnotationBookmarkSession(store: nil)
        let sessionStore: WorkspaceSessionStoring? = FileBackedWorkspaceSessionStore(
          directory: sessionStoreDirectory())
      #endif
      return DocumentSessionController(
        parseTreeStore: ParseTreeStore(),
        annotations: annotations,
        recentsStore: recentsStore,
        sessionStore: sessionStore,
        bookmarkStore: bookmarkStore,
        filesystemAccess: FilesystemAccess.live(),
        validationConfigurationStore: FileBackedValidationConfigurationStore(
          directory: validationConfigurationDirectory()
        )
      )
    }

    private static func recentsDirectory() -> URL {
      let base =
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory
      let directory = base.appendingPathComponent("DocumentRecents", isDirectory: true)
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory
    }

    #if canImport(CoreData)
      @MainActor
      private static func makeAnnotationSession() -> (
        AnnotationBookmarkSession, CoreDataAnnotationBookmarkStore?
      ) {
        let directory = annotationStoreDirectory()
        let store = try? CoreDataAnnotationBookmarkStore(directory: directory)
        return (AnnotationBookmarkSession(store: store), store)
      }

      private static func annotationStoreDirectory() -> URL {
        let base =
          FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
          ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("AnnotationBookmarks", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
      }
    #endif

    private static func sessionStoreDirectory() -> URL {
      let base =
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory
      let directory = base.appendingPathComponent("WorkspaceSession", isDirectory: true)
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory
    }

    private static func validationConfigurationDirectory() -> URL {
      let base =
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.temporaryDirectory
      let directory = base.appendingPathComponent("ValidationConfiguration", isDirectory: true)
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory
    }
  }

  private struct FocusCommands: Commands {
    @FocusedValue(\.inspectorFocusTarget) private var focusTarget
    private let catalog = InspectorFocusShortcutCatalog.default

    var body: some Commands {
      CommandMenu("Focus") {
        if let focusTarget {
          ForEach(catalog.shortcuts) { descriptor in
            Button(descriptor.title) {
              focusTarget.wrappedValue = descriptor.target
            }
            .keyboardShortcut(
              KeyEquivalent(descriptor.key.first ?? " "),
              modifiers: [.command, .option]
            )
          }
        } else {
          Text("Open a parse session to enable focus shortcuts")
        }
      }
    }
  }
#else
  import Foundation
  import ISOInspectorKit

  @main
  struct ISOInspectorAppFallback {
    static func main() {
      FileHandle.standardOutput.write(Data(ISOInspectorKit.welcomeMessage().utf8))
    }
  }
#endif
