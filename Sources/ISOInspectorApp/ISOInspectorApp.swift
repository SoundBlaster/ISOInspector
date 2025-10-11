import ISOInspectorKit

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import NestedA11yIDs
#if canImport(CoreData)
import CoreData
#endif

@main
struct ISOInspectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .a11yRoot(ParseTreeAccessibilityID.root)
        }
    }
}

private struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = ParseTreeStore()
    #if canImport(CoreData)
    @StateObject private var annotations = ContentView.makeAnnotationSession()
    #else
    @StateObject private var annotations = AnnotationBookmarkSession(store: nil)
    #endif

    var body: some View {
        ParseTreeExplorerView(store: store, annotations: annotations)
            .frame(minWidth: 480, minHeight: 480)
            .onDisappear {
                store.shutdown()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background || phase == .inactive {
                    store.shutdown()
                }
            }
    }

    #if canImport(CoreData)
    private static func makeAnnotationSession() -> AnnotationBookmarkSession {
        let directory = annotationStoreDirectory()
        let store = try? CoreDataAnnotationBookmarkStore(directory: directory)
        return AnnotationBookmarkSession(store: store)
    }

    private static func annotationStoreDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("AnnotationBookmarks", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    #endif
}
#else
import Foundation

@main
struct ISOInspectorAppFallback {
    static func main() {
        FileHandle.standardOutput.write(Data(ISOInspectorKit.welcomeMessage().utf8))
    }
}
#endif
