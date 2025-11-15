import Foundation

public struct ResearchLogTelemetrySnapshot: Equatable {
  public enum State: Equatable, CustomStringConvertible {
    case ready(ResearchLogAudit)
    case missingLog(ResearchLogAudit)
    case emptyLog(ResearchLogAudit)
    case schemaMismatch(expected: [String], actual: [String])
    case loadFailure(message: String)

    public var description: String {
      switch self {
      case .ready(let audit):
        return "ready(entries: \(audit.entryCount))"
      case .missingLog:
        return "missingLog"
      case .emptyLog:
        return "emptyLog"
      case .schemaMismatch(let expected, let actual):
        return "schemaMismatch(expected: \(expected), actual: \(actual))"
      case .loadFailure(let message):
        return "loadFailure(\(message))"
      }
    }
  }

  public let logURL: URL
  public let state: State
  public let diagnostics: [String]
}

public enum ResearchLogTelemetryProbe {
  public static func capture(
    logURL: URL,
    fileManager: FileManager = .default
  ) -> ResearchLogTelemetrySnapshot {
    do {
      let audit = try ResearchLogMonitor.audit(logURL: logURL, fileManager: fileManager)
      if !audit.logExists {
        return ResearchLogTelemetrySnapshot(
          logURL: logURL,
          state: .missingLog(audit),
          diagnostics: missingDiagnostics(for: logURL, audit: audit)
        )
      }
      if audit.entryCount == 0 {
        return ResearchLogTelemetrySnapshot(
          logURL: logURL,
          state: .emptyLog(audit),
          diagnostics: emptyDiagnostics(for: logURL, audit: audit)
        )
      }
      return ResearchLogTelemetrySnapshot(
        logURL: logURL,
        state: .ready(audit),
        diagnostics: readyDiagnostics(for: logURL, audit: audit)
      )
    } catch let error as ResearchLogMonitor.Error {
      switch error {
      case .schemaMismatch(let expected, let actual):
        return ResearchLogTelemetrySnapshot(
          logURL: logURL,
          state: .schemaMismatch(expected: expected, actual: actual),
          diagnostics: schemaMismatchDiagnostics(for: logURL, expected: expected, actual: actual)
        )
      }
    } catch {
      return ResearchLogTelemetrySnapshot(
        logURL: logURL,
        state: .loadFailure(message: error.localizedDescription),
        diagnostics: loadFailureDiagnostics(for: logURL, message: error.localizedDescription)
      )
    }
  }

  private static func readyDiagnostics(for logURL: URL, audit: ResearchLogAudit) -> [String] {
    [
      "VR-006 telemetry ready for \(displayName(for: logURL)); CLI `isoinspect inspect` and SwiftUI previews recorded \(audit.entryCount) research entries (todo.md #5).",
      "ResearchLogSchema v\(audit.schemaVersion) fields: \(audit.fieldNames.joined(separator: ", ")).",
      "Telemetry aligns CLI pipelines and SwiftUI fixtures so VR-006 dashboards stay green.",
    ]
  }

  private static func missingDiagnostics(for logURL: URL, audit: ResearchLogAudit) -> [String] {
    [
      "UI smoke telemetry detected missing VR-006 research log at \(logURL.path). Wire CLI `isoinspect inspect` and SwiftUI previews to persist research entries (todo.md #5).",
      "ResearchLogSchema v\(audit.schemaVersion) expects fields: \(audit.fieldNames.joined(separator: ", ")).",
      "Consult the VR-006 monitoring checklist to restore telemetry before shipping UI builds.",
    ]
  }

  private static func emptyDiagnostics(for logURL: URL, audit: ResearchLogAudit) -> [String] {
    [
      "UI smoke telemetry detected empty VR-006 research log at \(logURL.path). CLI `isoinspect inspect` and SwiftUI previews must record at least one unknown box entry (todo.md #5).",
      "ResearchLogSchema v\(audit.schemaVersion) fields: \(audit.fieldNames.joined(separator: ", ")).",
      "Review smoke test fixtures so CLI and SwiftUI instrumentation stay synchronized.",
    ]
  }

  private static func schemaMismatchDiagnostics(
    for logURL: URL,
    expected: [String],
    actual: [String]
  ) -> [String] {
    [
      "UI smoke telemetry detected VR-006 schema mismatch at \(displayName(for: logURL)). CLI `isoinspect inspect` and SwiftUI previews disagreed with ResearchLogSchema.fieldNames (todo.md #5).",
      "Expected fields: \(expected.joined(separator: ", ")).",
      "Actual fields: \(actual.joined(separator: ", ")). Update telemetry per the VR-006 monitoring checklist.",
    ]
  }

  private static func loadFailureDiagnostics(for logURL: URL, message: String) -> [String] {
    [
      "UI smoke telemetry failed to load VR-006 research log at \(logURL.path): \(message).",
      "Inspect CLI `isoinspect inspect` output and SwiftUI preview fixtures to repair research log persistence.",
    ]
  }

  private static func displayName(for logURL: URL) -> String {
    let last = logURL.lastPathComponent
    return last.isEmpty ? logURL.path : last
  }
}
