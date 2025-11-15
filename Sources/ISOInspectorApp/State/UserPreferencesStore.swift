#if canImport(Foundation)
import Foundation

/// Protocol defining user preferences persistence operations.
protocol UserPreferencesPersisting {
    /// Loads user preferences from persistent storage.
    /// - Returns: Decoded `UserPreferences` if file exists, `nil` otherwise.
    /// - Throws: Decoding or I/O errors.
    func loadPreferences() throws -> UserPreferences?

    /// Saves user preferences to persistent storage.
    /// - Parameter preferences: The preferences to persist.
    /// - Throws: Encoding or I/O errors.
    func savePreferences(_ preferences: UserPreferences) throws

    /// Resets user preferences by deleting the persistent storage file.
    /// Falls back to defaults on next load.
    /// - Throws: File system errors (silent if file doesn't exist).
    func reset() throws
}

/// File-backed implementation of user preferences storage.
/// Persists preferences as JSON in Application Support directory.
struct FileBackedUserPreferencesStore: UserPreferencesPersisting {
    private let storageURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a store instance with the specified storage directory.
    /// - Parameters:
    ///   - directory: Directory where UserPreferences.json will be stored.
    ///   - fileName: Name of the JSON file (default: "UserPreferences.json").
    init(directory: URL, fileName: String = "UserPreferences.json") {
        self.storageURL = directory.appendingPathComponent(fileName, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    func loadPreferences() throws -> UserPreferences? {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: storageURL)
        return try decoder.decode(UserPreferences.self, from: data)
    }

    func savePreferences(_ preferences: UserPreferences) throws {
        let data = try encoder.encode(preferences)
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try data.write(to: storageURL, options: .atomic)
    }

    func reset() throws {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            try FileManager.default.removeItem(at: storageURL)
        }
    }
}
#endif
