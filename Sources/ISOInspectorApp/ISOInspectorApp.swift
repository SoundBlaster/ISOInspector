import ISOInspectorKit

#if canImport(SwiftUI)
import SwiftUI

@main
struct ISOInspectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    @StateObject private var store = ParseTreeStore()

    var body: some View {
        ParseTreeExplorerView(store: store)
            .frame(minWidth: 480, minHeight: 480)
    }
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
