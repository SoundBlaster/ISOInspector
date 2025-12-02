import Foundation

public enum BoxHeaderDecodingError: Swift.Error {
    case offsetOutsideParent(offset: Int64, parentRange: Range<Int64>)
    case offsetBeyondReader(length: Int64, offset: Int64)
    case truncatedField(expected: Int, actual: Int)
    case invalidFourCharacterCode(Data)
    case zeroSizeWithoutParent
    case sizeOutOfRange(UInt64)
    case invalidSize(totalSize: Int64, headerSize: Int64)
    case exceedsParent(expectedEnd: Int64, parentEnd: Int64)
    case exceedsReader(expectedEnd: Int64, readerLength: Int64)
    case readerError(underlying: Swift.Error)
}

public enum BoxHeaderDecoder {
    public static func readHeader(
        from reader: RandomAccessReader, at offset: Int64,
        inParentRange parentRange: Range<Int64>? = nil
    ) -> Result<BoxHeader, BoxHeaderDecodingError> {
        do {
            return .success(try decodeHeader(from: reader, at: offset, inParentRange: parentRange))
        } catch let error as BoxHeaderDecodingError { return .failure(error) } catch {
            return .failure(.readerError(underlying: error))
        }
    }

    @available(*, deprecated, message: "Use result-based readHeader(_:at:inParentRange:) API")
    public static func readHeaderStrict(
        from reader: RandomAccessReader, at offset: Int64,
        inParentRange parentRange: Range<Int64>? = nil
    ) throws -> BoxHeader {
        try readHeader(from: reader, at: offset, inParentRange: parentRange).get()
    }

    private static func decodeHeader(
        from reader: RandomAccessReader, at offset: Int64,
        inParentRange parentRange: Range<Int64>? = nil
    ) throws -> BoxHeader {
        let parent = parentRange ?? (Int64(0)..<reader.length)
        guard parent.contains(offset) else {
            throw BoxHeaderDecodingError.offsetOutsideParent(offset: offset, parentRange: parent)
        }
        guard offset < reader.length else {
            throw BoxHeaderDecodingError.offsetBeyondReader(length: reader.length, offset: offset)
        }

        let sizeField: UInt32
        do { sizeField = try reader.readUInt32(at: offset) } catch let error
            as RandomAccessReaderValueDecodingError
        {
            switch error {
            case .truncatedRead(let expected, let actual):
                throw BoxHeaderDecodingError.truncatedField(expected: expected, actual: actual)
            case .invalidFourCharacterCode(let data):
                throw BoxHeaderDecodingError.invalidFourCharacterCode(data)
            }
        } catch { throw BoxHeaderDecodingError.readerError(underlying: error) }

        let type: FourCharCode
        do { type = try reader.readFourCC(at: offset + 4) } catch let error
            as RandomAccessReaderValueDecodingError
        {
            switch error {
            case .truncatedRead(let expected, let actual):
                throw BoxHeaderDecodingError.truncatedField(expected: expected, actual: actual)
            case .invalidFourCharacterCode(let data):
                throw BoxHeaderDecodingError.invalidFourCharacterCode(data)
            }
        } catch { throw BoxHeaderDecodingError.readerError(underlying: error) }

        var headerSize: Int64 = 8
        var cursor = offset + headerSize
        var totalSize: Int64

        if sizeField == 1 {
            let largeSize: UInt64
            do { largeSize = try reader.readUInt64(at: cursor) } catch let error
                as RandomAccessReaderValueDecodingError
            {
                switch error {
                case .truncatedRead(let expected, let actual):
                    throw BoxHeaderDecodingError.truncatedField(expected: expected, actual: actual)
                case .invalidFourCharacterCode(let data):
                    throw BoxHeaderDecodingError.invalidFourCharacterCode(data)
                }
            } catch { throw BoxHeaderDecodingError.readerError(underlying: error) }
            guard largeSize <= UInt64(Int64.max) else {
                throw BoxHeaderDecodingError.sizeOutOfRange(largeSize)
            }
            headerSize += 8
            cursor += 8
            totalSize = Int64(largeSize)
        } else {
            totalSize = Int64(sizeField)
        }

        var uuid: UUID?
        if type.rawValue == "uuid" {
            let uuidBytes: Data
            do { uuidBytes = try reader.read(at: cursor, count: 16) } catch {
                throw BoxHeaderDecodingError.readerError(underlying: error)
            }
            guard uuidBytes.count == 16 else {
                throw BoxHeaderDecodingError.truncatedField(expected: 16, actual: uuidBytes.count)
            }
            headerSize += 16
            cursor += 16
            uuid = uuidFrom(bytes: uuidBytes)
        }

        if sizeField == 0 {
            guard let parentRange = parentRange else {
                throw BoxHeaderDecodingError.zeroSizeWithoutParent
            }
            totalSize = parentRange.upperBound - offset
        }

        guard totalSize >= headerSize else {
            throw BoxHeaderDecodingError.invalidSize(totalSize: totalSize, headerSize: headerSize)
        }

        let endOffset = offset + totalSize
        guard endOffset <= parent.upperBound else {
            throw BoxHeaderDecodingError.exceedsParent(
                expectedEnd: endOffset, parentEnd: parent.upperBound)
        }
        guard endOffset <= reader.length else {
            throw BoxHeaderDecodingError.exceedsReader(
                expectedEnd: endOffset, readerLength: reader.length)
        }

        let payloadRange = cursor..<endOffset
        return BoxHeader(
            type: type, totalSize: totalSize, headerSize: headerSize, payloadRange: payloadRange,
            range: offset..<endOffset, uuid: uuid)
    }

    private static func uuidFrom(bytes: Data) -> UUID {
        let array = Array(bytes)
        return UUID(
            uuid: (
                array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7],
                array[8], array[9], array[10], array[11], array[12], array[13], array[14], array[15]
            ))
    }
}
