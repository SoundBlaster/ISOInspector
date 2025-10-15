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
            AppShellView(controller: controller)
                .a11yRoot(ParseTreeAccessibilityID.root)
        }
    }

    @MainActor
    private static func makeDocumentSessionController() -> DocumentSessionController {
        let recentsStore = DocumentRecentsStore(directory: recentsDirectory())
        #if canImport(CoreData)
        let (annotations, sessionStore) = makeAnnotationSession()
        #else
        let annotations = AnnotationBookmarkSession(store: nil)
        let sessionStore: WorkspaceSessionStoring? = FileBackedWorkspaceSessionStore(directory: sessionStoreDirectory())
        #endif
        return DocumentSessionController(
            parseTreeStore: ParseTreeStore(),
            annotations: annotations,
            recentsStore: recentsStore,
            sessionStore: sessionStore
        )
    }

    private static func recentsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("DocumentRecents", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    #if canImport(CoreData)
    @MainActor
    private static func makeAnnotationSession() -> (AnnotationBookmarkSession, CoreDataAnnotationBookmarkStore?) {
        let directory = annotationStoreDirectory()
        let store = try? CoreDataAnnotationBookmarkStore(directory: directory)
        return (AnnotationBookmarkSession(store: store), store)
    }

    private static func annotationStoreDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("AnnotationBookmarks", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    #endif

    private static func sessionStoreDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("WorkspaceSession", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
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
