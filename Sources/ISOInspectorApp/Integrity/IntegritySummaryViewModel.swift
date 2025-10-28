#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

@MainActor
final class IntegritySummaryViewModel: ObservableObject {
    enum SortOrder {
        case severity
        case offset
        case affectedNode
    }

    @Published private(set) var displayedIssues: [ParseIssue] = []
    @Published var sortOrder: SortOrder = .severity
    @Published var severityFilter: Set<ParseIssue.Severity> = []

    private let issueStore: ParseIssueStore
    private var cancellables = Set<AnyCancellable>()

    init(issueStore: ParseIssueStore) {
        self.issueStore = issueStore

        // Observe changes to issues in the store
        issueStore.$issues
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplayedIssues()
            }
            .store(in: &cancellables)

        // Observe changes to sort order
        $sortOrder
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateDisplayedIssues()
            }
            .store(in: &cancellables)

        // Observe changes to severity filter
        $severityFilter
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateDisplayedIssues()
            }
            .store(in: &cancellables)

        // Initial update
        updateDisplayedIssues()
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
            issues = issues.sorted { lhs, rhs in
                // @todo #T36-001 Implement offset-based sorting
                (lhs.byteRange?.lowerBound ?? 0) < (rhs.byteRange?.lowerBound ?? 0)
            }
        case .affectedNode:
            issues = issues.sorted { lhs, rhs in
                // @todo #T36-002 Implement affected node sorting
                (lhs.affectedNodeIDs.first ?? 0) < (rhs.affectedNodeIDs.first ?? 0)
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

    func clearFilters() {
        severityFilter.removeAll()
    }
}
#endif
