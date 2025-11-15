public enum ValidationRuleIdentifier: String, CaseIterable, Codable, Sendable {
  case structuralSize = "VR-001"
  case containerBoundary = "VR-002"
  case versionFlags = "VR-003"
  case fileTypeOrdering = "VR-004"
  case movieDataOrdering = "VR-005"
  case researchLogRecording = "VR-006"
  case editListDuration = "VR-014"
  case sampleTableCorrelation = "VR-015"
  case fragmentSequence = "VR-016"
  case fragmentRun = "VR-017"
  case codecConfiguration = "VR-018"
}
