import Foundation

public struct ParseEventCaptureEncoder {
  private let encoder: PropertyListEncoder

  public init(encoder: PropertyListEncoder = PropertyListEncoder()) {
    let configured = encoder
    configured.outputFormat = .binary
    self.encoder = configured
  }

  public func encode(events: [ParseEvent]) throws -> Data {
    let payload = ParseEventCapturePayload(events: events)
    return try encoder.encode(payload)
  }
}
