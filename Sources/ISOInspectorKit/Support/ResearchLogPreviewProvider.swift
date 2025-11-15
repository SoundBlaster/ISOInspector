import Foundation

public struct ResearchLogPreviewSnapshot: Equatable {
  public enum State: Equatable, CustomStringConvertible {
    case ready(ResearchLogAudit)
    case missingFixture(ResearchLogAudit)
    case schemaMismatch(expected: [String], actual: [String])
    case loadFailure(message: String)

    public var description: String {
      switch self {
      case .ready:
        return "ready"
      case .missingFixture:
        return "missingFixture"
      case .schemaMismatch:
        return "schemaMismatch"
      case .loadFailure(let message):
        return "loadFailure(\(message))"
      }
    }
  }

  public let fixtureName: String
  public let state: State
  public let diagnostics: [String]
}

/// Provides deterministic VR-006 research log snapshots for SwiftUI previews so UI developers
/// can validate bindings against the shared schema before wiring live parse pipelines.
/// The helper intentionally mirrors the monitoring checkpoints documented in
/// `DOCS/TASK_ARCHIVE/15_Monitor_VR006_Research_Log_Adoption/VR006_Monitoring_Checklist.md`
/// by surfacing schema and fixture drift during preview rendering.
public enum ResearchLogPreviewProvider {
  private static func resolveBundle(_ bundle: Bundle?) -> Bundle {
    bundle ?? .module
  }

  private static func snapshot(
    resourceName: String,
    bundle: Bundle?,
    fileManager: FileManager
  ) -> ResearchLogPreviewSnapshot {
    let resolvedBundle = resolveBundle(bundle)
    let fixtureName = "\(resourceName).json"

    guard
      let fixtureURL = resolvedBundle.url(
        forResource: resourceName,
        withExtension: "json"
      )
    else {
      let audit = ResearchLogAudit(
        schemaVersion: ResearchLogSchema.version,
        fieldNames: ResearchLogSchema.fieldNames,
        entryCount: 0,
        logExists: false
      )

      return ResearchLogPreviewSnapshot(
        fixtureName: fixtureName,
        state: .missingFixture(audit),
        diagnostics: [
          "VR-006 preview fixture \(fixtureName) is missing from \(resolvedBundle.bundleURL.lastPathComponent).",
          "Update preview resources alongside ResearchLogSchema.fieldNames (\(ResearchLogSchema.fieldNames.joined(separator: ", "))).",
          "Consult the VR-006 monitoring checklist to confirm preview fixtures stay in sync with the shared schema.",
        ]
      )
    }

    do {
      let audit = try ResearchLogMonitor.audit(logURL: fixtureURL, fileManager: fileManager)
      return ResearchLogPreviewSnapshot(
        fixtureName: fixtureName,
        state: .ready(audit),
        diagnostics: [
          "VR-006 schema v\(audit.schemaVersion) confirmed for preview fixture \(fixtureName).",
          "Fields: \(audit.fieldNames.joined(separator: ", ")).",
          "Entries audited: \(audit.entryCount).",
        ]
      )
    } catch let error as ResearchLogMonitor.Error {
      switch error {
      case .schemaMismatch(let expected, let actual):
        return ResearchLogPreviewSnapshot(
          fixtureName: fixtureName,
          state: .schemaMismatch(expected: expected, actual: actual),
          diagnostics: [
            "Schema mismatch detected for \(fixtureName).",
            "Expected fields: \(expected.joined(separator: ", ")).",
            "Actual fields: \(actual.joined(separator: ", ")).",
            "Update preview fixtures to align with ResearchLogSchema.fieldNames before wiring UI previews.",
          ]
        )
      }
    } catch {
      return ResearchLogPreviewSnapshot(
        fixtureName: fixtureName,
        state: .loadFailure(message: error.localizedDescription),
        diagnostics: [
          "Failed to audit preview fixture \(fixtureName): \(error.localizedDescription).",
          "Confirm preview fixtures contain valid VR-006 JSON arrays before running SwiftUI previews.",
        ]
      )
    }
  }

  public static func validFixture(
    bundle: Bundle? = nil,
    fileManager: FileManager = .default
  ) -> ResearchLogPreviewSnapshot {
    snapshot(resourceName: "VR006PreviewLog", bundle: bundle, fileManager: fileManager)
  }

  public static func missingFixture(
    bundle: Bundle? = nil,
    fileManager: FileManager = .default
  ) -> ResearchLogPreviewSnapshot {
    snapshot(resourceName: "VR006PreviewLog_Missing", bundle: bundle, fileManager: fileManager)
  }

  public static func schemaMismatchFixture(
    bundle: Bundle? = nil,
    fileManager: FileManager = .default
  ) -> ResearchLogPreviewSnapshot {
    snapshot(resourceName: "VR006PreviewLog_Mismatch", bundle: bundle, fileManager: fileManager)
  }
}
