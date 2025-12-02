#if canImport(Combine)
    import Combine
    import Foundation
    import ISOInspectorKit

    @MainActor final class IntegritySummaryViewModel: ObservableObject {
        enum SortOrder {
            case severity
            case offset
            case affectedNode
        }

        @Published private(set) var displayedIssues: [ParseIssue] = []
        @Published var sortOrder: SortOrder = .severity {
            didSet { if sortOrder != oldValue { scheduleUpdate() } }
        }
        @Published var severityFilter: Set<ParseIssue.Severity> = [] {
            didSet { if severityFilter != oldValue { scheduleUpdate() } }
        }

        private let issueStore: ParseIssueStore
        private var cancellables = Set<AnyCancellable>()
        private var updateTask: Task<Void, Never>?

        init(issueStore: ParseIssueStore) {
            self.issueStore = issueStore

            // Observe changes to issues in the store
            issueStore.$issues.receive(on: DispatchQueue.main).sink { [weak self] _ in
                self?.scheduleUpdate()
            }.store(in: &cancellables)

            // Initial update
            scheduleUpdate()
        }

        private func scheduleUpdate() {
            // Cancel any pending update
            updateTask?.cancel()

            // Schedule update for next run loop to avoid publishing during view updates
            updateTask = Task { @MainActor [weak self] in
                // Yield to allow the current view update cycle to complete
                await Task.yield()
                guard !Task.isCancelled else { return }
                self?.updateDisplayedIssues()
            }
        }

        private func updateDisplayedIssues() {
            var issues = issueStore.issuesSnapshot()

            // Apply severity filter
            if !severityFilter.isEmpty {
                issues = issues.filter { severityFilter.contains($0.severity) }
            }

            // Apply sorting
            switch sortOrder {
            case .severity:
                issues = issues.sorted { lhs, rhs in
                    severityRank(lhs.severity) > severityRank(rhs.severity)
                }
            case .offset:
                // Multi-field offset-based sorting:
                // 1. Primary: Sort by byteRange.lowerBound (issues without ranges sort to end)
                // 2. Secondary: Tie-break by severity rank (Error > Warning > Info)
                // 3. Tertiary: Tie-break by code lexicographically for deterministic ordering
                issues = issues.sorted { lhs, rhs in
                    let lhsOffset = lhs.byteRange?.lowerBound ?? Int64.max
                    let rhsOffset = rhs.byteRange?.lowerBound ?? Int64.max

                    if lhsOffset != rhsOffset { return lhsOffset < rhsOffset }

                    // Tie-breaker: severity rank (descending)
                    let lhsSeverity = severityRank(lhs.severity)
                    let rhsSeverity = severityRank(rhs.severity)

                    if lhsSeverity != rhsSeverity { return lhsSeverity > rhsSeverity }

                    // Final tie-breaker: code (lexicographic)
                    return lhs.code < rhs.code
                }
            case .affectedNode:
                // Multi-field affected node sorting:
                // 1. Primary: Sort by first affected node ID (issues without nodes sort to end)
                // 2. Secondary: Tie-break by severity rank (Error > Warning > Info)
                // 3. Tertiary: Tie-break by byteRange.lowerBound for stable ordering
                issues = issues.sorted { lhs, rhs in
                    let lhsNodeID = lhs.affectedNodeIDs.first ?? Int64.max
                    let rhsNodeID = rhs.affectedNodeIDs.first ?? Int64.max

                    if lhsNodeID != rhsNodeID { return lhsNodeID < rhsNodeID }

                    // Tie-breaker: severity rank (descending)
                    let lhsSeverity = severityRank(lhs.severity)
                    let rhsSeverity = severityRank(rhs.severity)

                    if lhsSeverity != rhsSeverity { return lhsSeverity > rhsSeverity }

                    // Final tie-breaker: offset for stable ordering
                    let lhsOffset = lhs.byteRange?.lowerBound ?? Int64.max
                    let rhsOffset = rhs.byteRange?.lowerBound ?? Int64.max
                    return lhsOffset < rhsOffset
                }
            }

            displayedIssues = issues
        }

        private func severityRank(_ severity: ParseIssue.Severity) -> Int {
            switch severity {
            case .error: return 3
            case .warning: return 2
            case .info: return 1
            }
        }

        func toggleSeverityFilter(_ severity: ParseIssue.Severity) {
            if severityFilter.contains(severity) {
                severityFilter.remove(severity)
            } else {
                severityFilter.insert(severity)
            }
        }

        func clearFilters() { severityFilter.removeAll() }

        // MARK: - Testing Support

        /// Waits for any pending updates to complete. For testing only.
        func waitForPendingUpdates() async {
            // Wait for the current task if it exists
            if let task = updateTask { await task.value }
            // Give a moment for any scheduled tasks to start
            await Task.yield()
            // Check again if a new task was scheduled
            if let task = updateTask { await task.value }
        }
    }
#endif
