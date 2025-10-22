#if canImport(Combine) && canImport(SwiftUI)
import Combine
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit
import UniformTypeIdentifiers

@MainActor
final class DocumentSessionControllerTests: XCTestCase {
    func testInitializerLoadsRecentsFromStore() throws {
        let expected = [sampleRecent(index: 1)]
        let store = DocumentRecentsStoreStub(initialRecents: expected)
        let controller = makeController(store: store)
        XCTAssertEqual(controller.recents, expected)
    }

    func testInitializerMigratesBookmarkDataToPersistenceStore() throws {
        let bookmarkStore = BookmarkPersistenceStoreStub()
        let data = Data("bookmark".utf8)
        let recent = DocumentRecent(
            url: URL(fileURLWithPath: "/tmp/migrate.mp4"),
            bookmarkData: data,
            displayName: "Migrate",
            lastOpened: Date(timeIntervalSince1970: 1)
        )
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [recent])

        let controller = makeController(
            store: recentsStore,
            bookmarkStore: bookmarkStore
        )

        XCTAssertEqual(bookmarkStore.upsertedURLs.map { $0.standardizedFileURL }, [recent.url.standardizedFileURL])
        XCTAssertEqual(controller.recents.first?.bookmarkData, nil)
        XCTAssertNotNil(controller.recents.first?.bookmarkIdentifier)
        XCTAssertEqual(recentsStore.savedRecents?.first?.bookmarkIdentifier, controller.recents.first?.bookmarkIdentifier)
        XCTAssertNil(recentsStore.savedRecents?.first?.bookmarkData)
    }

    func testOpenDocumentUpsertsBookmarkRecord() throws {
        let bookmarkStore = BookmarkPersistenceStoreStub()
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let controller = makeController(
            store: recentsStore,
            bookmarkStore: bookmarkStore,
            bookmarkDataProvider: { _ in Data("bookmark".utf8) }
        )

        let url = URL(fileURLWithPath: "/tmp/upsert.mp4")
        controller.openDocument(at: url)

        XCTAssertEqual(bookmarkStore.upsertedURLs.map { $0.standardizedFileURL }, [url.standardizedFileURL])
        let saved = try XCTUnwrap(recentsStore.savedRecents?.first)
        XCTAssertNotNil(saved.bookmarkIdentifier)
        XCTAssertNil(saved.bookmarkData)
    }

    func testOpeningDocumentStartsParsingAndUpdatesRecents() throws {
        let store = DocumentRecentsStoreStub(initialRecents: [])
        let filesystemStub = FilesystemAccessStub()
        let controller = makeController(
            store: store,
            filesystemAccess: filesystemStub.makeAccess()
        )
        let url = URL(fileURLWithPath: "/tmp/example.mp4")
        var cancellables: Set<AnyCancellable> = []
        let finished = expectation(description: "Parsing finished")

        controller.parseTreeStore.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        controller.openDocument(at: url)
        wait(for: [finished], timeout: 1.0)

        XCTAssertEqual(controller.recents.first?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(store.savedRecents?.first?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.currentDocument?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.parseTreeStore.fileURL?.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.parseTreeStore.state, .finished)
        XCTAssertEqual(filesystemStub.manager.startedURLs, [url.standardizedFileURL])
    }

    func testOpeningSecondDocumentRevokesPreviousScope() throws {
        let store = DocumentRecentsStoreStub(initialRecents: [])
        let filesystemStub = FilesystemAccessStub()
        let controller = makeController(
            store: store,
            filesystemAccess: filesystemStub.makeAccess()
        )

        let firstURL = URL(fileURLWithPath: "/tmp/first.mp4")
        let secondURL = URL(fileURLWithPath: "/tmp/second.mp4")

        controller.openDocument(at: firstURL)
        controller.openDocument(at: secondURL)

        XCTAssertEqual(
            filesystemStub.manager.startedURLs,
            [firstURL.standardizedFileURL, secondURL.standardizedFileURL]
        )
        XCTAssertEqual(
            filesystemStub.manager.stoppedURLs,
            [firstURL.standardizedFileURL]
        )
    }

    func testInitializerRestoresSessionSnapshotAndPersistsUpdates() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let annotationStore = AnnotationBookmarkStoreStub()
        let bookmarkStore = BookmarkPersistenceStoreStub()

        let focusURL = URL(fileURLWithPath: "/tmp/focus.mp4")
        let otherURL = URL(fileURLWithPath: "/tmp/other.mp4")

        let focusBookmarkID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let focusRecent = DocumentRecent(
            url: focusURL,
            bookmarkIdentifier: focusBookmarkID,
            bookmarkData: Data([0x01]),
            displayName: "Focus",
            lastOpened: Date(timeIntervalSince1970: 10)
        )
        let otherBookmarkID = UUID(uuidString: "00000000-0000-0000-0000-000000000098")!
        let otherRecent = DocumentRecent(
            url: otherURL,
            bookmarkIdentifier: otherBookmarkID,
            bookmarkData: nil,
            displayName: "Other",
            lastOpened: Date(timeIntervalSince1970: 5)
        )

        let focusDiff = WorkspaceSessionBookmarkDiff(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
            bookmarkID: focusBookmarkID,
            isRemoved: false,
            noteDelta: "retain"
        )
        let otherDiff = WorkspaceSessionBookmarkDiff(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D2")!,
            bookmarkID: otherBookmarkID,
            isRemoved: true,
            noteDelta: ""
        )

        sessionStore.loadedSnapshot = WorkspaceSessionSnapshot(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            appVersion: "1.0",
            files: [
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                    recent: focusRecent,
                    orderIndex: 0,
                    lastSelectionNodeID: 99,
                    isPinned: false,
                    scrollOffset: nil,
                    bookmarkIdentifier: focusRecent.bookmarkIdentifier,
                    bookmarkDiffs: [focusDiff],
                    validationConfiguration: nil
                ),
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                    recent: otherRecent,
                    orderIndex: 1,
                    lastSelectionNodeID: nil,
                    isPinned: false,
                    scrollOffset: nil,
                    bookmarkIdentifier: otherRecent.bookmarkIdentifier,
                    bookmarkDiffs: [otherDiff],
                    validationConfiguration: nil
                )
            ],
            focusedFileURL: focusURL,
            lastSceneIdentifier: nil,
            windowLayouts: []
        )

        let filesystemStub = FilesystemAccessStub()
        filesystemStub.resolutions[Data([0x01])] = BookmarkResolution(url: focusURL, isStale: false)

        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            annotationsStore: annotationStore,
            bookmarkStore: bookmarkStore,
            filesystemAccess: filesystemStub.makeAccess()
        )

        XCTAssertEqual(controller.recents.count, 2)
        XCTAssertEqual(controller.recents.first?.url.standardizedFileURL, focusURL.standardizedFileURL)
        XCTAssertEqual(controller.currentDocument?.url.standardizedFileURL, focusURL.standardizedFileURL)
        XCTAssertEqual(controller.annotations.currentSelectedNodeID, 99)
        XCTAssertEqual(sessionStore.savedSnapshots.count, 1)
        let persisted = try XCTUnwrap(sessionStore.savedSnapshots.first)
        XCTAssertEqual(persisted.files.count, 2)
        XCTAssertEqual(persisted.files.first?.lastSelectionNodeID, 99)
        XCTAssertEqual(persisted.files.first?.bookmarkDiffs, [focusDiff])
    }

    func testSelectionChangePersistsUpdatedSession() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let annotationStore = AnnotationBookmarkStoreStub()
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            annotationsStore: annotationStore
        )

        let url = URL(fileURLWithPath: "/tmp/example.mp4")
        controller.openDocument(at: url)
        XCTAssertEqual(sessionStore.savedSnapshots.count, 1)

        controller.annotations.setSelectedNode(123)

        XCTAssertEqual(sessionStore.savedSnapshots.count, 2)
        XCTAssertEqual(sessionStore.savedSnapshots.last?.files.first?.lastSelectionNodeID, 123)
    }

    func testPersistSessionIncludesBookmarkIdentifiers() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let bookmarkStore = BookmarkPersistenceStoreStub()
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            bookmarkStore: bookmarkStore,
            bookmarkDataProvider: { _ in Data("bookmark".utf8) }
        )

        let url = URL(fileURLWithPath: "/tmp/session-bookmark.mp4")
        controller.openDocument(at: url)

        let snapshot = try XCTUnwrap(sessionStore.savedSnapshots.last)
        let file = try XCTUnwrap(snapshot.files.first)
        XCTAssertNotNil(file.bookmarkIdentifier)
        XCTAssertNil(file.recent.bookmarkData)
    }

    func testOpenDocumentFailurePublishesLoadFailureUntilDismissed() throws {
        let store = DocumentRecentsStoreStub(initialRecents: [])
        enum SampleError: LocalizedError {
            case failed

            var errorDescription: String? { "Simulated failure" }
        }
        var shouldFail = true
        let filesystemStub = FilesystemAccessStub()
        let controller = makeController(
            store: store,
            readerFactory: { _ in
                if shouldFail {
                    shouldFail = false
                    throw SampleError.failed
                }
                return StubRandomAccessReader()
            },
            workQueue: ImmediateWorkQueue(),
            filesystemAccess: filesystemStub.makeAccess()
        )

        let url = URL(fileURLWithPath: "/tmp/missing.mp4")
        controller.openDocument(at: url)

        let failure = try XCTUnwrap(controller.loadFailure)
        XCTAssertEqual(failure.fileDisplayName, "missing.mp4")
        XCTAssertEqual(failure.message, "Simulated failure")
        XCTAssertFalse(failure.recoverySuggestion.isEmpty)
        XCTAssertNil(controller.currentDocument)

        controller.dismissLoadFailure()
        XCTAssertNil(controller.loadFailure)
        XCTAssertEqual(filesystemStub.manager.startedURLs, [url.standardizedFileURL])
        XCTAssertEqual(filesystemStub.manager.stoppedURLs, [url.standardizedFileURL])
    }

    func testOpenRecentResolvesBookmarkAndActivatesSecurityScope() throws {
        let recentURL = URL(fileURLWithPath: "/tmp/recent.mp4")
        let bookmarkData = Data(recentURL.path.utf8)
        let recent = DocumentRecent(
            url: recentURL,
            bookmarkData: bookmarkData,
            displayName: "Recent",
            lastOpened: Date()
        )
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [recent])
        let filesystemStub = FilesystemAccessStub()
        var resolvedReaderURL: URL?
        let controller = makeController(
            store: recentsStore,
            readerFactory: { url in
                resolvedReaderURL = url
                return StubRandomAccessReader()
            },
            workQueue: ImmediateWorkQueue(),
            filesystemAccess: filesystemStub.makeAccess()
        )

        controller.openRecent(recent)

        XCTAssertEqual(resolvedReaderURL?.standardizedFileURL, recentURL.standardizedFileURL)
        XCTAssertEqual(filesystemStub.manager.startedURLs, [recentURL.standardizedFileURL])
        XCTAssertTrue(filesystemStub.manager.stoppedURLs.isEmpty)
    }

    func testRetryingFailureClearsBannerAfterSuccessfulOpen() throws {
        let store = DocumentRecentsStoreStub(initialRecents: [])
        var shouldFail = true
        let controller = makeController(
            store: store,
            readerFactory: { _ in
                if shouldFail {
                    shouldFail = false
                    struct SampleError: LocalizedError {
                        var errorDescription: String? { "Simulated failure" }
                    }
                    throw SampleError()
                }
                return StubRandomAccessReader()
            },
            workQueue: ImmediateWorkQueue()
        )

        let url = URL(fileURLWithPath: "/tmp/retry.mp4")
        var cancellables: Set<AnyCancellable> = []
        let finished = expectation(description: "Parsing finished")

        controller.parseTreeStore.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        controller.openDocument(at: url)
        XCTAssertNotNil(controller.loadFailure)

        controller.retryLastFailure()
        wait(for: [finished], timeout: 1.0)

        XCTAssertNil(controller.loadFailure)
        XCTAssertEqual(controller.currentDocument?.url.standardizedFileURL, url.standardizedFileURL)
    }

    func testExportJSONWritesFullDocument() async throws {
        let issue = ValidationIssue(ruleID: "sample", message: "root", severity: .warning)
        let root = makeNode(identifier: 0, type: "moov", issues: [issue])
        let snapshot = ParseTreeSnapshot(nodes: [root], validationIssues: [issue])
        let parseTreeStore = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
        let filesystemStub = FilesystemAccessStub()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-full-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: destination) }
        filesystemStub.saveHandler = { _ in destination }

        let controller = makeController(
            store: DocumentRecentsStoreStub(initialRecents: []),
            filesystemAccess: filesystemStub.makeAccess(),
            parseTreeStore: parseTreeStore
        )

        await controller.exportJSON(scope: .document)

        XCTAssertEqual(filesystemStub.lastSaveConfiguration?.allowedContentTypes, [UTType.json.identifier])
        XCTAssertEqual(filesystemStub.lastSavedURL?.standardizedFileURL, destination.standardizedFileURL)
        let data = try Data(contentsOf: destination)
        let expected = try JSONParseTreeExporter().export(tree: ParseTree(nodes: [root], validationIssues: [issue]))
        XCTAssertEqual(data, expected)
        let status = try XCTUnwrap(controller.exportStatus)
        XCTAssertTrue(status.isSuccess)
        XCTAssertEqual(status.destinationURL?.standardizedFileURL, destination.standardizedFileURL)
        XCTAssertEqual(filesystemStub.manager.startedURLs, [destination.standardizedFileURL])
        XCTAssertEqual(filesystemStub.manager.stoppedURLs, [destination.standardizedFileURL])
    }

    func testExportJSONSelectionWritesSubtree() async throws {
        let childIssue = ValidationIssue(ruleID: "child", message: "child", severity: .error)
        let grandChild = makeNode(identifier: 64, type: "trak", issues: [childIssue])
        let parentIssue = ValidationIssue(ruleID: "parent", message: "parent", severity: .warning)
        let parent = makeNode(identifier: 0, type: "moov", issues: [parentIssue], children: [grandChild])
        let snapshot = ParseTreeSnapshot(nodes: [parent], validationIssues: [parentIssue, childIssue])
        let parseTreeStore = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
        let filesystemStub = FilesystemAccessStub()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-selection-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: destination) }
        filesystemStub.saveHandler = { _ in destination }

        let controller = makeController(
            store: DocumentRecentsStoreStub(initialRecents: []),
            filesystemAccess: filesystemStub.makeAccess(),
            parseTreeStore: parseTreeStore
        )

        await controller.exportJSON(scope: .selection(grandChild.id))

        let data = try Data(contentsOf: destination)
        let expected = try JSONParseTreeExporter().export(
            tree: ParseTree(nodes: [grandChild], validationIssues: [childIssue])
        )
        XCTAssertEqual(data, expected)
        let status = try XCTUnwrap(controller.exportStatus)
        XCTAssertTrue(status.isSuccess)
        XCTAssertEqual(status.destinationURL?.standardizedFileURL, destination.standardizedFileURL)
    }

    func testCanExportSelectionReflectsSnapshotMembership() throws {
        let node = makeNode(identifier: 0, type: "moov")
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [])
        let parseTreeStore = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
        let controller = makeController(
            store: DocumentRecentsStoreStub(initialRecents: []),
            parseTreeStore: parseTreeStore
        )

        XCTAssertTrue(controller.canExportSelection(nodeID: node.id))
        XCTAssertFalse(controller.canExportSelection(nodeID: -1))
        XCTAssertFalse(controller.canExportSelection(nodeID: nil))
    }

    func testPersistRecentsFailureEmitsDiagnostics() throws {
        enum SampleError: LocalizedError {
            case failed

            var errorDescription: String? { "Simulated recents failure" }
        }

        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        recentsStore.saveHandler = { _ in throw SampleError.failed }
        let diagnostics = DiagnosticsLoggerStub()
        let controller = makeController(
            store: recentsStore,
            diagnostics: diagnostics
        )

        controller.openDocument(at: URL(fileURLWithPath: "/tmp/recents.mp4"))

        XCTAssertEqual(diagnostics.errors.count, 1)
        let message = try XCTUnwrap(diagnostics.errors.first)
        XCTAssertTrue(message.contains("recents"))
        XCTAssertTrue(message.contains("Simulated recents failure"))
        XCTAssertTrue(message.contains("/tmp/recents.mp4"))
    }

    func testPersistSessionFailureEmitsDiagnostics() throws {
        enum SampleError: LocalizedError {
            case failed

            var errorDescription: String? { "Simulated session save failure" }
        }

        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        sessionStore.saveHandler = { _ in throw SampleError.failed }
        let diagnostics = DiagnosticsLoggerStub()
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            diagnostics: diagnostics
        )

        controller.openDocument(at: URL(fileURLWithPath: "/tmp/session.mp4"))

        XCTAssertEqual(diagnostics.errors.count, 1)
        let message = try XCTUnwrap(diagnostics.errors.first)
        XCTAssertTrue(message.contains("session"))
        XCTAssertTrue(message.contains("Simulated session save failure"))
        XCTAssertTrue(message.contains("sessionID"))
    }

    func testSelectingWorkspacePresetFiltersIssuesAndPersistsOverride() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let configStore = ValidationConfigurationStoreStub()
        configStore.storedConfiguration = ValidationConfiguration(activePresetID: "all-rules")
        let presets = [
            ValidationPreset(id: "all-rules", name: "All", summary: "", rules: []),
            ValidationPreset(
                id: "structural",
                name: "Structural",
                summary: "",
                rules: [ValidationPreset.RuleState(ruleID: .researchLogRecording, isEnabled: false)]
            )
        ]
        let parseTreeStore = ParseTreeStore(bridge: ParsePipelineEventBridge())
        let eventStream = makeValidationEventStream()
        let pipeline = ParsePipeline { _, _ in eventStream }
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            pipeline: pipeline,
            filesystemAccess: FilesystemAccessStub().makeAccess(),
            parseTreeStore: parseTreeStore,
            validationConfigStore: configStore,
            validationPresets: presets
        )

        let finished = expectation(description: "Parsing finished")
        var cancellables: Set<AnyCancellable> = []
        controller.parseTreeStore.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        let url = URL(fileURLWithPath: "/tmp/validation.mp4")
        controller.openDocument(at: url)
        wait(for: [finished], timeout: 1.0)

        XCTAssertEqual(controller.validationConfiguration.activePresetID, "all-rules")
        XCTAssertFalse(controller.isUsingWorkspaceValidationOverride)
        XCTAssertEqual(controller.parseTreeStore.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 2)

        controller.selectValidationPreset("structural", scope: .workspace)

        XCTAssertEqual(controller.validationConfiguration.activePresetID, "structural")
        XCTAssertTrue(controller.isUsingWorkspaceValidationOverride)
        XCTAssertEqual(controller.parseTreeStore.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 0)
        let savedSnapshot = try XCTUnwrap(sessionStore.savedSnapshots.last)
        let savedConfiguration = try XCTUnwrap(savedSnapshot.files.first?.validationConfiguration)
        XCTAssertEqual(savedConfiguration.activePresetID, "structural")
        XCTAssertTrue(savedConfiguration.ruleOverrides.isEmpty)

        controller.resetWorkspaceValidationOverrides()

        XCTAssertEqual(controller.validationConfiguration.activePresetID, "all-rules")
        XCTAssertFalse(controller.isUsingWorkspaceValidationOverride)
        XCTAssertEqual(controller.parseTreeStore.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 2)
        let resetSnapshot = try XCTUnwrap(sessionStore.savedSnapshots.last)
        XCTAssertNil(resetSnapshot.files.first?.validationConfiguration)
    }

    func testUpdatingGlobalConfigurationAppliesWhenNoOverride() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let configStore = ValidationConfigurationStoreStub()
        configStore.storedConfiguration = ValidationConfiguration(activePresetID: "all-rules")
        let presets = [
            ValidationPreset(id: "all-rules", name: "All", summary: "", rules: []),
            ValidationPreset(
                id: "structural",
                name: "Structural",
                summary: "",
                rules: [ValidationPreset.RuleState(ruleID: .researchLogRecording, isEnabled: false)]
            )
        ]
        let parseTreeStore = ParseTreeStore(bridge: ParsePipelineEventBridge())
        let eventStream = makeValidationEventStream()
        let pipeline = ParsePipeline { _, _ in eventStream }
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            pipeline: pipeline,
            filesystemAccess: FilesystemAccessStub().makeAccess(),
            parseTreeStore: parseTreeStore,
            validationConfigStore: configStore,
            validationPresets: presets
        )

        let finished = expectation(description: "Parsing finished")
        var cancellables: Set<AnyCancellable> = []
        controller.parseTreeStore.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        let url = URL(fileURLWithPath: "/tmp/global-validation.mp4")
        controller.openDocument(at: url)
        wait(for: [finished], timeout: 1.0)

        XCTAssertEqual(controller.globalValidationConfiguration.activePresetID, "all-rules")
        XCTAssertEqual(controller.parseTreeStore.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 2)

        controller.setValidationRule(.researchLogRecording, isEnabled: false, scope: .global)

        XCTAssertEqual(controller.globalValidationConfiguration.ruleOverrides[.researchLogRecording], false)
        XCTAssertEqual(configStore.savedConfigurations.last?.ruleOverrides[.researchLogRecording], false)
        XCTAssertEqual(controller.parseTreeStore.snapshot.validationIssues.filter { $0.ruleID == "VR-006" }.count, 0)
        XCTAssertFalse(controller.isUsingWorkspaceValidationOverride)
    }

    func testClearingSessionFailureEmitsDiagnostics() throws {
        enum SampleError: LocalizedError {
            case failed

            var errorDescription: String? { "Simulated session clear failure" }
        }

        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        sessionStore.clearHandler = { throw SampleError.failed }
        let diagnostics = DiagnosticsLoggerStub()
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            diagnostics: diagnostics
        )

        let url = URL(fileURLWithPath: "/tmp/clear.mp4")
        controller.openDocument(at: url)
        controller.removeRecent(at: IndexSet(integer: 0))

        XCTAssertEqual(diagnostics.errors.count, 1)
        let message = try XCTUnwrap(diagnostics.errors.first)
        XCTAssertTrue(message.contains("clear"))
        XCTAssertTrue(message.contains("Simulated session clear failure"))
        XCTAssertTrue(message.contains("sessionID"))
    }

        private func makeController(
            store: DocumentRecentsStoring,
            sessionStore: WorkspaceSessionStoring? = nil,
            annotationsStore: AnnotationBookmarkStoring? = nil,
            pipeline: ParsePipeline? = nil,
            readerFactory: ((URL) throws -> RandomAccessReader)? = nil,
            workQueue: DocumentSessionWorkQueue = ImmediateWorkQueue(),
            diagnostics: DiagnosticsLogging? = nil,
            bookmarkStore: BookmarkPersistenceManaging? = nil,
            filesystemAccess: FilesystemAccess? = nil,
            bookmarkDataProvider: ((SecurityScopedURL) -> Data?)? = nil,
            parseTreeStore: ParseTreeStore? = nil,
            validationConfigStore: ValidationConfigurationPersisting? = nil,
            validationPresets: [ValidationPreset]? = nil
        ) -> DocumentSessionController {
            let resolvedPipeline = pipeline ?? ParsePipeline(buildStream: { _, _ in .finishedStream })
            let resolvedDiagnostics: (any DiagnosticsLogging)? = diagnostics
            let access = filesystemAccess ?? FilesystemAccessStub().makeAccess()
            return DocumentSessionController(
                parseTreeStore: parseTreeStore ?? ParseTreeStore(bridge: ParsePipelineEventBridge()),
                annotations: AnnotationBookmarkSession(store: annotationsStore),
                recentsStore: store,
                sessionStore: sessionStore,
                pipelineFactory: { resolvedPipeline },
                readerFactory: readerFactory ?? { _ in StubRandomAccessReader() },
                workQueue: workQueue,
                diagnostics: resolvedDiagnostics,
                bookmarkStore: bookmarkStore,
                filesystemAccess: access,
                bookmarkDataProvider: bookmarkDataProvider,
                validationConfigurationStore: validationConfigStore,
                validationPresetLoader: { validationPresets ?? [] }
            )
        }

    private func makeValidationEventStream() -> ParsePipeline.EventStream {
        let parentHeader = BoxHeader(
            type: try! FourCharCode("root"),
            totalSize: 32,
            headerSize: 8,
            payloadRange: 8..<32,
            range: 0..<32,
            uuid: nil
        )
        let childHeader = BoxHeader(
            type: try! FourCharCode("test"),
            totalSize: 16,
            headerSize: 8,
            payloadRange: 8..<16,
            range: 8..<24,
            uuid: nil
        )
        let issues = [
            ValidationIssue(ruleID: "VR-006", message: "research", severity: .info),
            ValidationIssue(ruleID: "VR-001", message: "structure", severity: .error)
        ]

        let events = [
            ParseEvent(kind: .willStartBox(header: parentHeader, depth: 0), offset: 0, metadata: nil, validationIssues: []),
            ParseEvent(kind: .willStartBox(header: childHeader, depth: 1), offset: 8, metadata: nil, validationIssues: issues),
            ParseEvent(kind: .didFinishBox(header: childHeader, depth: 1), offset: 24, metadata: nil, validationIssues: issues),
            ParseEvent(kind: .didFinishBox(header: parentHeader, depth: 0), offset: 32, metadata: nil, validationIssues: [])
        ]

        return AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }

    private func sampleRecent(index: Int) -> DocumentRecent {
        DocumentRecent(
            url: URL(fileURLWithPath: "/tmp/sample-\(index).mp4"),
            bookmarkData: nil,
            displayName: "Sample \(index)",
            lastOpened: Date(timeIntervalSince1970: TimeInterval(index))
        )
    }

    private func makeNode(
        identifier: Int64,
        type: String,
        issues: [ValidationIssue] = [],
        children: [ParseTreeNode] = []
    ) -> ParseTreeNode {
        let totalSize: Int64 = 32
        let headerSize: Int64 = 8
        let header = BoxHeader(
            type: try! FourCharCode(type),
            totalSize: totalSize,
            headerSize: headerSize,
            payloadRange: (identifier + headerSize)..<(identifier + totalSize),
            range: identifier..<(identifier + totalSize),
            uuid: nil
        )
        return ParseTreeNode(
            header: header,
            metadata: nil,
            payload: nil,
            validationIssues: issues,
            children: children
        )
    }
}
#endif
