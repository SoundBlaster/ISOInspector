import Foundation

public enum ParseEventCaptureDecodingError: Swift.Error, Equatable {
  case unsupportedVersion(Int)
  case invalidFourCharCode(String)
}
