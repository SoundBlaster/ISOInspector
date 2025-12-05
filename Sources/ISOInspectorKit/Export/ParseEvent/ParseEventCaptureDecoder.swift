import Foundation

public struct ParseEventCaptureDecoder {
    private let decoder: PropertyListDecoder

    public init(decoder: PropertyListDecoder = PropertyListDecoder()) { self.decoder = decoder }

    public func decode(data: Data) throws -> [ParseEvent] {
        let payload = try decoder.decode(ParseEventCapturePayload.self, from: data)
        guard payload.version == 1 else {
            throw ParseEventCaptureDecodingError.unsupportedVersion(payload.version)
        }
        return try payload.parseEvents()
    }
}
