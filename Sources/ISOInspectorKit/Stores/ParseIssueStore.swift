#if canImport(Combine)
import Combine
#else
public protocol ObservableObject: AnyObject {}
@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif
import Foundation

public final class ParseIssueStore: ObservableObject {
    private let queue: DispatchQueue
    private let queueSpecificKey = DispatchSpecificKey<UUID>()
    private let queueSpecificValue = UUID()
    public struct IssueMetrics: Equatable, Sendable {
        private let counts: [ParseIssue.Severity: Int]
        public let deepestAffectedDepth: Int

        public init(
            countsBySeverity: [ParseIssue.Severity: Int] = [:],
            deepestAffectedDepth: Int = 0
        ) {
            var normalized: [ParseIssue.Severity: Int] = [:]
            for severity in ParseIssue.Severity.allCases {
                normalized[severity] = countsBySeverity[severity, default: 0]
            }
            self.counts = normalized
            self.deepestAffectedDepth = deepestAffectedDepth
        }

        public init(
            errorCount: Int = 0,
            warningCount: Int = 0,
            infoCount: Int = 0,
            deepestAffectedDepth: Int = 0
        ) {
            self.init(
                countsBySeverity: [
                    .error: errorCount,
                    .warning: warningCount,
                    .info: infoCount,
                ],
                deepestAffectedDepth: deepestAffectedDepth
            )
        }

        public var countsBySeverity: [ParseIssue.Severity: Int] { counts }

        public func count(for severity: ParseIssue.Severity) -> Int {
            counts[severity, default: 0]
        }

        public var errorCount: Int { count(for: .error) }
        public var warningCount: Int { count(for: .warning) }
        public var infoCount: Int { count(for: .info) }

        public var totalCount: Int {
            counts.values.reduce(0, +)
        }
    }

    public struct IssueSummary: Equatable, Sendable {
        public let metrics: IssueMetrics
        public let totalCount: Int

        public init(
            metrics: IssueMetrics = IssueMetrics(),
            totalCount: Int = 0
        ) {
            self.metrics = metrics
            self.totalCount = totalCount
        }

        public var countsBySeverity: [ParseIssue.Severity: Int] {
            metrics.countsBySeverity
        }

        public var deepestAffectedDepth: Int {
            metrics.deepestAffectedDepth
        }

        public func count(for severity: ParseIssue.Severity) -> Int {
            metrics.count(for: severity)
        }
    }

    @Published public private(set) var issues: [ParseIssue]
    @Published public private(set) var metrics: IssueMetrics

    private var issuesByNodeID: [Int64: [ParseIssue]]
    private var errorCount: Int
    private var warningCount: Int
    private var infoCount: Int
    private var deepestDepth: Int

    public init(
        issues: [ParseIssue] = [],
        queue: DispatchQueue = .main
    ) {
        self.queue = queue
        queue.setSpecific(key: queueSpecificKey, value: queueSpecificValue)
        self.issues = []
        self.metrics = IssueMetrics()
        self.issuesByNodeID = [:]
        self.errorCount = 0
        self.warningCount = 0
        self.infoCount = 0
        self.deepestDepth = 0
        if !issues.isEmpty {
            replaceAll(with: issues)
        }
    }

    public func record(_ issue: ParseIssue, depth: Int? = nil) {
        performOnQueue { [self] in
            self.append(issue, depth: depth)
        }
    }

    public func record(
        _ issues: [ParseIssue],
        depthResolver: (@Sendable (ParseIssue) -> Int?)? = nil
    ) {
        performOnQueue { [self] in
            for issue in issues {
                let depth = depthResolver?(issue)
                self.append(issue, depth: depth)
            }
        }
    }

    public func replaceAll(
        with issues: [ParseIssue],
        depthResolver: (@Sendable (ParseIssue) -> Int?)? = nil
    ) {
        performOnQueue { [self] in
            self.resetStorage()
            for issue in issues {
                let depth = depthResolver?(issue)
                self.append(issue, depth: depth)
            }
        }
    }

    public func issues(forNodeID nodeID: Int64) -> [ParseIssue] {
        readOnQueue { issuesByNodeID[nodeID] ?? [] }
    }

    public func issues(in range: Range<Int64>) -> [ParseIssue] {
        readOnQueue {
            issues.filter { issue in
                guard let byteRange = issue.byteRange else { return false }
                return Self.intersects(byteRange, range)
            }
        }
    }

    public func metricsSnapshot() -> IssueMetrics {
        readOnQueue { metrics }
    }

    public func makeIssueSummary() -> IssueSummary {
        readOnQueue {
            IssueSummary(
                metrics: metrics,
                totalCount: issues.count
            )
        }
    }

    public func issuesSnapshot() -> [ParseIssue] {
        readOnQueue { issues }
    }

    public func reset() {
        performOnQueue { [self] in
            self.resetStorage()
        }
    }

    private func append(_ issue: ParseIssue, depth: Int?) {
        issues.append(issue)
        for nodeID in issue.affectedNodeIDs {
            issuesByNodeID[nodeID, default: []].append(issue)
        }
        switch issue.severity {
        case .error:
            errorCount += 1
        case .warning:
            warningCount += 1
        case .info:
            infoCount += 1
        }
        let resolvedDepth = max(depth ?? issue.affectedNodeIDs.count, 0)
        deepestDepth = max(deepestDepth, resolvedDepth)
        metrics = IssueMetrics(
            errorCount: errorCount,
            warningCount: warningCount,
            infoCount: infoCount,
            deepestAffectedDepth: deepestDepth
        )
    }

    private func resetStorage() {
        issues = []
        issuesByNodeID = [:]
        errorCount = 0
        warningCount = 0
        infoCount = 0
        deepestDepth = 0
        metrics = IssueMetrics()
    }

    private func performOnQueue(_ action: @escaping @Sendable () -> Void) {
        if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            action()
        } else {
            queue.async(execute: action)
        }
    }

    private func readOnQueue<T>(_ action: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueSpecificKey) == queueSpecificValue {
            return action()
        }
        return queue.sync(execute: action)
    }

    private static func intersects(_ lhs: Range<Int64>, _ rhs: Range<Int64>) -> Bool {
        lhs.lowerBound < rhs.upperBound && rhs.lowerBound < lhs.upperBound
    }
}

extension ParseIssueStore: @unchecked Sendable {}
