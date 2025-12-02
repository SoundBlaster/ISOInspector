#if canImport(SwiftUI) && canImport(Combine)
    import Foundation
    import ISOInspectorKit
    import OSLog
    import UniformTypeIdentifiers

    /// Service responsible for exporting parse trees and issue summaries.
    ///
    /// This service handles:
    /// - JSON export of parse trees
    /// - Issue summary export
    /// - File save dialog coordination
    /// - Export metadata generation
    @MainActor final class ExportService {  // swiftlint:disable:this type_body_length
        // MARK: - Properties

        private let parseTreeStore: ParseTreeStore
        private let bookmarkService: BookmarkService
        private let validationConfigurationService: ValidationConfigurationService
        private let diagnostics: any DiagnosticsLogging
        private let exportLogger = Logger(subsystem: "ISOInspectorApp", category: "Export")

        private var currentDocument: DocumentRecent?

        // MARK: - Initialization

        init(
            parseTreeStore: ParseTreeStore, bookmarkService: BookmarkService,
            validationConfigurationService: ValidationConfigurationService,
            diagnostics: any DiagnosticsLogging
        ) {
            self.parseTreeStore = parseTreeStore
            self.bookmarkService = bookmarkService
            self.validationConfigurationService = validationConfigurationService
            self.diagnostics = diagnostics
        }

        // MARK: - Public Methods

        func setCurrentDocument(_ document: DocumentRecent?) { currentDocument = document }

        func canExportSelection(nodeID: ParseTreeNode.ID?) -> Bool {
            guard let nodeID else { return false }
            return findNode(with: nodeID, in: parseTreeStore.snapshot.nodes) != nil
        }

        var canExportDocument: Bool { !parseTreeStore.snapshot.nodes.isEmpty }

        func exportJSON(
            scope: ExportScope, onSuccess: @escaping (ExportStatus) -> Void,
            onFailure: @escaping (ExportStatus) -> Void
        ) async {
            await runExport(
                operation: .json, scope: scope, onSuccess: onSuccess, onFailure: onFailure
            ) { try await performJSONExport(scope: scope) }
        }

        func exportIssueSummary(
            scope: ExportScope, onSuccess: @escaping (ExportStatus) -> Void,
            onFailure: @escaping (ExportStatus) -> Void
        ) async {
            await runExport(
                operation: .issueSummary, scope: scope, onSuccess: onSuccess, onFailure: onFailure
            ) { try await performIssueSummaryExport(scope: scope) }
        }

        // MARK: - Private Methods

        private func performJSONExport(scope: ExportScope) async throws -> URL {
            let prepared = try prepareExport(scope: scope)
            let exporter = JSONParseTreeExporter()
            let data = try exporter.export(tree: prepared.tree)
            let filename = suggestedFilename(
                base: prepared.baseFilename, suffix: prepared.suffix, fileExtension: "json")
            return try await saveExportedData(
                data: data, suggestedFilename: filename, contentType: UTType.json.identifier)
        }

        private func performIssueSummaryExport(scope: ExportScope) async throws -> URL {
            let prepared = try prepareExport(scope: scope)
            let exporter = PlaintextIssueSummaryExporter()
            let metadata = makeIssueSummaryMetadata()
            let (summary, issues) = makeIssueSummaryInputs(for: scope, tree: prepared.tree)
            let data = try exporter.export(
                tree: prepared.tree, metadata: metadata, summary: summary, issues: issues)
            let filename = suggestedFilename(
                base: prepared.baseFilename, suffix: prepared.suffix, fileExtension: "txt")
            return try await saveExportedData(
                data: data, suggestedFilename: filename, contentType: UTType.plainText.identifier)
        }

        private func runExport(
            operation: ExportOperation, scope: ExportScope,
            onSuccess: @escaping (ExportStatus) -> Void,
            onFailure: @escaping (ExportStatus) -> Void, action: () async throws -> URL
        ) async {
            do {
                let destination = try await action()
                let status = makeSuccessStatus(
                    operation: operation, scope: scope, destination: destination)
                onSuccess(status)
            } catch is CancellationError {
                // User cancelled the save dialog; nothing to report.
            } catch let error as ExportError {
                let status = makeFailureStatus(error: error, operation: operation)
                onFailure(status)
            } catch {
                let status = makeFailureStatus(
                    error: .destinationUnavailable(underlying: error), operation: operation)
                onFailure(status)
            }
        }

        private func makeSuccessStatus(
            operation: ExportOperation, scope: ExportScope, destination: URL
        ) -> ExportStatus {
            exportLogger.info(
                "\(operation.successLogEvent): scope=\(scope.logDescription, privacy: .public); destination=\(destination.path, privacy: .public)"
            )
            return ExportStatus(
                title: "Export Complete",
                message: operation.successMessagePrefix + "\(destination.lastPathComponent).",
                destinationURL: destination, isSuccess: true)
        }

        private func makeFailureStatus(error: ExportError, operation: ExportOperation)
            -> ExportStatus
        {
            exportLogger.error(
                "\(operation.failureLogEvent): error=\(error.logDescription, privacy: .public)")
            diagnostics.error("\(operation.diagnosticsContext) failed: \(error.logDescription)")
            return ExportStatus(
                title: "Export Failed",
                message: error.errorDescription ?? "\(operation.diagnosticsContext) failed.",
                destinationURL: nil, isSuccess: false)
        }

        private func saveExportedData(data: Data, suggestedFilename: String, contentType: String)
            async throws -> URL
        {
            let configuration = FilesystemSaveConfiguration(
                allowedContentTypes: [contentType], suggestedFilename: suggestedFilename)

            let scopedURL: SecurityScopedURL
            do {
                scopedURL = try await bookmarkService.filesystemAccess.saveFile(
                    configuration: configuration)
            } catch let accessError as FilesystemAccessError {
                if case .dialogUnavailable = accessError { throw CancellationError() }
                throw ExportError.destinationUnavailable(underlying: accessError)
            } catch is CancellationError { throw CancellationError() } catch {
                throw ExportError.destinationUnavailable(underlying: error)
            }

            defer { scopedURL.revoke() }

            do {
                return try scopedURL.withAccess { url in
                    try data.write(to: url, options: [.atomic])
                    return url
                }
            } catch { throw ExportError.writeFailed(url: scopedURL.url, underlying: error) }
        }

        private func prepareExport(scope: ExportScope) throws -> PreparedExport {
            let snapshot = parseTreeStore.snapshot
            guard !snapshot.nodes.isEmpty else { throw ExportError.emptyTree }
            let base = baseFilename()

            switch scope {
            case .document:
                return PreparedExport(
                    tree: ParseTree(
                        nodes: snapshot.nodes, validationIssues: snapshot.validationIssues,
                        validationMetadata: nil), baseFilename: base, suffix: nil)
            case .selection(let nodeID):
                guard let node = findNode(with: nodeID, in: snapshot.nodes) else {
                    throw ExportError.nodeNotFound
                }
                let suffix = selectionFilenameSuffix(for: node)
                return PreparedExport(
                    tree: ParseTree(
                        nodes: [node], validationIssues: collectIssues(from: node),
                        validationMetadata: nil), baseFilename: base, suffix: suffix)
            }
        }

        private func baseFilename() -> String {
            if let current = currentDocument {
                let trimmed = current.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return sanitisedFilenameStem(trimmed) }
            }
            if let url = parseTreeStore.fileURL {
                return sanitisedFilenameStem(url.deletingPathExtension().lastPathComponent)
            }
            return "parse-tree"
        }

        private func suggestedFilename(base: String, suffix: String?, fileExtension: String)
            -> String
        {
            var stem = base
            if let suffix, !suffix.isEmpty { stem.append("-\(suffix)") }
            let lowercasedStem = stem.lowercased()
            let lowercasedExtension = fileExtension.lowercased()
            if lowercasedStem.hasSuffix(".\(lowercasedExtension)") { return stem }
            let filename = "\(stem).\(fileExtension)"
            return filename
        }

        private func selectionFilenameSuffix(for node: ParseTreeNode) -> String {
            let rawType = node.header.type.rawValue
            let sanitizedType = rawType.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
            return "\(sanitizedType)-offset-\(node.header.startOffset)"
        }

        private func sanitisedFilenameStem(_ raw: String) -> String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "parse-tree" }
            let components = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            let stem: String
            if components.count > 1 {
                stem = components.dropLast().joined(separator: ".")
            } else {
                stem = trimmed
            }
            let sanitized = stem.replacingOccurrences(of: "/", with: "-").replacingOccurrences(
                of: ":", with: "-"
            ).replacingOccurrences(of: "\u{0000}", with: "").replacingOccurrences(
                of: " ", with: "-")
            return sanitized.isEmpty ? "parse-tree" : sanitized
        }

        private func collectIssues(from node: ParseTreeNode) -> [ValidationIssue] {
            var issues = node.validationIssues
            for child in node.children { issues.append(contentsOf: collectIssues(from: child)) }
            return issues
        }

        private func makeIssueSummaryInputs(for scope: ExportScope, tree: ParseTree) -> (
            ParseIssueStore.IssueSummary, [ParseIssue]
        ) {
            switch scope {
            case .document:
                return (
                    parseTreeStore.issueStore.makeIssueSummary(),
                    parseTreeStore.issueStore.issuesSnapshot()
                )
            case .selection:
                let issues = collectParseIssues(from: tree.nodes)
                let summary = makeIssueSummary(for: issues, in: tree)
                return (summary, issues)
            }
        }

        private func collectParseIssues(from nodes: [ParseTreeNode]) -> [ParseIssue] {
            nodes.flatMap(collectParseIssues(from:))
        }

        private func collectParseIssues(from node: ParseTreeNode) -> [ParseIssue] {
            var issues = node.issues
            for child in node.children {
                issues.append(contentsOf: collectParseIssues(from: child))
            }
            return issues
        }

        private func makeIssueSummary(for issues: [ParseIssue], in tree: ParseTree)
            -> ParseIssueStore.IssueSummary
        {
            var counts: [ParseIssue.Severity: Int] = [:]
            for severity in ParseIssue.Severity.allCases { counts[severity] = 0 }
            var deepestDepth = 0
            let depthIndex = makeDepthIndex(from: tree.nodes)
            for issue in issues {
                counts[issue.severity, default: 0] += 1
                for nodeID in issue.affectedNodeIDs {
                    if let depth = depthIndex[nodeID] { deepestDepth = max(deepestDepth, depth) }
                }
            }
            let metrics = ParseIssueStore.IssueMetrics(
                countsBySeverity: counts, deepestAffectedDepth: deepestDepth)
            return ParseIssueStore.IssueSummary(metrics: metrics, totalCount: issues.count)
        }

        private func makeDepthIndex(from nodes: [ParseTreeNode]) -> [Int64: Int] {
            var index: [Int64: Int] = [:]
            func traverse(nodes: [ParseTreeNode], depth: Int) {
                for node in nodes {
                    index[node.id] = depth
                    if !node.children.isEmpty { traverse(nodes: node.children, depth: depth + 1) }
                }
            }
            traverse(nodes: nodes, depth: 0)
            return index
        }

        private func findNode(with id: ParseTreeNode.ID, in nodes: [ParseTreeNode])
            -> ParseTreeNode?
        {
            for node in nodes {
                if node.id == id { return node }
                if let match = findNode(with: id, in: node.children) { return match }
            }
            return nil
        }

        private func makeIssueSummaryMetadata() -> PlaintextIssueSummaryExporter.Metadata {
            let resolvedURL = resolvedFileURL()
            let path: String
            if let resolvedURL { path = resolvedURL.path } else { path = baseFilename() }

            let fileSize: Int64?
            if let resolvedURL {
                let attributes = try? FileManager.default.attributesOfItem(atPath: resolvedURL.path)
                if let number = attributes?[.size] as? NSNumber {
                    fileSize = number.int64Value
                } else {
                    fileSize = nil
                }
            } else {
                fileSize = nil
            }

            return PlaintextIssueSummaryExporter.Metadata(
                filePath: path, fileSize: fileSize, analyzedAt: Date(), sha256: nil)
        }

        private func resolvedFileURL() -> URL? {
            if let url = parseTreeStore.fileURL?.standardizedFileURL { return url }
            if let url = currentDocument?.url.standardizedFileURL { return url }
            return nil
        }

        private struct PreparedExport {
            let tree: ParseTree
            let baseFilename: String
            let suffix: String?
        }

        // MARK: - Nested Types

        enum ExportScope: Equatable, Sendable {
            case document
            case selection(ParseTreeNode.ID)

            var logDescription: String {
                switch self {
                case .document: return "document"
                case .selection(let identifier): return "selection-\(identifier)"
                }
            }
        }

        struct ExportStatus: Identifiable, Equatable {
            let id: UUID
            let title: String
            let message: String
            let destinationURL: URL?
            let isSuccess: Bool

            init(
                id: UUID = UUID(), title: String, message: String, destinationURL: URL?,
                isSuccess: Bool
            ) {
                self.id = id
                self.title = title
                self.message = message
                self.destinationURL = destinationURL
                self.isSuccess = isSuccess
            }
        }
    }

    // MARK: - Supporting Types

    private enum ExportOperation {
        case json
        case issueSummary

        var logIdentifier: String {
            switch self {
            case .json: return "json"
            case .issueSummary: return "issue-summary"
            }
        }

        var successMessagePrefix: String {
            switch self {
            case .json: return "Saved JSON to "
            case .issueSummary: return "Saved issue summary to "
            }
        }

        var diagnosticsContext: String {
            switch self {
            case .json: return "JSON export"
            case .issueSummary: return "Issue summary export"
            }
        }

        var successLogEvent: String {
            switch self {
            case .json: return "JSON export succeeded"
            case .issueSummary: return "Issue summary export succeeded"
            }
        }

        var failureLogEvent: String {
            switch self {
            case .json: return "JSON export failed"
            case .issueSummary: return "Issue summary export failed"
            }
        }
    }

    enum ExportError: LocalizedError {
        case emptyTree
        case nodeNotFound
        case destinationUnavailable(underlying: Error)
        case writeFailed(url: URL, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .emptyTree: return "Run a parse before exporting."
            case .nodeNotFound:
                return
                    "The selected box is no longer available. Refresh the selection and try again."
            case .destinationUnavailable(let underlying):
                return
                    "ISO Inspector couldn't access the chosen destination. \(underlying.localizedDescription)"
            case .writeFailed(let url, let underlying):
                return
                    "ISO Inspector couldn't write to \"\(url.lastPathComponent)\". \(underlying.localizedDescription)"
            }
        }

        var logDescription: String {
            switch self {
            case .emptyTree: return "empty-parse-tree"
            case .nodeNotFound: return "selection-missing"
            case .destinationUnavailable(let underlying):
                return "destination-unavailable: \(String(describing: underlying))"
            case .writeFailed(let url, let underlying):
                return "write-failed: url=\(url.path) underlying=\(String(describing: underlying))"
            }
        }
    }
#endif
