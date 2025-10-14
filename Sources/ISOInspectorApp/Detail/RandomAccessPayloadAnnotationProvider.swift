import Foundation

#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif

final class RandomAccessPayloadAnnotationProvider: PayloadAnnotationProvider {
    private let reader: RandomAccessReader

    init(reader: RandomAccessReader) {
        self.reader = reader
    }

    func annotations(for header: BoxHeader) async throws -> [PayloadAnnotation] {
        try Task.checkCancellation()
        let payloadStart = header.payloadRange.lowerBound
        let payloadEnd = header.payloadRange.upperBound
        guard payloadEnd > payloadStart else { return [] }

        if let payload = try BoxParserRegistry.shared.parse(header: header, reader: reader),
           let derived = annotations(from: payload) {
            return derived
        }

        var annotations: [PayloadAnnotation] = []

        switch header.type.rawValue {
        case "ftyp":
            annotations.append(contentsOf: try parseFileTypeBox(header: header, start: payloadStart, end: payloadEnd))
        case "mvhd":
            annotations.append(contentsOf: try parseMovieHeaderBox(header: header, start: payloadStart, end: payloadEnd))
        default:
            break
        }

        return annotations.sorted { lhs, rhs in
            lhs.byteRange.lowerBound < rhs.byteRange.lowerBound
        }
    }
}

private extension RandomAccessPayloadAnnotationProvider {
    func annotations(from payload: ParsedBoxPayload) -> [PayloadAnnotation]? {
        let mapped = payload.fields.compactMap { field -> PayloadAnnotation? in
            guard let range = field.byteRange else { return nil }
            return PayloadAnnotation(
                label: field.name,
                value: field.value,
                byteRange: range,
                summary: field.description
            )
        }
        return mapped.isEmpty ? nil : mapped
    }

    func parseFileTypeBox(header: BoxHeader, start: Int64, end: Int64) throws -> [PayloadAnnotation] {
        var results: [PayloadAnnotation] = []
        guard end - start >= 8 else { return results }

        let majorBrand = try reader.readFourCC(at: start)
        results.append(PayloadAnnotation(
            label: "major_brand",
            value: majorBrand.rawValue,
            byteRange: start..<(start + 4),
            summary: "Primary brand identifying the file"
        ))

        let minorVersion = try reader.readUInt32(at: start + 4)
        results.append(PayloadAnnotation(
            label: "minor_version",
            value: String(minorVersion),
            byteRange: (start + 4)..<(start + 8),
            summary: "File type minor version"
        ))

        var offset = start + 8
        var index = 0
        while offset + 4 <= end {
            let brand = try reader.readFourCC(at: offset)
            let range = offset..<(offset + 4)
            results.append(PayloadAnnotation(
                label: "compatible_brand[\(index)]",
                value: brand.rawValue,
                byteRange: range,
                summary: "Brand compatibility entry"
            ))
            offset += 4
            index += 1
        }

        return results
    }

    func parseMovieHeaderBox(header: BoxHeader, start: Int64, end: Int64) throws -> [PayloadAnnotation] {
        var results: [PayloadAnnotation] = []
        var cursor = start

        guard let versionData = try safeRead(at: cursor, count: 1, end: end) else { return results }
        let version = versionData[0]
        results.append(PayloadAnnotation(
            label: "version",
            value: String(version),
            byteRange: cursor..<(cursor + 1),
            summary: "Structure version"
        ))
        cursor += 1

        if let flagsData = try safeRead(at: cursor, count: 3, end: end) {
            let flags = flagsData.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            results.append(PayloadAnnotation(
                label: "flags",
                value: String(format: "0x%06X", flags),
                byteRange: cursor..<(cursor + 3),
                summary: "Bit flags"
            ))
        }
        cursor += 3

        if version == 1 {
            if let creation = try readUInt64(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "creation_time",
                    value: String(creation),
                    byteRange: cursor..<(cursor + 8),
                    summary: "Movie creation timestamp"
                ))
                cursor += 8
            }
            if let modification = try readUInt64(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "modification_time",
                    value: String(modification),
                    byteRange: cursor..<(cursor + 8),
                    summary: "Last modification timestamp"
                ))
                cursor += 8
            }
            if let timescale = try readUInt32(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "timescale",
                    value: String(timescale),
                    byteRange: cursor..<(cursor + 4),
                    summary: "Time units per second"
                ))
                cursor += 4
            }
            if let duration = try readUInt64(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "duration",
                    value: String(duration),
                    byteRange: cursor..<(cursor + 8),
                    summary: "Movie duration"
                ))
                cursor += 8
            }
        } else {
            if let creation = try readUInt32(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "creation_time",
                    value: String(creation),
                    byteRange: cursor..<(cursor + 4),
                    summary: "Movie creation timestamp"
                ))
                cursor += 4
            }
            if let modification = try readUInt32(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "modification_time",
                    value: String(modification),
                    byteRange: cursor..<(cursor + 4),
                    summary: "Last modification timestamp"
                ))
                cursor += 4
            }
            if let timescale = try readUInt32(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "timescale",
                    value: String(timescale),
                    byteRange: cursor..<(cursor + 4),
                    summary: "Time units per second"
                ))
                cursor += 4
            }
            if let duration = try readUInt32(at: cursor, end: end) {
                results.append(PayloadAnnotation(
                    label: "duration",
                    value: String(duration),
                    byteRange: cursor..<(cursor + 4),
                    summary: "Movie duration"
                ))
                cursor += 4
            }
        }

        if let rate = try readUInt32(at: cursor, end: end) {
            let fixed = formatFixedPoint(rate, integerBits: 16)
            results.append(PayloadAnnotation(
                label: "rate",
                value: fixed,
                byteRange: cursor..<(cursor + 4),
                summary: "Playback rate"
            ))
            cursor += 4
        }

        if let volumeValue = try safeRead(at: cursor, count: 2, end: end) {
            let raw = UInt16(volumeValue[0]) << 8 | UInt16(volumeValue[1])
            let volume = Double(raw) / 256.0
            results.append(PayloadAnnotation(
                label: "volume",
                value: String(format: "%.2f", volume),
                byteRange: cursor..<(cursor + 2),
                summary: "Playback volume"
            ))
            cursor += 2
        }

        // Skip reserved 10 bytes (2 bytes padding already consumed by volume high bits)
        let reservedLength: Int64 = 10
        if cursor + reservedLength <= end {
            results.append(PayloadAnnotation(
                label: "reserved",
                value: "10 bytes",
                byteRange: cursor..<(cursor + reservedLength),
                summary: "Reserved"
            ))
            cursor += reservedLength
        } else {
            return results
        }

        // Matrix structure (9 fixed-point values)
        let matrixLength: Int64 = 36
        if cursor + matrixLength <= end {
            results.append(PayloadAnnotation(
                label: "matrix",
                value: "3x3",
                byteRange: cursor..<(cursor + matrixLength),
                summary: "Transformation matrix"
            ))
            cursor += matrixLength
        } else {
            return results
        }

        let predefinedLength: Int64 = 24
        if cursor + predefinedLength <= end {
            results.append(PayloadAnnotation(
                label: "pre_defined",
                value: "24 bytes",
                byteRange: cursor..<(cursor + predefinedLength),
                summary: "Pre-defined"
            ))
            cursor += predefinedLength
        } else {
            return results
        }

        if let nextTrackID = try readUInt32(at: cursor, end: end) {
            results.append(PayloadAnnotation(
                label: "next_track_ID",
                value: String(nextTrackID),
                byteRange: cursor..<(cursor + 4),
                summary: "Next available track identifier"
            ))
        }

        return results
    }

    func safeRead(at offset: Int64, count: Int, end: Int64) throws -> Data? {
        guard count > 0 else { return Data() }
        guard offset >= 0, offset + Int64(count) <= end else { return nil }
        do {
            let data = try reader.read(at: offset, count: count)
            guard data.count == count else { return nil }
            return data
        } catch {
            return nil
        }
    }

    func readUInt32(at offset: Int64, end: Int64) throws -> UInt32? {
        guard offset + 4 <= end else { return nil }
        return try reader.readUInt32(at: offset)
    }

    func readUInt64(at offset: Int64, end: Int64) throws -> UInt64? {
        guard offset + 8 <= end else { return nil }
        return try reader.readUInt64(at: offset)
    }

    func formatFixedPoint(_ value: UInt32, integerBits: Int) -> String {
        let fractionalBits = 32 - integerBits
        let integerMask: UInt32 = (1 << integerBits) - 1
        let integerPart = (value >> fractionalBits) & integerMask
        let fractionalMask: UInt32 = (1 << fractionalBits) - 1
        let fractionalPart = value & fractionalMask
        let fraction = Double(fractionalPart) / Double(1 << fractionalBits)
        return String(format: "%.2f", Double(integerPart) + fraction)
    }
}
