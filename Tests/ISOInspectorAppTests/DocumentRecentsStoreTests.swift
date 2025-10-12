import XCTest
@testable import ISOInspectorApp

final class DocumentRecentsStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        try super.tearDownWithError()
    }

    func testLoadingWithoutExistingFileReturnsEmptyList() throws {
        let store = DocumentRecentsStore(directory: directory)
        let recents = try store.load()
        XCTAssertTrue(recents.isEmpty)
    }

    func testSavedRecentsArePersisted() throws {
        let store = DocumentRecentsStore(directory: directory)
        let fileURL = URL(fileURLWithPath: "/tmp/example.mp4")
        let entries = [
            DocumentRecent(
                url: fileURL,
                bookmarkData: Data("bookmark".utf8),
                displayName: "Example",
                lastOpened: Date(timeIntervalSince1970: 12345)
            ),
            DocumentRecent(
                url: fileURL.appendingPathComponent("other"),
                bookmarkData: nil,
                displayName: "Other",
                lastOpened: Date(timeIntervalSince1970: 67890)
            )
        ]

        try store.save(entries)
        let loaded = try store.load()

        XCTAssertEqual(loaded, entries)
    }
}
