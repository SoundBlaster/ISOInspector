#if canImport(Foundation)
    import Foundation
    import ISOInspectorKit

    protocol ValidationConfigurationPersisting {
        func loadConfiguration() throws -> ValidationConfiguration?
        func saveConfiguration(_ configuration: ValidationConfiguration) throws
        func clearConfiguration() throws
    }

    struct FileBackedValidationConfigurationStore: ValidationConfigurationPersisting {
        private let storageURL: URL
        private let encoder: JSONEncoder
        private let decoder: JSONDecoder

        init(directory: URL, fileName: String = "ValidationConfiguration.json") {
            self.storageURL = directory.appendingPathComponent(fileName, isDirectory: false)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            self.encoder = encoder
            self.decoder = JSONDecoder()
        }

        func loadConfiguration() throws -> ValidationConfiguration? {
            guard FileManager.default.fileExists(atPath: storageURL.path) else { return nil }
            let data = try Data(contentsOf: storageURL)
            return try decoder.decode(ValidationConfiguration.self, from: data)
        }

        func saveConfiguration(_ configuration: ValidationConfiguration) throws {
            let data = try encoder.encode(configuration)
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true)
            try data.write(to: storageURL, options: .atomic)
        }

        func clearConfiguration() throws {
            if FileManager.default.fileExists(atPath: storageURL.path) {
                try FileManager.default.removeItem(at: storageURL)
            }
        }
    }
#endif
