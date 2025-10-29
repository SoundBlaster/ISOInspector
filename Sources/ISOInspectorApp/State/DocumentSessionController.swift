#if canImport(SwiftUI) && canImport(Combine)
    import Combine
    import Dispatch
    import Foundation
    import ISOInspectorKit
    import OSLog

    import UniformTypeIdentifiers

    typealias BookmarkResolutionState = BookmarkPersistenceStore.Record.ResolutionState

    protocol BookmarkPersistenceManaging: Sendable {
        func record(for file: URL) throws -> BookmarkPersistenceStore.Record?
        func record(withID id: UUID) throws -> BookmarkPersistenceStore.Record?
        @discardableResult
        func upsertBookmark(for file: URL, bookmarkData: Data) throws
            -> BookmarkPersistenceStore.Record
        @discardableResult
        func markResolution(for file: URL, state: BookmarkResolutionState) throws
            -> BookmarkPersistenceStore.Record?
        func removeBookmark(for file: URL) throws
    }

    extension BookmarkPersistenceStore: BookmarkPersistenceManaging {}

    @MainActor
    final class DocumentSessionController: ObservableObject {
        @Published private(set) var recents: [DocumentRecent]
        @Published private(set) var currentDocument: DocumentRecent?
        @Published private(set) var loadFailure: DocumentLoadFailure?
        @Published private(set) var exportStatus: ExportStatus?
        @Published private(set) var validationConfiguration: ValidationConfiguration
        @Published private(set) var globalValidationConfiguration: ValidationConfiguration
        @Published private(set) var validationPresets: [ValidationPreset]
        @Published private(set) var isUsingWorkspaceValidationOverride: Bool
        @Published private(set) var issueMetrics: ParseIssueStore.IssueMetrics

        let parseTreeStore: ParseTreeStore
        let annotations: AnnotationBookmarkSession
        let documentViewModel: DocumentViewModel

        private let recentsStore: DocumentRecentsStoring
        private let pipelineFactory: () -> ParsePipeline
        private let readerFactory: (URL) throws -> RandomAccessReader
        private let workQueue: DocumentSessionWorkQueue
        private let recentLimit: Int
        private let sessionStore: WorkspaceSessionStoring?
        private let diagnostics: any DiagnosticsLogging
        private let bookmarkStore: BookmarkPersistenceManaging?
        private let filesystemAccess: FilesystemAccess
        private let bookmarkDataProvider: (SecurityScopedURL) -> Data?
        private let validationConfigurationStore: ValidationConfigurationPersisting?

        private let logger = Logger(subsystem: "ISOInspectorApp", category: "DocumentSession")
        private let exportLogger = Logger(subsystem: "ISOInspectorApp", category: "Export")

        private var currentSessionID: UUID?
        private var currentSessionCreatedAt: Date?
        private var sessionFileIDs: [String: UUID] = [:]
        private var sessionBookmarkDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]
        private var isRestoringSession = false
        private var pendingSessionSnapshot: WorkspaceSessionSnapshot?
        private var annotationsSelectionCancellable: AnyCancellable?
        private var issueMetricsCancellable: AnyCancellable?
        private var lastFailedRecent: DocumentRecent?
        private var activeSecurityScopedURL: SecurityScopedURL?
        private var sessionValidationConfigurations: [String: ValidationConfiguration] = [:]
        private var presetByID: [String: ValidationPreset] = [:]
        private var currentConfigurationKey: String?
        private var defaultValidationPresetID: String
        private var latestSelectionNodeID: Int64?

        enum ValidationConfigurationScope {
            case global
            case workspace
        }

        init(
            parseTreeStore: ParseTreeStore? = nil,
            annotations: AnnotationBookmarkSession? = nil,
            recentsStore: DocumentRecentsStoring,
            sessionStore: WorkspaceSessionStoring? = nil,
            pipelineFactory: @escaping () -> ParsePipeline = { .live(options: .tolerant) },
            readerFactory: @escaping (URL) throws -> RandomAccessReader = {
                try ChunkedFileReader(fileURL: $0)
            },
            workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
            diagnostics: (any DiagnosticsLogging)? = nil,
            recentLimit: Int = 10,
            bookmarkStore: BookmarkPersistenceManaging? = nil,
            filesystemAccess: FilesystemAccess = .live(),
            bookmarkDataProvider: ((SecurityScopedURL) -> Data?)? = nil,
            validationConfigurationStore: ValidationConfigurationPersisting? = nil,
            validationPresetLoader: (() throws -> [ValidationPreset])? = nil
        ) {
            let resolvedParseTreeStore = parseTreeStore ?? ParseTreeStore()
            let resolvedAnnotations = annotations ?? AnnotationBookmarkSession(store: nil)

            self.parseTreeStore = resolvedParseTreeStore
            self.annotations = resolvedAnnotations
            self.documentViewModel = DocumentViewModel(
                store: resolvedParseTreeStore, annotations: resolvedAnnotations)
            self.issueMetrics = resolvedParseTreeStore.issueMetrics
            self.recentsStore = recentsStore
            self.sessionStore = sessionStore
            self.pipelineFactory = pipelineFactory
            self.readerFactory = readerFactory
            self.workQueue = workQueue
            self.recentLimit = recentLimit
            self.diagnostics =
                diagnostics
                ?? DiagnosticsLogger(
                    subsystem: "ISOInspectorApp",
                    category: "DocumentSessionPersistence"
                )
            self.bookmarkStore = bookmarkStore
            self.filesystemAccess = filesystemAccess
            if let bookmarkDataProvider {
                self.bookmarkDataProvider = bookmarkDataProvider
            } else {
                self.bookmarkDataProvider = { scopedURL in
                    try? filesystemAccess.createBookmark(for: scopedURL)
                }
            }
            self.validationConfigurationStore = validationConfigurationStore

            let loader = validationPresetLoader ?? { try ValidationPreset.loadBundledPresets() }
            var loadedPresets: [ValidationPreset] = []
            do {
                loadedPresets = try loader()
            } catch {
                self.diagnostics.error("Failed to load validation presets: \(error)")
            }
            self.validationPresets = loadedPresets
            let presetByID = Dictionary(uniqueKeysWithValues: loadedPresets.map { ($0.id, $0) })
            self.presetByID = presetByID
            let defaultPresetID = Self.defaultPresetID(from: loadedPresets)
            self.defaultValidationPresetID = defaultPresetID

            let loadedGlobal: ValidationConfiguration
            if let validationConfigurationStore {
                do {
                    loadedGlobal =
                        try validationConfigurationStore.loadConfiguration()
                        ?? ValidationConfiguration(activePresetID: defaultValidationPresetID)
                } catch {
                    self.diagnostics.error("Failed to load validation configuration: \(error)")
                    loadedGlobal = ValidationConfiguration(
                        activePresetID: defaultValidationPresetID)
                }
            } else {
                loadedGlobal = ValidationConfiguration(activePresetID: defaultValidationPresetID)
            }

            let normalizedGlobal = Self.normalizedConfiguration(
                loadedGlobal,
                presetByID: presetByID,
                defaultPresetID: defaultPresetID
            )
            self.globalValidationConfiguration = normalizedGlobal
            self.validationConfiguration = normalizedGlobal
            self.isUsingWorkspaceValidationOverride = false
            self.currentConfigurationKey = nil

            self.recents = (try? recentsStore.load()) ?? []
            migrateRecentsForBookmarkStore()

            latestSelectionNodeID = resolvedAnnotations.currentSelectedNodeID
            annotationsSelectionCancellable = resolvedAnnotations.$currentSelectedNodeID
                .dropFirst()
                .sink { [weak self] value in
                    guard let self else { return }
                    self.latestSelectionNodeID = value
                    guard !self.recents.isEmpty, !self.isRestoringSession else { return }
                    self.persistSession()
                }

            issueMetricsCancellable = resolvedParseTreeStore.$issueMetrics
                .receive(on: DispatchQueue.main)
                .sink { [weak self] metrics in
                    self?.issueMetrics = metrics
                }

            applyValidationConfigurationFilter()

            if let sessionStore, let snapshot = try? sessionStore.loadCurrentSession() {
                currentSessionID = snapshot.id
                currentSessionCreatedAt = snapshot.createdAt
                applySessionSnapshot(snapshot)
                pendingSessionSnapshot = snapshot
                restoreSessionIfNeeded()
            }
        }

        deinit {
            // Clean up security-scoped resource access on deallocation
            activeSecurityScopedURL?.revoke()
        }

        func openDocument(at url: URL) {
            let standardized = url.standardizedFileURL
            let baseRecent = DocumentRecent(
                url: standardized,
                bookmarkData: nil,
                displayName: url.lastPathComponent,
                lastOpened: Date()
            )
            openDocument(recent: baseRecent)
        }

        func openRecent(_ recent: DocumentRecent) {
            openDocument(
                recent: recent,
                restoredSelection: nil,
                preResolvedScope: nil,
                failureRecent: recent
            )
        }

        func removeRecent(at offsets: IndexSet) {
            var didRemove = false
            let urls = offsets.compactMap { index -> URL? in
                guard recents.indices.contains(index) else { return nil }
                didRemove = true
                return recents[index].url
            }
            for url in urls {
                removeRecent(with: url)
            }
            if !didRemove, !offsets.isEmpty, recents.isEmpty {
                persistSession()
            }
        }

        func dismissLoadFailure() {
            loadFailure = nil
            lastFailedRecent = nil
        }

        func retryLastFailure() {
            guard let recent = lastFailedRecent else { return }
            openDocument(recent: recent)
        }

        func dismissExportStatus() {
            exportStatus = nil
        }

        func focusIntegrityDiagnostics() {
            if let nodeID = parseTreeStore.issueStore.issues.first?.affectedNodeIDs.first {
                documentViewModel.nodeViewModel.select(nodeID: nodeID)
            }
        }

        func selectValidationPreset(_ presetID: String, scope: ValidationConfigurationScope) {
            guard presetByID[presetID] != nil else { return }
            switch scope {
            case .global:
                var configuration = globalValidationConfiguration
                configuration.activePresetID = presetID
                configuration.ruleOverrides.removeAll()
                updateGlobalConfiguration(configuration)
            case .workspace:
                guard let key = currentConfigurationKey else { return }
                var configuration =
                    sessionValidationConfigurations[key]
                    ?? globalValidationConfiguration
                configuration.activePresetID = presetID
                configuration.ruleOverrides.removeAll()
                updateWorkspaceConfiguration(configuration)
            }
        }

        func setValidationRule(
            _ rule: ValidationRuleIdentifier,
            isEnabled: Bool,
            scope: ValidationConfigurationScope
        ) {
            switch scope {
            case .global:
                var configuration = globalValidationConfiguration
                applyOverride(on: &configuration, rule: rule, isEnabled: isEnabled)
                updateGlobalConfiguration(configuration)
            case .workspace:
                guard let key = currentConfigurationKey else { return }
                var configuration =
                    sessionValidationConfigurations[key]
                    ?? globalValidationConfiguration
                applyOverride(on: &configuration, rule: rule, isEnabled: isEnabled)
                updateWorkspaceConfiguration(configuration)
            }
        }

        func resetWorkspaceValidationOverrides() {
            updateWorkspaceConfiguration(globalValidationConfiguration)
        }

        func exportJSON(scope: ExportScope) async {
            await runExport(operation: .json, scope: scope) {
                try await performJSONExport(scope: scope)
            }
        }

        func exportIssueSummary(scope: ExportScope) async {
            await runExport(operation: .issueSummary, scope: scope) {
                try await performIssueSummaryExport(scope: scope)
            }
        }

        func canExportSelection(nodeID: ParseTreeNode.ID?) -> Bool {
            guard let nodeID else { return false }
            return findNode(with: nodeID, in: parseTreeStore.snapshot.nodes) != nil
        }

        var canExportDocument: Bool {
            !parseTreeStore.snapshot.nodes.isEmpty
        }

        var allowedContentTypes: [UTType] {
            [.mpeg4Movie, .quickTimeMovie]
        }

        private func performJSONExport(scope: ExportScope) async throws -> URL {
            let prepared = try prepareExport(scope: scope)
            let exporter = JSONParseTreeExporter()
            let data = try exporter.export(tree: prepared.tree)
            let filename = suggestedFilename(
                base: prepared.baseFilename,
                suffix: prepared.suffix,
                fileExtension: "json"
            )
            return try await saveExportedData(
                data: data,
                suggestedFilename: filename,
                contentType: UTType.json.identifier
            )
        }

        private func runExport(
            operation: ExportOperation,
            scope: ExportScope,
            action: () async throws -> URL
        ) async {
            do {
                let destination = try await action()
                handleExportSuccess(operation: operation, scope: scope, destination: destination)
            } catch is CancellationError {
                // User cancelled the save dialog; nothing to report.
            } catch let error as ExportError {
                handleExportError(error, operation: operation)
            } catch {
                handleExportError(
                    .destinationUnavailable(underlying: error),
                    operation: operation
                )
            }
        }

        private func handleExportSuccess(
            operation: ExportOperation,
            scope: ExportScope,
            destination: URL
        ) {
            exportStatus = ExportStatus(
                title: "Export Complete",
                message: operation.successMessagePrefix + "\(destination.lastPathComponent)”.",
                destinationURL: destination,
                isSuccess: true
            )
            exportLogger.info(
                "\(operation.successLogEvent): scope=\(scope.logDescription, privacy: .public); destination=\(destination.path, privacy: .public)"
            )
        }

        private func performIssueSummaryExport(scope: ExportScope) async throws -> URL {
            let prepared = try prepareExport(scope: scope)
            let exporter = PlaintextIssueSummaryExporter()
            let metadata = makeIssueSummaryMetadata()
            let (summary, issues) = makeIssueSummaryInputs(for: scope, tree: prepared.tree)
            let data = try exporter.export(
                tree: prepared.tree,
                metadata: metadata,
                summary: summary,
                issues: issues
            )
            let filename = suggestedFilename(
                base: prepared.baseFilename,
                suffix: prepared.suffix,
                fileExtension: "txt"
            )
            return try await saveExportedData(
                data: data,
                suggestedFilename: filename,
                contentType: UTType.plainText.identifier
            )
        }

        private func makeIssueSummaryMetadata() -> PlaintextIssueSummaryExporter.Metadata {
            let resolvedURL = resolvedFileURL()
            let path: String
            if let resolvedURL {
                path = resolvedURL.path
            } else {
                path = baseFilename()
            }

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
                filePath: path,
                fileSize: fileSize,
                analyzedAt: Date(),
                sha256: nil
            )
        }

        private func resolvedFileURL() -> URL? {
            if let url = parseTreeStore.fileURL?.standardizedFileURL {
                return url
            }
            if let url = currentDocument?.url.standardizedFileURL {
                return url
            }
            return nil
        }

        private func saveExportedData(
            data: Data,
            suggestedFilename: String,
            contentType: String
        ) async throws -> URL {
            let configuration = FilesystemSaveConfiguration(
                allowedContentTypes: [contentType],
                suggestedFilename: suggestedFilename
            )

            let scopedURL: SecurityScopedURL
            do {
                scopedURL = try await filesystemAccess.saveFile(configuration: configuration)
            } catch let accessError as FilesystemAccessError {
                if case .dialogUnavailable = accessError {
                    throw CancellationError()
                }
                throw ExportError.destinationUnavailable(underlying: accessError)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ExportError.destinationUnavailable(underlying: error)
            }

            defer { scopedURL.revoke() }

            do {
                return try scopedURL.withAccess { url in
                    try data.write(to: url, options: [.atomic])
                    return url
                }
            } catch {
                throw ExportError.writeFailed(url: scopedURL.url, underlying: error)
            }
        }

        private func prepareExport(scope: ExportScope) throws -> PreparedExport {
            let snapshot = parseTreeStore.snapshot
            guard !snapshot.nodes.isEmpty else {
                throw ExportError.emptyTree
            }
            let base = baseFilename()

            switch scope {
            case .document:
                return PreparedExport(
                    tree: ParseTree(
                        nodes: snapshot.nodes,
                        validationIssues: snapshot.validationIssues,
                        validationMetadata: nil
                    ),
                    baseFilename: base,
                    suffix: nil
                )
            case .selection(let nodeID):
                guard let node = findNode(with: nodeID, in: snapshot.nodes) else {
                    throw ExportError.nodeNotFound
                }
                let suffix = selectionFilenameSuffix(for: node)
                return PreparedExport(
                    tree: ParseTree(
                        nodes: [node],
                        validationIssues: collectIssues(from: node),
                        validationMetadata: nil
                    ),
                    baseFilename: base,
                    suffix: suffix
                )
            }
        }

        private func baseFilename() -> String {
            if let current = currentDocument {
                let trimmed = current.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return sanitisedFilenameStem(trimmed)
                }
            }
            if let url = parseTreeStore.fileURL {
                return sanitisedFilenameStem(url.deletingPathExtension().lastPathComponent)
            }
            return "parse-tree"
        }

        private func suggestedFilename(
            base: String,
            suffix: String?,
            fileExtension: String
        ) -> String {
            var stem = base
            if let suffix, !suffix.isEmpty {
                stem.append("-\(suffix)")
            }
            let lowercasedStem = stem.lowercased()
            let lowercasedExtension = fileExtension.lowercased()
            if lowercasedStem.hasSuffix(".\(lowercasedExtension)") {
                return stem
            }
            let filename = "\(stem).\(fileExtension)"
            return filename
        }

        private func selectionFilenameSuffix(for node: ParseTreeNode) -> String {
            let rawType = node.header.type.rawValue
            let sanitizedType =
                rawType
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
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
            let sanitized =
                stem
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "\u{0000}", with: "")
                .replacingOccurrences(of: " ", with: "-")
            return sanitized.isEmpty ? "parse-tree" : sanitized
        }

        private func collectIssues(from node: ParseTreeNode) -> [ValidationIssue] {
            var issues = node.validationIssues
            for child in node.children {
                issues.append(contentsOf: collectIssues(from: child))
            }
            return issues
        }

        private func makeIssueSummaryInputs(
            for scope: ExportScope,
            tree: ParseTree
        ) -> (ParseIssueStore.IssueSummary, [ParseIssue]) {
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

        private func makeIssueSummary(
            for issues: [ParseIssue],
            in tree: ParseTree
        ) -> ParseIssueStore.IssueSummary {
            var counts: [ParseIssue.Severity: Int] = [:]
            for severity in ParseIssue.Severity.allCases {
                counts[severity] = 0
            }
            var deepestDepth = 0
            let depthIndex = makeDepthIndex(from: tree.nodes)
            for issue in issues {
                counts[issue.severity, default: 0] += 1
                for nodeID in issue.affectedNodeIDs {
                    if let depth = depthIndex[nodeID] {
                        deepestDepth = max(deepestDepth, depth)
                    }
                }
            }
            let metrics = ParseIssueStore.IssueMetrics(
                countsBySeverity: counts,
                deepestAffectedDepth: deepestDepth
            )
            return ParseIssueStore.IssueSummary(
                metrics: metrics,
                totalCount: issues.count
            )
        }

        private func makeDepthIndex(from nodes: [ParseTreeNode]) -> [Int64: Int] {
            var index: [Int64: Int] = [:]
            func traverse(nodes: [ParseTreeNode], depth: Int) {
                for node in nodes {
                    index[node.id] = depth
                    if !node.children.isEmpty {
                        traverse(nodes: node.children, depth: depth + 1)
                    }
                }
            }
            traverse(nodes: nodes, depth: 0)
            return index
        }

        private func findNode(with id: ParseTreeNode.ID, in nodes: [ParseTreeNode])
            -> ParseTreeNode? {
            for node in nodes {
                if node.id == id { return node }
                if let match = findNode(with: id, in: node.children) {
                    return match
                }
            }
            return nil
        }

        private func handleExportError(
            _ error: ExportError,
            operation: ExportOperation
        ) {
            exportLogger.error(
                "\(operation.failureLogEvent): error=\(error.logDescription, privacy: .public)"
            )
            diagnostics.error("\(operation.diagnosticsContext) failed: \(error.logDescription)")
            exportStatus = ExportStatus(
                title: "Export Failed",
                message: error.errorDescription ?? "\(operation.diagnosticsContext) failed.",
                destinationURL: nil,
                isSuccess: false
            )
        }

        private struct PreparedExport {
            let tree: ParseTree
            let baseFilename: String
            let suffix: String?
        }

        private func openDocument(
            recent: DocumentRecent,
            restoredSelection: Int64? = nil,
            preResolvedScope: SecurityScopedURL? = nil,
            failureRecent: DocumentRecent? = nil
        ) {
            workQueue.execute { [weak self] in
                guard let self else { return }

                var accessContext: AccessContext?

                do {
                    accessContext = try self.prepareAccess(
                        for: recent,
                        preResolvedScope: preResolvedScope
                    )
                    let reader = try self.readerFactory(accessContext!.scopedURL.url)
                    let pipeline = self.pipelineFactory()
                    let launchSession = {
                        self.startSession(
                            scopedURL: accessContext!.scopedURL,
                            bookmark: accessContext!.bookmarkData,
                            bookmarkRecord: accessContext!.bookmarkRecord,
                            reader: reader,
                            pipeline: pipeline,
                            recent: accessContext!.recent,
                            restoredSelection: restoredSelection
                        )
                    }
                    if Thread.isMainThread {
                        launchSession()
                    } else {
                        Task { @MainActor in
                            launchSession()
                        }
                    }
                } catch let accessError as DocumentAccessError {
                    preResolvedScope?.revoke()
                    accessContext?.scopedURL.revoke()
                    let targetRecent = failureRecent ?? recent
                    Task { @MainActor in
                        guard failureRecent != nil else {
                            self.emitLoadFailure(for: targetRecent, error: accessError)
                            return
                        }
                        self.handleRecentAccessFailure(targetRecent, error: accessError)
                    }
                } catch {
                    preResolvedScope?.revoke()
                    accessContext?.scopedURL.revoke()
                    let targetRecent = failureRecent ?? recent
                    Task { @MainActor in
                        self.emitLoadFailure(for: targetRecent, error: error)
                    }
                }
            }
        }

        private struct AccessContext {
            let scopedURL: SecurityScopedURL
            var recent: DocumentRecent
            var bookmarkRecord: BookmarkPersistenceStore.Record?
            var bookmarkData: Data?
        }

        private func prepareAccess(
            for recent: DocumentRecent,
            preResolvedScope: SecurityScopedURL?
        ) throws -> AccessContext {
            if let scope = preResolvedScope {
                return prepareAccessUsingPreResolvedScope(scope, for: recent)
            }
            return try prepareAccessResolvingBookmark(for: recent)
        }

        private func prepareAccessUsingPreResolvedScope(
            _ scope: SecurityScopedURL,
            for recent: DocumentRecent
        ) -> AccessContext {
            var preparedRecent = recent
            preparedRecent.url = scope.url
            preparedRecent.displayName =
                preparedRecent.displayName.isEmpty
                ? scope.url.lastPathComponent : preparedRecent.displayName

            var record: BookmarkPersistenceStore.Record?
            var bookmarkData: Data?

            if let bookmarkStore {
                if let identifier = preparedRecent.bookmarkIdentifier,
                    let existing = try? bookmarkStore.record(withID: identifier) {
                    record = existing
                } else if let existing = try? bookmarkStore.record(for: scope.url) {
                    record = existing
                } else if let data = makeBookmarkData(for: scope) {
                    record = try? bookmarkStore.upsertBookmark(for: scope.url, bookmarkData: data)
                }

                if let record {
                    preparedRecent = applyBookmarkRecord(record, to: preparedRecent)
                }
            } else {
                bookmarkData = preparedRecent.bookmarkData ?? makeBookmarkData(for: scope)
                preparedRecent.bookmarkData = bookmarkData
            }

            return AccessContext(
                scopedURL: scope,
                recent: preparedRecent,
                bookmarkRecord: record,
                bookmarkData: bookmarkData
            )
        }

        private func prepareAccessResolvingBookmark(
            for recent: DocumentRecent
        ) throws -> AccessContext {
            var preparedRecent = recent
            let standardized = recent.url.standardizedFileURL

            var candidateRecord: BookmarkPersistenceStore.Record?
            if let bookmarkStore {
                if let identifier = preparedRecent.bookmarkIdentifier,
                    let existing = try? bookmarkStore.record(withID: identifier) {
                    candidateRecord = existing
                } else if let existing = try? bookmarkStore.record(for: standardized) {
                    candidateRecord = existing
                }
            }

            var bookmarkBlob: Data?
            if let candidateRecord {
                bookmarkBlob = candidateRecord.bookmarkData
            } else if let existingData = preparedRecent.bookmarkData {
                bookmarkBlob = existingData
            }

            var resolvedScope: SecurityScopedURL
            var record: BookmarkPersistenceStore.Record? = candidateRecord
            var bookmarkData: Data?

            if let blob = bookmarkBlob {
                do {
                    let resolution = try filesystemAccess.resolveBookmarkData(
                        blob,
                        bookmarkIdentifier: candidateRecord?.id
                            ?? preparedRecent.bookmarkIdentifier
                    )
                    resolvedScope = resolution.url
                    preparedRecent.url = resolution.url.url
                    preparedRecent.displayName =
                        preparedRecent.displayName.isEmpty
                        ? resolution.url.url.lastPathComponent : preparedRecent.displayName

                    if let bookmarkStore {
                        if resolution.isStale,
                            let refreshed = makeBookmarkData(for: resolution.url),
                            let updated = try? bookmarkStore.upsertBookmark(
                                for: resolution.url.url,
                                bookmarkData: refreshed
                            ) {
                            record = updated
                        }
                        let state: BookmarkResolutionState =
                            resolution.isStale ? .stale : .succeeded
                        if let updated = try? bookmarkStore.markResolution(
                            for: resolution.url.url,
                            state: state
                        ) {
                            record = updated
                        }
                        if record == nil, !resolution.isStale,
                            let refreshed = makeBookmarkData(for: resolution.url) {
                            record = try? bookmarkStore.upsertBookmark(
                                for: resolution.url.url,
                                bookmarkData: refreshed
                            )
                        }
                    } else {
                        if resolution.isStale {
                            bookmarkData = makeBookmarkData(for: resolution.url) ?? blob
                        } else {
                            bookmarkData = blob
                        }
                    }
                } catch {
                    if let bookmarkStore {
                        _ = try? bookmarkStore.markResolution(
                            for: standardized,
                            state: .failed
                        )
                        try? bookmarkStore.removeBookmark(for: standardized)
                    }
                    throw DocumentAccessError.unresolvedBookmark
                }
            } else {
                resolvedScope = try filesystemAccess.adoptSecurityScope(for: standardized)
                preparedRecent.url = resolvedScope.url
                preparedRecent.displayName =
                    preparedRecent.displayName.isEmpty
                    ? resolvedScope.url.lastPathComponent : preparedRecent.displayName

                if let bookmarkStore,
                    let data = makeBookmarkData(for: resolvedScope) {
                    record = try? bookmarkStore.upsertBookmark(
                        for: resolvedScope.url,
                        bookmarkData: data
                    )
                } else {
                    bookmarkData = makeBookmarkData(for: resolvedScope)
                }
            }

            if let record {
                preparedRecent = applyBookmarkRecord(record, to: preparedRecent)
            } else {
                preparedRecent.bookmarkData = bookmarkData
            }

            return AccessContext(
                scopedURL: resolvedScope,
                recent: preparedRecent,
                bookmarkRecord: record,
                bookmarkData: bookmarkData
            )
        }

        // swiftlint:disable:next function_parameter_count
        private func startSession(
            scopedURL: SecurityScopedURL,
            bookmark: Data?,
            bookmarkRecord: BookmarkPersistenceStore.Record?,
            reader: RandomAccessReader,
            pipeline: ParsePipeline,
            recent: DocumentRecent,
            restoredSelection: Int64?
        ) {
            // Release previous security-scoped resource if any
            activeSecurityScopedURL?.revoke()

            // Store the new security-scoped URL to keep access alive
            activeSecurityScopedURL = scopedURL
            let standardizedURL = scopedURL.url
            updateActiveValidationConfiguration(for: recent)
            parseTreeStore.start(
                pipeline: pipeline,
                reader: reader,
                context: .init(source: standardizedURL)
            )
            annotations.setFileURL(standardizedURL)
            latestSelectionNodeID = restoredSelection
            if let restoredSelection {
                annotations.setSelectedNode(restoredSelection)
            } else {
                annotations.setSelectedNode(nil)
            }
            var updatedRecent = recent
            if let bookmarkRecord {
                updatedRecent = applyBookmarkRecord(bookmarkRecord, to: updatedRecent)
            } else {
                updatedRecent.bookmarkData = bookmark ?? recent.bookmarkData
            }
            updatedRecent.lastOpened = Date()
            updatedRecent.displayName =
                updatedRecent.displayName.isEmpty
                ? standardizedURL.lastPathComponent : updatedRecent.displayName
            loadFailure = nil
            lastFailedRecent = nil
            currentDocument = updatedRecent
            insertRecent(updatedRecent)
            isRestoringSession = false
        }

        private func insertRecent(_ recent: DocumentRecent) {
            recents.removeAll { $0.url.standardizedFileURL == recent.url.standardizedFileURL }
            recents.insert(recent, at: 0)
            if recents.count > recentLimit {
                recents = Array(recents.prefix(recentLimit))
            }
            persistRecents()
            persistSession()
        }
        private func removeRecent(with url: URL) {
            recents.removeAll { $0.url.standardizedFileURL == url.standardizedFileURL }
            persistRecents()
            persistSession()
        }

        private func persistRecents() {
            do {
                let payload = sanitizeRecentsForPersistence(recents)
                try recentsStore.save(payload)
            } catch {
                let errorDescription = (error as NSError).localizedDescription
                let focusedPath = currentDocument?.url.standardizedFileURL.path ?? "none"
                let allRecents =
                    recents
                    .map { $0.url.standardizedFileURL.path }
                    .joined(separator: ", ")
                diagnostics.error(
                    "Failed to persist recents: error=\(errorDescription); recentsCount=\(recents.count); "
                        + "focusedPath=\(focusedPath); recentsPaths=[\(allRecents)]"
                )
            }
        }

        private func makeBookmarkData(for scopedURL: SecurityScopedURL) -> Data? {
            bookmarkDataProvider(scopedURL)
        }

        private func applySessionSnapshot(_ snapshot: WorkspaceSessionSnapshot) {
            let sortedFiles = snapshot.files.sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.orderIndex < rhs.orderIndex
            }
            if !sortedFiles.isEmpty {
                let loadedRecents = sortedFiles.map(\.recent)
                let migratedRecents =
                    bookmarkStore != nil ? loadedRecents.map(migrateRecentBookmark) : loadedRecents
                recents = migratedRecents
                let focusURL = snapshot.focusedFileURL?.standardizedFileURL
                if let focusURL,
                    let focusedIndex = migratedRecents.firstIndex(where: {
                        $0.url.standardizedFileURL == focusURL
                    }) {
                    currentDocument = migratedRecents[focusedIndex]
                } else {
                    currentDocument = migratedRecents.first
                }
            }
            sessionFileIDs = Dictionary(
                uniqueKeysWithValues: sortedFiles.map { file in
                    (canonicalIdentifier(for: file.recent.url), file.id)
                })
            sessionBookmarkDiffs = Dictionary(
                uniqueKeysWithValues: sortedFiles.map { file in
                    (canonicalIdentifier(for: file.recent.url), file.bookmarkDiffs)
                })
            sessionValidationConfigurations = Dictionary(
                uniqueKeysWithValues: sortedFiles.compactMap { file in
                    guard let configuration = file.validationConfiguration else { return nil }
                    let key = canonicalIdentifier(for: file.recent.url)
                    return (key, normalizedConfiguration(configuration))
                })
        }

        private func restoreSessionIfNeeded() {
            guard let snapshot = pendingSessionSnapshot else { return }
            pendingSessionSnapshot = nil
            let sortedFiles = snapshot.files.sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.orderIndex < rhs.orderIndex
            }
            guard !sortedFiles.isEmpty else { return }
            let focusURL =
                snapshot.focusedFileURL?.standardizedFileURL
                ?? sortedFiles.first?.recent.url.standardizedFileURL
            guard let focusURL,
                let focused = sortedFiles.first(where: {
                    $0.recent.url.standardizedFileURL == focusURL
                })
            else {
                return
            }
            isRestoringSession = true
            openDocument(
                recent: focused.recent,
                restoredSelection: focused.lastSelectionNodeID,
                preResolvedScope: nil,
                failureRecent: focused.recent
            )
        }

        private func persistSession() {
            guard let sessionStore else { return }
            if recents.isEmpty {
                do {
                    try sessionStore.clearCurrentSession()
                    currentSessionID = nil
                    currentSessionCreatedAt = nil
                    sessionFileIDs.removeAll()
                    sessionBookmarkDiffs.removeAll()
                    sessionValidationConfigurations.removeAll()
                    latestSelectionNodeID = nil
                } catch {
                    let errorDescription = (error as NSError).localizedDescription
                    diagnostics.error(
                        "Failed to clear persisted session: error=\(errorDescription); "
                            + "sessionID=\(currentSessionID?.uuidString ?? "none")"
                    )
                }
                return
            }

            let now = Date()
            if currentSessionCreatedAt == nil {
                currentSessionCreatedAt = now
            }
            let sessionID = currentSessionID ?? UUID()
            currentSessionID = sessionID

            var snapshots: [WorkspaceSessionFileSnapshot] = []
            snapshots.reserveCapacity(recents.count)
            var nextDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]
            var nextValidationConfigurations: [String: ValidationConfiguration] = [:]

            for (index, recent) in recents.enumerated() {
                let canonical = canonicalIdentifier(for: recent.url)
                let fileID = sessionFileIDs[canonical] ?? UUID()
                sessionFileIDs[canonical] = fileID
                let selection: Int64?
                if let currentURL = annotations.currentFileURL,
                    currentURL.standardizedFileURL == recent.url.standardizedFileURL {
                    selection = latestSelectionNodeID
                } else {
                    selection = nil
                }
                let persistedRecent = sanitizeRecentsForPersistence([recent]).first ?? recent
                let diffs = sessionBookmarkDiffs[canonical] ?? []
                nextDiffs[canonical] = diffs
                let overrideConfiguration = sessionValidationConfigurations[canonical]
                if let overrideConfiguration {
                    nextValidationConfigurations[canonical] = overrideConfiguration
                }
                snapshots.append(
                    WorkspaceSessionFileSnapshot(
                        id: fileID,
                        recent: persistedRecent,
                        orderIndex: index,
                        lastSelectionNodeID: selection,
                        isPinned: false,
                        scrollOffset: nil,
                        bookmarkIdentifier: recent.bookmarkIdentifier,
                        bookmarkDiffs: diffs,
                        validationConfiguration: overrideConfiguration
                    )
                )
            }

            sessionBookmarkDiffs = nextDiffs
            sessionValidationConfigurations = nextValidationConfigurations

            let snapshot = WorkspaceSessionSnapshot(
                id: sessionID,
                createdAt: currentSessionCreatedAt ?? now,
                updatedAt: now,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                files: snapshots,
                focusedFileURL: currentDocument?.url,
                lastSceneIdentifier: nil,
                windowLayouts: []
            )

            do {
                try sessionStore.saveCurrentSession(snapshot)
            } catch {
                let errorDescription = (error as NSError).localizedDescription
                diagnostics.error(
                    "Failed to persist session snapshot: error=\(errorDescription); "
                        + "sessionID=\(snapshot.id.uuidString); focusedPath=\(snapshot.focusedFileURL?.standardizedFileURL.path ?? "none")"
                )
            }
        }

        private func canonicalIdentifier(for url: URL) -> String {
            url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        }

        private func updateActiveValidationConfiguration(for recent: DocumentRecent) {
            let key = canonicalIdentifier(for: recent.url)
            currentConfigurationKey = key
            if let override = sessionValidationConfigurations[key] {
                validationConfiguration = normalizedConfiguration(override)
                isUsingWorkspaceValidationOverride = true
            } else {
                validationConfiguration = globalValidationConfiguration
                isUsingWorkspaceValidationOverride = false
            }
            applyValidationConfigurationFilter()
        }

        private func updateGlobalConfiguration(_ configuration: ValidationConfiguration) {
            let normalized = normalizedConfiguration(configuration)
            guard normalized != globalValidationConfiguration else { return }
            globalValidationConfiguration = normalized
            persistGlobalConfiguration()
            if !isUsingWorkspaceValidationOverride {
                validationConfiguration = normalized
                applyValidationConfigurationFilter()
            }
        }

        private func updateWorkspaceConfiguration(_ configuration: ValidationConfiguration) {
            guard let key = currentConfigurationKey else { return }
            let normalized = normalizedConfiguration(configuration)
            if normalized == globalValidationConfiguration {
                let removed = sessionValidationConfigurations.removeValue(forKey: key) != nil
                validationConfiguration = globalValidationConfiguration
                isUsingWorkspaceValidationOverride = false
                applyValidationConfigurationFilter()
                if removed {
                    persistSession()
                }
            } else {
                sessionValidationConfigurations[key] = normalized
                validationConfiguration = normalized
                isUsingWorkspaceValidationOverride = true
                applyValidationConfigurationFilter()
                persistSession()
            }
        }

        private func applyOverride(
            on configuration: inout ValidationConfiguration,
            rule: ValidationRuleIdentifier,
            isEnabled: Bool
        ) {
            let preset = presetByID[configuration.activePresetID]
            let presetValue = preset?.isRuleEnabled(rule) ?? true
            if isEnabled == presetValue {
                configuration.ruleOverrides.removeValue(forKey: rule)
            } else {
                configuration.ruleOverrides[rule] = isEnabled
            }
        }

        private func applyValidationConfigurationFilter() {
            let configuration = validationConfiguration
            let presets = validationPresets
            parseTreeStore.setValidationIssueFilter { issue in
                guard let identifier = ValidationRuleIdentifier(rawValue: issue.ruleID) else {
                    return true
                }
                return configuration.isRuleEnabled(identifier, presets: presets)
            }
        }

        private func normalizedConfiguration(
            _ configuration: ValidationConfiguration
        ) -> ValidationConfiguration {
            Self.normalizedConfiguration(
                configuration,
                presetByID: presetByID,
                defaultPresetID: defaultValidationPresetID
            )
        }

        private static func normalizedConfiguration(
            _ configuration: ValidationConfiguration,
            presetByID: [String: ValidationPreset],
            defaultPresetID: String
        ) -> ValidationConfiguration {
            var normalized = configuration
            if presetByID[normalized.activePresetID] == nil {
                normalized.activePresetID = defaultPresetID
                normalized.ruleOverrides.removeAll()
            }
            return normalized
        }

        private func persistGlobalConfiguration() {
            guard let validationConfigurationStore else { return }
            do {
                try validationConfigurationStore.saveConfiguration(globalValidationConfiguration)
            } catch {
                diagnostics.error("Failed to persist validation configuration: \(error)")
            }
        }

        private func makeValidationMetadata() -> ValidationMetadata {
            ValidationMetadata(
                activePresetID: validationConfiguration.activePresetID,
                disabledRuleIDs: disabledRuleIDs(for: validationConfiguration)
            )
        }

        private func disabledRuleIDs(for configuration: ValidationConfiguration) -> [String] {
            ValidationRuleIdentifier.allCases
                .filter { !configuration.isRuleEnabled($0, presets: validationPresets) }
                .map(\.rawValue)
                .sorted()
        }

        private static func defaultPresetID(from presets: [ValidationPreset]) -> String {
            if presets.contains(where: { $0.id == "all-rules" }) {
                return "all-rules"
            }
            return presets.first?.id ?? "all-rules"
        }

        private func migrateRecentsForBookmarkStore() {
            guard bookmarkStore != nil, !recents.isEmpty else { return }
            let migrated = recents.map(migrateRecentBookmark)
            if migrated != recents {
                recents = migrated
                persistRecents()
            }
        }

        private func migrateRecentBookmark(_ recent: DocumentRecent) -> DocumentRecent {
            guard let bookmarkStore else { return recent }
            let standardized = recent.url.standardizedFileURL
            if let identifier = recent.bookmarkIdentifier,
                let record = try? bookmarkStore.record(withID: identifier) {
                return applyBookmarkRecord(record, to: recent)
            }
            if let record = try? bookmarkStore.record(for: standardized) {
                return applyBookmarkRecord(record, to: recent)
            }
            if let data = recent.bookmarkData,
                let record = try? bookmarkStore.upsertBookmark(
                    for: standardized, bookmarkData: data) {
                return applyBookmarkRecord(record, to: recent)
            }
            return recent
        }

        private func sanitizeRecentsForPersistence(_ recents: [DocumentRecent]) -> [DocumentRecent] {
            guard bookmarkStore != nil else { return recents }
            return recents.map { recent in
                var sanitized = recent
                if sanitized.bookmarkIdentifier != nil {
                    sanitized.bookmarkData = nil
                }
                return sanitized
            }
        }

        private func applyBookmarkRecord(
            _ record: BookmarkPersistenceStore.Record, to recent: DocumentRecent
        ) -> DocumentRecent {
            var updated = recent
            updated.bookmarkIdentifier = record.id
            updated.bookmarkData = nil
            return updated
        }

        private func updateRecent(with record: BookmarkPersistenceStore.Record, for url: URL) {
            let standardized = url.standardizedFileURL
            // Must update @Published properties on main thread to avoid SwiftUI/menu crashes
            if Thread.isMainThread {
                if let index = recents.firstIndex(where: {
                    $0.url.standardizedFileURL == standardized
                }) {
                    recents[index] = applyBookmarkRecord(record, to: recents[index])
                }
                if let current = currentDocument, current.url.standardizedFileURL == standardized {
                    currentDocument = applyBookmarkRecord(record, to: current)
                }
            } else {
                Task { @MainActor in
                    if let index = self.recents.firstIndex(where: {
                        $0.url.standardizedFileURL == standardized
                    }) {
                        self.recents[index] = self.applyBookmarkRecord(
                            record, to: self.recents[index])
                    }
                    if let current = self.currentDocument,
                        current.url.standardizedFileURL == standardized {
                        self.currentDocument = self.applyBookmarkRecord(record, to: current)
                    }
                }
            }
        }

        private func handleRecentAccessFailure(_ recent: DocumentRecent, error: DocumentAccessError) {
            removeRecent(with: recent.url)
            emitLoadFailure(for: recent, error: error)
        }

        private func emitLoadFailure(for recent: DocumentRecent, error: Error?) {
            var standardizedRecent = recent
            standardizedRecent.url = recent.url.standardizedFileURL
            let displayName = failureDisplayName(for: standardizedRecent)
            let defaultSuggestion =
                "Verify that the file exists and you have permission to read it, then try again."

            var message = "ISO Inspector couldn't open “\(displayName)”."
            var suggestion = defaultSuggestion
            var details: String?

            if let localizedError = error as? LocalizedError {
                if let description = localizedError.errorDescription?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !description.isEmpty {
                    message = description
                }
                if let recovery = localizedError.recoverySuggestion?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !recovery.isEmpty {
                    suggestion = recovery
                }
                if let reason = localizedError.failureReason?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !reason.isEmpty {
                    details = reason
                }
            } else if let error {
                let localized = error.localizedDescription.trimmingCharacters(
                    in: .whitespacesAndNewlines)
                if !localized.isEmpty {
                    message = localized
                }
            }

            if let error {
                logger.error(
                    "Document open failed for \(standardizedRecent.url.path, privacy: .public): \(String(describing: error), privacy: .public)"
                )
            } else {
                logger.error(
                    "Document open failed for \(standardizedRecent.url.path, privacy: .public): no additional error details available"
                )
            }

            loadFailure = DocumentLoadFailure(
                fileURL: standardizedRecent.url,
                fileDisplayName: displayName,
                message: message,
                recoverySuggestion: suggestion,
                details: details
            )
            lastFailedRecent = standardizedRecent
        }

        private func failureDisplayName(for recent: DocumentRecent) -> String {
            let trimmed = recent.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
            let lastComponent = recent.url.lastPathComponent
            return lastComponent.isEmpty ? recent.url.absoluteString : lastComponent
        }

    }

    extension DocumentSessionController {
        enum ExportScope: Equatable, Sendable {
            case document
            case selection(ParseTreeNode.ID)

            var logDescription: String {
                switch self {
                case .document:
                    return "document"
                case .selection(let identifier):
                    return "selection-\(identifier)"
                }
            }
        }

        private enum ExportOperation {
            case json
            case issueSummary

            var logIdentifier: String {
                switch self {
                case .json:
                    return "json"
                case .issueSummary:
                    return "issue-summary"
                }
            }

            var successMessagePrefix: String {
                switch self {
                case .json:
                    return "Saved JSON to “"
                case .issueSummary:
                    return "Saved issue summary to “"
                }
            }

            var diagnosticsContext: String {
                switch self {
                case .json:
                    return "JSON export"
                case .issueSummary:
                    return "Issue summary export"
                }
            }

            var successLogEvent: String {
                switch self {
                case .json:
                    return "JSON export succeeded"
                case .issueSummary:
                    return "Issue summary export succeeded"
                }
            }

            var failureLogEvent: String {
                switch self {
                case .json:
                    return "JSON export failed"
                case .issueSummary:
                    return "Issue summary export failed"
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
                id: UUID = UUID(),
                title: String,
                message: String,
                destinationURL: URL?,
                isSuccess: Bool
            ) {
                self.id = id
                self.title = title
                self.message = message
                self.destinationURL = destinationURL
                self.isSuccess = isSuccess
            }
        }

        enum ExportError: LocalizedError {
            case emptyTree
            case nodeNotFound
            case destinationUnavailable(underlying: Error)
            case writeFailed(url: URL, underlying: Error)

            var errorDescription: String? {
                switch self {
                case .emptyTree:
                    return "Run a parse before exporting."
                case .nodeNotFound:
                    return
                        "The selected box is no longer available. Refresh the selection and try again."
                case .destinationUnavailable(let underlying):
                    return
                        "ISO Inspector couldn't access the chosen destination. \(underlying.localizedDescription)"
                case .writeFailed(let url, let underlying):
                    return
                        "ISO Inspector couldn't write to “\(url.lastPathComponent)”. \(underlying.localizedDescription)"
                }
            }

            var logDescription: String {
                switch self {
                case .emptyTree:
                    return "empty-parse-tree"
                case .nodeNotFound:
                    return "selection-missing"
                case .destinationUnavailable(let underlying):
                    return "destination-unavailable: \(String(describing: underlying))"
                case .writeFailed(let url, let underlying):
                    return
                        "write-failed: url=\(url.path) underlying=\(String(describing: underlying))"
                }
            }
        }

        struct DocumentLoadFailure: Identifiable, Equatable {
            let id: UUID
            let fileURL: URL
            let fileDisplayName: String
            let message: String
            let recoverySuggestion: String
            let details: String?

            init(
                id: UUID = UUID(),
                fileURL: URL,
                fileDisplayName: String,
                message: String,
                recoverySuggestion: String,
                details: String?
            ) {
                self.id = id
                self.fileURL = fileURL
                self.fileDisplayName = fileDisplayName
                self.message = message
                self.recoverySuggestion = recoverySuggestion
                self.details = details
            }

            var title: String {
                "Unable to open “\(fileDisplayName)”"
            }
        }
    }

    private enum DocumentAccessError: LocalizedError {
        case unreadable(URL)
        case unresolvedBookmark

        var errorDescription: String? {
            switch self {
            case .unreadable(let url):
                return "ISO Inspector couldn't access the file at \(url.path)."
            case .unresolvedBookmark:
                return "ISO Inspector couldn't resolve the saved bookmark for this file."
            }
        }

        var failureReason: String? {
            switch self {
            case .unreadable(let url):
                return
                    "The file may have been moved, deleted, or you may not have permission to read it. (\(url.path))"
            case .unresolvedBookmark:
                return "The security-scoped bookmark is no longer valid."
            }
        }

        var recoverySuggestion: String? {
            "Verify that the file exists and you have permission to read it, then try opening it again."
        }
    }

    protocol DocumentSessionWorkQueue {
        func execute(_ work: @escaping () -> Void)
    }

    struct DocumentSessionBackgroundQueue: DocumentSessionWorkQueue {
        private let queue: DispatchQueue

        init(
            queue: DispatchQueue = DispatchQueue(
                label: "isoinspector.document-session", qos: .userInitiated)
        ) {
            self.queue = queue
        }

        func execute(_ work: @escaping () -> Void) {
            queue.async(execute: work)
        }
    }
#endif
