import Foundation

struct PayloadAnnotation: Identifiable, Equatable {
  let id: UUID
  let label: String
  let value: String
  let byteRange: Range<Int64>
  let summary: String?

  init(
    id: UUID = UUID(), label: String, value: String, byteRange: Range<Int64>, summary: String? = nil
  ) {
    self.id = id
    self.label = label
    self.value = value
    self.byteRange = byteRange
    self.summary = summary
  }
}

extension PayloadAnnotation {
  var formattedRange: String {
    "\(byteRange.lowerBound) – \(byteRange.upperBound)"
  }
}
