import Foundation

extension BoxParserRegistry.DefaultParsers {
    // MARK: - Byte Reading Helpers

    @inline(__always) static func readData(
        _ reader: RandomAccessReader, at offset: Int64, count: Int, end: Int64
    ) throws -> Data? {
        guard offset + Int64(count) <= end else { return nil }
        let data = try reader.read(at: offset, count: count)
        guard data.count == count else { return nil }
        return data
    }

    @inline(__always) static func readUInt16(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> UInt16? {
        guard offset + 2 <= end else { return nil }
        guard let data = try? reader.read(at: offset, count: 2), data.count == 2 else { return nil }
        return (UInt16(data[0]) << 8) | UInt16(data[1])
    }

    static func decodeISO639Language(_ rawValue: UInt16) -> String? {
        if rawValue == 0x7FFF { return "und" }
        let first = UInt8((rawValue >> 10) & 0x1F)
        let second = UInt8((rawValue >> 5) & 0x1F)
        let third = UInt8(rawValue & 0x1F)
        guard first != 0, second != 0, third != 0 else { return nil }
        let bytes = [first + 0x60, second + 0x60, third + 0x60]
        return String(bytes: bytes, encoding: .ascii)
    }

    @inline(__always) static func readUInt32(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> UInt32? {
        guard offset + 4 <= end else { return nil }
        return try? reader.readUInt32(at: offset)
    }

    @inline(__always) static func readUInt64(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> UInt64? {
        guard offset + 8 <= end else { return nil }
        return try? reader.readUInt64(at: offset)
    }

    @inline(__always) static func readFourCC(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> FourCharCode? {
        guard offset + 4 <= end else { return nil }
        return try? reader.readFourCC(at: offset)
    }

    @inline(__always) static func readInt16(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> Int16? {
        guard offset + 2 <= end else { return nil }
        guard let data = try? reader.read(at: offset, count: 2), data.count == 2 else { return nil }
        let value = UInt16(data[0]) << 8 | UInt16(data[1])
        return Int16(bitPattern: value)
    }

    @inline(__always) static func readInt32(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> Int32? {
        guard let raw = try readUInt32(reader, at: offset, end: end) else { return nil }
        return Int32(bitPattern: raw)
    }

    @inline(__always) static func readInt64(
        _ reader: RandomAccessReader, at offset: Int64, end: Int64
    ) throws -> Int64? {
        guard let raw = try readUInt64(reader, at: offset, end: end) else { return nil }
        return Int64(bitPattern: raw)
    }

    // MARK: - Formatting Helpers

    static func formatFixedPoint(_ value: UInt32, integerBits: Int) -> String {
        let fractionalBits = 32 - integerBits
        let scale = Double(1 << fractionalBits)
        let integer = Int32(bitPattern: value) >> fractionalBits
        let fractional = Double(value & UInt32((1 << fractionalBits) - 1)) / scale
        return String(format: "%.2f", Double(integer) + fractional)
    }

    static func decodeSignedFixedPoint(_ value: Int32, fractionalBits: Int) -> Double {
        Double(value) / Double(1 << fractionalBits)
    }

    static func formatSignedFixedPoint(_ value: Int32, fractionalBits: Int, precision: Int)
        -> String
    {
        let formatted = decodeSignedFixedPoint(value, fractionalBits: fractionalBits)
        return String(format: "%.\(precision)f", formatted)
    }

    static func normalizedSeconds(for value: UInt64, timescale: UInt32?) -> Double? {
        guard let timescale, timescale != 0 else { return nil }
        return Double(value) / Double(timescale)
    }

    static func normalizedSeconds(forSigned value: Int64, timescale: UInt32?) -> Double? {
        guard let timescale, timescale != 0 else { return nil }
        return Double(value) / Double(timescale)
    }

    static func quantizedSeconds(_ value: Double?, decimalPlaces: Int = 6) -> Double? {
        guard let value else { return nil }
        let scale = pow(10.0, Double(decimalPlaces))
        return (value * scale).rounded() / scale
    }

    static func formatSeconds(_ value: Double) -> String { String(format: "%.6f", value) }

    static func formatMediaRate(_ value: Double) -> String { String(format: "%.4f", value) }

    static func boolString(_ value: Bool) -> String { value ? "true" : "false" }

    static func describeGraphicsMode(_ raw: UInt16) -> String? {
        switch raw {
        case 0: return "copy"
        case 1: return "ditherCopy"
        case 2: return "componentAlpha"
        case 3: return "preMultipliedAlpha"
        default: return nil
        }
    }

    static func decodeHandlerName(from data: Data, at offset: Int64) -> ParsedBoxPayload.Field? {
        guard !data.isEmpty else { return nil }
        let nameData: Data
        if let terminatorIndex = data.firstIndex(of: 0) {
            nameData = data.prefix(upTo: terminatorIndex)
        } else {
            nameData = data
        }
        guard !nameData.isEmpty else { return nil }
        guard let name = String(data: nameData, encoding: .utf8) else { return nil }
        let nameEnd = offset + Int64(nameData.count)
        return ParsedBoxPayload.Field(
            name: "handler_name", value: name, description: "Handler name",
            byteRange: offset..<nameEnd)
    }
}
