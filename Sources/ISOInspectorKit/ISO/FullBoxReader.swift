import Foundation

public struct FullBoxHeaderFields: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let contentRange: Range<Int64>

    public var contentStart: Int64 { contentRange.lowerBound }

    public init(version: UInt8, flags: UInt32, contentRange: Range<Int64>) {
        self.version = version
        self.flags = flags
        self.contentRange = contentRange
    }
}

public enum FullBoxReader {
    public static func read(header: BoxHeader, reader: RandomAccessReader) throws
        -> FullBoxHeaderFields?
    {
        let payloadRange = header.payloadRange
        let availableBytes = payloadRange.upperBound - payloadRange.lowerBound
        guard availableBytes >= 4 else { return nil }

        let versionData = try reader.read(at: payloadRange.lowerBound, count: 1)
        guard versionData.count == 1, let version = versionData.first else { return nil }

        let flagsData = try reader.read(at: payloadRange.lowerBound + 1, count: 3)
        guard flagsData.count == 3 else { return nil }
        let flags = flagsData.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }

        let contentStart = payloadRange.lowerBound + 4
        return FullBoxHeaderFields(
            version: version, flags: flags, contentRange: contentStart..<payloadRange.upperBound)
    }
}
