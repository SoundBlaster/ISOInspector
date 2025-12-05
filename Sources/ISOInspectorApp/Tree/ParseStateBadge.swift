import FoundationUI
import SwiftUI

extension ParseTreeExplorerView {
    struct ParseStateBadge: View {
        let state: ParseTreeStoreState

        var body: some View { Badge(text: stateDescription, level: badgeLevel) }

        private var stateDescription: String {
            switch state {
            case .idle: return "Idle"
            case .parsing: return "Parsing"
            case .finished: return "Finished"
            case .failed(let message): return "Failed: \(message)"
            }
        }

        private var badgeLevel: BadgeLevel {
            switch state {
            case .idle: return .info
            case .parsing: return .info
            case .finished: return .success
            case .failed: return .error
            }
        }
    }
}
