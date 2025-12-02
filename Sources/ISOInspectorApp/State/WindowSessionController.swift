#if canImport(SwiftUI) && canImport(Combine)
    import Combine
    import Foundation
    import ISOInspectorKit
    import OSLog

    /// Per-window session state controller
    ///
    /// Manages document-specific and view-specific state that should be isolated per window.
    /// Each window instance gets its own `WindowSessionController` to prevent state sharing
    /// across multiple windows in macOS/iPadOS multi-window mode.
    ///
    /// Architecture:
    /// - `DocumentSessionController`: Shared app-level state (recents, preferences, validation configs)
    /// - `WindowSessionController`: Per-window state (current document, tree selection, view state)
    /// - `DocumentViewModel`: Per-window document view hierarchy state
    /// - `ParseTreeStore`: Per-window parse tree cache and issue metrics
    ///
    /// This separation ensures that:
    /// 1. Opening a different file in Window B doesn't change Window A's document
    /// 2. Selecting a different tree item in Window B doesn't change Window A's selection
    /// 3. View state (scroll positions, panel visibility) is independent per window
    /// 4. Each window can maintain independent undo/redo stacks (future enhancement)
    @MainActor final class WindowSessionController: ObservableObject {
        // MARK: - Published Properties (Window-Specific State)

        /// The current document open in this window
        /// Internal setter to allow testing while preventing external mutation.
        @Published var currentDocument: DocumentRecent?

        /// Document load failure state for this window
        /// Internal setter to allow testing while preventing external mutation.
        @Published var loadFailure: DocumentSessionController.DocumentLoadFailure?

        /// Export status for operations in this window
        /// Internal setter to allow testing while preventing external mutation.
        @Published var exportStatus: DocumentSessionController.ExportStatus?

        /// Issue metrics for the current document in this window
        /// Internal setter to allow testing while preventing external mutation.
        @Published var issueMetrics: ParseIssueStore.IssueMetrics

        /// The document view model for this window
        let documentViewModel: DocumentViewModel

        /// Parse tree store for this window's document
        let parseTreeStore: ParseTreeStore

        /// Annotation session for this window
        let annotations: AnnotationBookmarkSession

        // MARK: - Private Properties

        private let appSessionController: DocumentSessionController
        private let readerFactory: @Sendable (URL) throws -> RandomAccessReader
        private let pipelineFactory: @Sendable () -> ParsePipeline
        private let workQueue: DocumentSessionWorkQueue
        private let diagnostics: any DiagnosticsLogging
        private let filesystemAccess: FilesystemAccess
        private let bookmarkDataProvider: @Sendable (SecurityScopedURL) -> Data?
        private let logger = Logger(subsystem: "ISOInspectorApp", category: "WindowSession")
        private let exportLogger = Logger(subsystem: "ISOInspectorApp", category: "WindowExport")

        private var cancellables: Set<AnyCancellable> = []
        private var activeSecurityScopedURL: SecurityScopedURL?
        private var currentSessionID: UUID?
        private var lastFailedRecent: DocumentRecent?

        // MARK: - Initialization

        init(
            appSessionController: DocumentSessionController, parseTreeStore: ParseTreeStore? = nil,
            annotations: AnnotationBookmarkSession? = nil,
            readerFactory: @escaping @Sendable (URL) throws -> RandomAccessReader = {
                try ChunkedFileReader(fileURL: $0)
            },
            pipelineFactory: @escaping @Sendable () -> ParsePipeline = {
                .live(options: .tolerant)
            }, workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
            diagnostics: (any DiagnosticsLogging)? = nil,
            filesystemAccess: FilesystemAccess = .live(),
            bookmarkDataProvider: (@Sendable (SecurityScopedURL) -> Data?)? = nil
        ) {
            let resolvedParseTreeStore = parseTreeStore ?? ParseTreeStore()
            let resolvedAnnotations = annotations ?? AnnotationBookmarkSession(store: nil)

            self.appSessionController = appSessionController
            self.parseTreeStore = resolvedParseTreeStore
            self.annotations = resolvedAnnotations
            self.documentViewModel = DocumentViewModel(
                store: resolvedParseTreeStore, annotations: resolvedAnnotations)
            self.issueMetrics = resolvedParseTreeStore.issueMetrics
            self.readerFactory = readerFactory
            self.pipelineFactory = pipelineFactory
            self.workQueue = workQueue
            self.diagnostics =
                diagnostics
                ?? DiagnosticsLogger(
                    subsystem: "ISOInspectorApp", category: "WindowSessionPersistence")
            self.filesystemAccess = filesystemAccess
            if let bookmarkDataProvider {
                self.bookmarkDataProvider = bookmarkDataProvider
            } else {
                self.bookmarkDataProvider = { scopedURL in
                    try? filesystemAccess.createBookmark(for: scopedURL)
                }
            }

            setupBindings()
        }

        // MARK: - Setup

        private func setupBindings() {
            parseTreeStore.$issueMetrics.sink { [weak self] metrics in self?.issueMetrics = metrics
            }.store(in: &cancellables)

            // Forward export status from app controller to this window
            appSessionController.$exportStatus.sink { [weak self] status in
                self?.exportStatus = status
            }.store(in: &cancellables)
        }

        // MARK: - Document Management

        /// Open a document in this window
        func openDocument(at url: URL) { Task { await handleOpenDocument(at: url) } }

        /// Open a recent document in this window
        /// Routes through the standard document loading path to ensure the parseTreeStore
        /// and DocumentViewModel are properly populated for this window.
        func openRecent(_ recent: DocumentRecent) { openDocument(at: recent.url) }

        // MARK: - Export Operations

        /// Export document as JSON
        /// Delegates to the app controller, which handles the actual export.
        /// The window's exportStatus is automatically synchronized via bindings.
        func exportJSON(scope: DocumentSessionController.ExportScope) async {
            await appSessionController.exportJSON(scope: scope)
        }

        /// Export issue summary
        /// Delegates to the app controller, which handles the actual export.
        /// The window's exportStatus is automatically synchronized via bindings.
        func exportIssueSummary(scope: DocumentSessionController.ExportScope) async {
            await appSessionController.exportIssueSummary(scope: scope)
        }

        /// Retry last failed document load in this window
        func retryLastFailure() {
            if let failed = lastFailedRecent { openDocument(at: failed.url) }
        }

        /// Dismiss load failure state for this window
        func dismissLoadFailure() { loadFailure = nil }

        /// Dismiss export status
        /// Clears both the window's and the app controller's export status.
        func dismissExportStatus() {
            exportStatus = nil
            appSessionController.dismissExportStatus()
        }

        // MARK: - Focus Management (delegated to app controller)

        /// Focus integrity diagnostics in this window
        func focusIntegrityDiagnostics() { appSessionController.focusIntegrityDiagnostics() }

        // MARK: - Private Helpers

        /// Encapsulates the resources needed to start parsing a document.
        /// Avoids SwiftLint large_tuple violation.
        private struct DocumentLoadingResources: @unchecked Sendable {
            let reader: RandomAccessReader
            let pipeline: ParsePipeline
            let context: ParsePipeline.Context
        }

        private func handleOpenDocument(at url: URL) async {
            logger.info("Opening document: \(url.lastPathComponent, privacy: .public)")
            loadFailure = nil
            exportStatus = nil

            do {
                // Start security-scoped access (on main thread)
                let scopedURL = try filesystemAccess.adoptSecurityScope(for: url)
                activeSecurityScopedURL = scopedURL

                // Capture dependencies on the main actor before hopping to a detached task.
                let readerFactory = self.readerFactory
                let pipelineFactory = self.pipelineFactory
                let context = ParsePipeline.Context(
                    source: url, issueStore: parseTreeStore.issueStore)

                // Offload heavy parsing work to a detached task to avoid blocking UI while keeping actor boundaries explicit.
                let resources = try await Task.detached(priority: .userInitiated) {
                    () -> DocumentLoadingResources in
                    let reader = try readerFactory(scopedURL.url)
                    let pipeline = pipelineFactory()
                    return DocumentLoadingResources(
                        reader: reader, pipeline: pipeline, context: context)
                }.value

                // Back to main thread for UI updates
                await MainActor.run {
                    parseTreeStore.start(
                        pipeline: resources.pipeline, reader: resources.reader,
                        context: resources.context)

                    let recent = DocumentRecent(
                        url: url, bookmarkIdentifier: nil, bookmarkData: nil,
                        displayName: url.lastPathComponent, lastOpened: Date())
                    currentDocument = recent

                    // Register with app controller's recent documents
                    appSessionController.openRecent(recent)
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to open document: \(error, privacy: .public)")
                    let recent = DocumentRecent(
                        url: url, bookmarkIdentifier: nil, bookmarkData: nil,
                        displayName: url.lastPathComponent, lastOpened: Date())
                    lastFailedRecent = recent
                    loadFailure = DocumentSessionController.DocumentLoadFailure(
                        id: UUID(), fileURL: url, fileDisplayName: url.lastPathComponent,
                        message: error.localizedDescription,
                        recoverySuggestion:
                            "Check that the file is a valid ISO, MP4, or QuickTime file.",
                        details: "\(error)")
                }
            }
        }
    }

#endif
