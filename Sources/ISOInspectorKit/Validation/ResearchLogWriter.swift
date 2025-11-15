import Dispatch
import Foundation

public struct ResearchLogEntry: Codable, Hashable, Sendable {
  public let boxType: String
  public let filePath: String
  public let startOffset: Int64
  public let endOffset: Int64

  public init(boxType: String, filePath: String, startOffset: Int64, endOffset: Int64) {
    self.boxType = boxType
    self.filePath = filePath
    self.startOffset = startOffset
    self.endOffset = endOffset
  }
}

public protocol ResearchLogRecording: Sendable {
  func record(_ entry: ResearchLogEntry)
}

public final class ResearchLogWriter: ResearchLogRecording, @unchecked Sendable {
  private let fileURL: URL
  private let queue = DispatchQueue(label: "ISOInspectorKit.ResearchLogWriter")
  private var entries: Set<ResearchLogEntry>
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let logger = DiagnosticsLogger(subsystem: "ISOInspectorKit", category: "ResearchLog")

  public init(fileURL: URL) throws {
    self.fileURL = fileURL
    self.encoder = JSONEncoder()
    self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    self.decoder = JSONDecoder()
    self.entries = try Self.loadExistingEntries(from: fileURL, decoder: decoder)
  }

  public func record(_ entry: ResearchLogEntry) {
    queue.sync {
      guard entries.insert(entry).inserted else {
        return
      }
      do {
        try persistLocked()
      } catch {
        logger.error("Failed to persist research log entry: \(error)")
      }
    }
  }

  public func loadEntries() -> [ResearchLogEntry] {
    queue.sync { sortedEntriesLocked() }
  }

  public static func defaultLogURL(fileManager: FileManager = .default) -> URL {
    #if os(macOS)
      let baseDirectory = fileManager.homeDirectoryForCurrentUser
    #else
      let baseDirectory =
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        ?? fileManager.temporaryDirectory
    #endif
    let base = baseDirectory.appendingPathComponent(".isoinspector", isDirectory: true)
    return base.appendingPathComponent("research-log.json", isDirectory: false)
  }

  private func persistLocked() throws {
    try ensureDirectoryExists()
    let data = try encoder.encode(sortedEntriesLocked())
    try data.write(to: fileURL, options: .atomic)
  }

  private func ensureDirectoryExists() throws {
    let directory = fileURL.deletingLastPathComponent()
    guard !directory.path.isEmpty else { return }
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
      if isDirectory.boolValue {
        return
      }
      throw CocoaError(.fileWriteFileExists)
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  private static func loadExistingEntries(from url: URL, decoder: JSONDecoder) throws -> Set<
    ResearchLogEntry
  > {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return []
    }
    do {
      let data = try Data(contentsOf: url)
      guard !data.isEmpty else { return [] }
      let decoded = try decoder.decode([ResearchLogEntry].self, from: data)
      return Set(decoded)
    } catch {
      throw error
    }
  }

  private func sortedEntriesLocked() -> [ResearchLogEntry] {
    entries.sorted(by: { lhs, rhs in
      if lhs.boxType == rhs.boxType {
        if lhs.filePath == rhs.filePath {
          return lhs.startOffset < rhs.startOffset
        }
        return lhs.filePath < rhs.filePath
      }
      return lhs.boxType < rhs.boxType
    })
  }
}
