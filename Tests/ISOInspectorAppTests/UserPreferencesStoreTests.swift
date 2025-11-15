#if canImport(XCTest) && canImport(Foundation)
  import XCTest
  @testable import ISOInspectorApp

  @MainActor
  final class UserPreferencesStoreTests: XCTestCase {
    var temporaryDirectory: URL!
    var sut: FileBackedUserPreferencesStore!

    override func setUp() {
      super.setUp()
      temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
      try? FileManager.default.createDirectory(
        at: temporaryDirectory, withIntermediateDirectories: true)
      sut = FileBackedUserPreferencesStore(directory: temporaryDirectory)
    }

    override func tearDown() {
      try? FileManager.default.removeItem(at: temporaryDirectory)
      temporaryDirectory = nil
      sut = nil
      super.tearDown()
    }

    // MARK: - Load Tests

    func testLoadPreferences_WhenFileDoesNotExist_ReturnsNil() throws {
      // When
      let result = try sut.loadPreferences()

      // Then
      XCTAssertNil(result, "Should return nil when preferences file does not exist")
    }

    func testLoadPreferences_WhenFileExists_ReturnsDecodedPreferences() throws {
      // Given
      let preferences = UserPreferences()
      try sut.savePreferences(preferences)

      // When
      let result = try sut.loadPreferences()

      // Then
      XCTAssertNotNil(result)
      XCTAssertEqual(result, preferences)
    }

    // MARK: - Save Tests

    func testSavePreferences_CreatesFileWithCorrectData() throws {
      // Given
      let preferences = UserPreferences()

      // When
      try sut.savePreferences(preferences)

      // Then
      let storageURL = temporaryDirectory.appendingPathComponent("UserPreferences.json")
      XCTAssertTrue(FileManager.default.fileExists(atPath: storageURL.path))

      let data = try Data(contentsOf: storageURL)
      let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
      XCTAssertEqual(decoded, preferences)
    }

    func testSavePreferences_CreatesDirectoryIfNeeded() throws {
      // Given
      let nestedDirectory =
        temporaryDirectory
        .appendingPathComponent("nested", isDirectory: true)
        .appendingPathComponent("path", isDirectory: true)
      let store = FileBackedUserPreferencesStore(directory: nestedDirectory)
      let preferences = UserPreferences()

      // When
      try store.savePreferences(preferences)

      // Then
      XCTAssertTrue(FileManager.default.fileExists(atPath: nestedDirectory.path))
    }

    func testSavePreferences_OverwritesExistingFile() throws {
      // Given
      let firstPreferences = UserPreferences(
        validationPresetID: "strict"
      )
      let secondPreferences = UserPreferences(
        validationPresetID: "lenient"
      )

      // When
      try sut.savePreferences(firstPreferences)
      try sut.savePreferences(secondPreferences)

      // Then
      let result = try sut.loadPreferences()
      XCTAssertEqual(result?.validationPresetID, "lenient")
    }

    // MARK: - Reset Tests

    func testReset_RemovesPreferencesFile() throws {
      // Given
      let preferences = UserPreferences()
      try sut.savePreferences(preferences)

      // When
      try sut.reset()

      // Then
      let result = try sut.loadPreferences()
      XCTAssertNil(result, "Preferences should be nil after reset")
    }

    func testReset_WhenFileDoesNotExist_DoesNotThrow() throws {
      // When/Then
      XCTAssertNoThrow(try sut.reset())
    }

    // MARK: - JSON Format Tests

    func testSavePreferences_UsesPrettyPrintedJSON() throws {
      // Given
      let preferences = UserPreferences()
      try sut.savePreferences(preferences)

      // When
      let storageURL = temporaryDirectory.appendingPathComponent("UserPreferences.json")
      let data = try Data(contentsOf: storageURL)
      let jsonString = String(data: data, encoding: .utf8)

      // Then
      XCTAssertNotNil(jsonString)
      XCTAssertTrue(jsonString!.contains("\n"), "JSON should be pretty-printed with newlines")
    }
  }
#endif
