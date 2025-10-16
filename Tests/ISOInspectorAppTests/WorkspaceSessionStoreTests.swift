import XCTest
@testable import ISOInspectorApp

final class WorkspaceSessionStoreTests: XCTestCase {
    func testFileBackedStoreRoundTrip() throws {
        let directory = try makeTemporaryDirectory()
        let store = FileBackedWorkspaceSessionStore(directory: directory)
        let snapshot = makeSampleSnapshot()

        try store.saveCurrentSession(snapshot)
        let loaded = try store.loadCurrentSession()

        XCTAssertEqual(loaded, snapshot)
    }

    func testFileBackedStoreClearRemovesSnapshot() throws {
        let directory = try makeTemporaryDirectory()
        let store = FileBackedWorkspaceSessionStore(directory: directory)
        let snapshot = makeSampleSnapshot()

        try store.saveCurrentSession(snapshot)
        try store.clearCurrentSession()

        XCTAssertNil(try store.loadCurrentSession())
    }

    // MARK: - Helpers

    private func makeSampleSnapshot() -> WorkspaceSessionSnapshot {
        let primaryURL = URL(fileURLWithPath: "/tmp/sample.mp4")
        let secondaryURL = URL(fileURLWithPath: "/tmp/second.mp4")
        let primaryRecent = DocumentRecent(
            url: primaryURL,
            bookmarkData: Data([0x01]),
            displayName: "Sample",
            lastOpened: Date(timeIntervalSince1970: 100)
        )
        let secondaryRecent = DocumentRecent(
            url: secondaryURL,
            bookmarkData: nil,
            displayName: "Second",
            lastOpened: Date(timeIntervalSince1970: 50)
        )
        return WorkspaceSessionSnapshot(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            appVersion: "1.0",
            files: [
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!,
                    recent: primaryRecent,
                    orderIndex: 0,
                    lastSelectionNodeID: 42,
                    isPinned: false,
                    scrollOffset: WorkspaceSessionScrollOffset(x: 1, y: 2),
                    bookmarkIdentifier: primaryRecent.bookmarkIdentifier,
                    bookmarkDiffs: []
                ),
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-0000000000CC")!,
                    recent: secondaryRecent,
                    orderIndex: 1,
                    lastSelectionNodeID: nil,
                    isPinned: true,
                    scrollOffset: nil,
                    bookmarkIdentifier: secondaryRecent.bookmarkIdentifier,
                    bookmarkDiffs: []
                )
            ],
            focusedFileURL: primaryURL,
            lastSceneIdentifier: "scene",
            windowLayouts: [
                WorkspaceWindowLayoutSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-0000000000DD")!,
                    sceneIdentifier: "scene",
                    serializedLayout: Data([0xAA, 0xBB]),
                    isFloatingInspector: false
                )
            ]
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
