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
    public struct IssueMetrics: Equatable, Sendable {
        public let errorCount: Int
        public let warningCount: Int
        public let infoCount: Int
        public let deepestAffectedDepth: Int

        public init(
            errorCount: Int = 0,
            warningCount: Int = 0,
            infoCount: Int = 0,
            deepestAffectedDepth: Int = 0
        ) {
            self.errorCount = errorCount
            self.warningCount = warningCount
            self.infoCount = infoCount
            self.deepestAffectedDepth = deepestAffectedDepth
        }
    }

    @Published public private(set) var issues: [ParseIssue]
    @Published public private(set) var metrics: IssueMetrics

    private var issuesByNodeID: [Int64: [ParseIssue]]
    private var errorCount: Int
    private var warningCount: Int
    private var infoCount: Int
    private var deepestDepth: Int

    public init(issues: [ParseIssue] = []) {
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
        performOnMain { [self] in
            self.append(issue, depth: depth)
        }
    }

    public func record(
        _ issues: [ParseIssue],
        depthResolver: (@Sendable (ParseIssue) -> Int?)? = nil
    ) {
        performOnMain { [self] in
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
        performOnMain { [self] in
            self.resetStorage()
            for issue in issues {
                let depth = depthResolver?(issue)
                self.append(issue, depth: depth)
            }
        }
    }

    public func issues(forNodeID nodeID: Int64) -> [ParseIssue] {
        readOnMain { issuesByNodeID[nodeID] ?? [] }
    }

    public func issues(in range: Range<Int64>) -> [ParseIssue] {
        readOnMain {
            issues.filter { issue in
                guard let byteRange = issue.byteRange else { return false }
                return Self.intersects(byteRange, range)
            }
        }
    }

    public func reset() {
        performOnMain { [self] in
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

    private func performOnMain(_ action: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    private func readOnMain<T>(_ action: () -> T) -> T {
        if Thread.isMainThread {
            return action()
        }
        return DispatchQueue.main.sync(execute: action)
    }

    private static func intersects(_ lhs: Range<Int64>, _ rhs: Range<Int64>) -> Bool {
        lhs.lowerBound < rhs.upperBound && rhs.lowerBound < lhs.upperBound
    }
}

extension ParseIssueStore: @unchecked Sendable {}
