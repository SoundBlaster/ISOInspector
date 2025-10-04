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
    private let focusAreas = ISOInspectorKit.initialFocusAreas

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ISOInspectorKit.projectName)
                .font(.largeTitle)
                .bold()
            Text("Initial focus areas")
                .font(.headline)
            ForEach(focusAreas, id: \.self) { focus in
                Text(focus)
                    .font(.body)
            }
        }
        .padding()
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
