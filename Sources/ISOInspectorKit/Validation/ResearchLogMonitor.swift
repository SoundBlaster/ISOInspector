import Foundation

public enum ResearchLogSchema {
    public static let version = "1.0"
    public static let fieldNames = [
        "boxType",
        "filePath",
        "startOffset",
        "endOffset"
    ]
}

public struct ResearchLogAudit: Equatable {
    public let schemaVersion: String
    public let fieldNames: [String]
    public let entryCount: Int
    public let logExists: Bool

    public init(schemaVersion: String, fieldNames: [String], entryCount: Int, logExists: Bool) {
        self.schemaVersion = schemaVersion
        self.fieldNames = fieldNames
        self.entryCount = entryCount
        self.logExists = logExists
    }
}

public enum ResearchLogMonitor {
    // @todo #4 Integrate this audit with SwiftUI previews once UI surfaces consume VR-006 entries.
    // Telemetry for UI smoke tests is exercised by ResearchLogTelemetryProbe (todo.md #5).
    public enum Error: Swift.Error, Equatable {
        case schemaMismatch(expected: [String], actual: [String])
    }

    public static func audit(
        logURL: URL,
        fileManager: FileManager = .default
    ) throws -> ResearchLogAudit {
        let exists = fileManager.fileExists(atPath: logURL.path)
        guard exists else {
            return ResearchLogAudit(
                schemaVersion: ResearchLogSchema.version,
                fieldNames: ResearchLogSchema.fieldNames,
                entryCount: 0,
                logExists: false
            )
        }

        let data = try Data(contentsOf: logURL)
        guard !data.isEmpty else {
            return ResearchLogAudit(
                schemaVersion: ResearchLogSchema.version,
                fieldNames: ResearchLogSchema.fieldNames,
                entryCount: 0,
                logExists: true
            )
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let entries = json as? [[String: Any]] else {
            return ResearchLogAudit(
                schemaVersion: ResearchLogSchema.version,
                fieldNames: ResearchLogSchema.fieldNames,
                entryCount: 0,
                logExists: true
            )
        }

        let normalizedExpected = Set(ResearchLogSchema.fieldNames)

        if let first = entries.first {
            let actualKeys = Set(first.keys)
            if actualKeys != normalizedExpected {
                throw Error.schemaMismatch(
                    expected: ResearchLogSchema.fieldNames.sorted(),
                    actual: Array(actualKeys).sorted()
                )
            }
        }

        return ResearchLogAudit(
            schemaVersion: ResearchLogSchema.version,
            fieldNames: ResearchLogSchema.fieldNames,
            entryCount: entries.count,
            logExists: true
        )
    }
}
