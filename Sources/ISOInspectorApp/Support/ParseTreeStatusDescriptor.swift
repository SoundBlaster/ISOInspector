import ISOInspectorKit

struct ParseTreeStatusDescriptor: Equatable {
  enum Level: Equatable {
    case info
    case warning
    case error
    case success
  }

  let text: String
  let level: Level
  let accessibilityLabel: String

  init?(status: ParseTreeNode.Status) {
    switch status {
    case .valid:
      return nil
    case .partial:
      self.text = "Partial"
      self.level = .warning
      self.accessibilityLabel = "Partial status"
    case .corrupt:
      self.text = "Corrupted"
      self.level = .error
      self.accessibilityLabel = "Corrupted status"
    case .skipped:
      self.text = "Skipped"
      self.level = .info
      self.accessibilityLabel = "Skipped status"
    case .invalid:
      self.text = "Invalid"
      self.level = .error
      self.accessibilityLabel = "Invalid status"
    case .empty:
      self.text = "Empty"
      self.level = .warning
      self.accessibilityLabel = "Empty status"
    case .trimmed:
      self.text = "Trimmed"
      self.level = .warning
      self.accessibilityLabel = "Trimmed status"
    }
  }
}
