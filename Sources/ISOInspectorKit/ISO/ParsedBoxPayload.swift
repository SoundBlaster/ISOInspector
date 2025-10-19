import Foundation

public struct ParsedBoxPayload: Equatable, Sendable {
    public enum Detail: Equatable, Sendable {
        case fileType(FileTypeBox)
        case movieHeader(MovieHeaderBox)
        case trackHeader(TrackHeaderBox)
        case sampleToChunk(SampleToChunkBox)
        case chunkOffset(ChunkOffsetBox)
        case sampleSize(SampleSizeBox)
        case compactSampleSize(CompactSampleSizeBox)
    }

    public struct FileTypeBox: Equatable, Sendable {
        public let majorBrand: FourCharCode
        public let minorVersion: UInt32
        public let compatibleBrands: [FourCharCode]

        public init(majorBrand: FourCharCode, minorVersion: UInt32, compatibleBrands: [FourCharCode]) {
            self.majorBrand = majorBrand
            self.minorVersion = minorVersion
            self.compatibleBrands = compatibleBrands
        }
    }

    public struct TransformationMatrix: Equatable, Sendable {
        public let a: Double
        public let b: Double
        public let u: Double
        public let c: Double
        public let d: Double
        public let v: Double
        public let x: Double
        public let y: Double
        public let w: Double

        public static let identity = TransformationMatrix(
            a: 1.0,
            b: 0.0,
            u: 0.0,
            c: 0.0,
            d: 1.0,
            v: 0.0,
            x: 0.0,
            y: 0.0,
            w: 1.0
        )
    }

    public struct MovieHeaderBox: Equatable, Sendable {

        public let version: UInt8
        public let creationTime: UInt64
        public let modificationTime: UInt64
        public let timescale: UInt32
        public let duration: UInt64
        public let durationIs64Bit: Bool
        public let rate: Double
        public let volume: Double
        public let matrix: TransformationMatrix
        public let nextTrackID: UInt32

        public init(
            version: UInt8,
            creationTime: UInt64,
            modificationTime: UInt64,
            timescale: UInt32,
            duration: UInt64,
            durationIs64Bit: Bool,
            rate: Double,
            volume: Double,
            matrix: TransformationMatrix,
            nextTrackID: UInt32
        ) {
            self.version = version
            self.creationTime = creationTime
            self.modificationTime = modificationTime
            self.timescale = timescale
            self.duration = duration
            self.durationIs64Bit = durationIs64Bit
            self.rate = rate
            self.volume = volume
            self.matrix = matrix
            self.nextTrackID = nextTrackID
        }
    }

    public struct TrackHeaderBox: Equatable, Sendable {
        public let version: UInt8
        public let flags: UInt32
        public let creationTime: UInt64
        public let modificationTime: UInt64
        public let trackID: UInt32
        public let duration: UInt64
        public let durationIs64Bit: Bool
        public let layer: Int16
        public let alternateGroup: Int16
        public let volume: Double
        public let matrix: TransformationMatrix
        public let width: Double
        public let height: Double
        public let isEnabled: Bool
        public let isInMovie: Bool
        public let isInPreview: Bool

        public init(
            version: UInt8,
            flags: UInt32,
            creationTime: UInt64,
            modificationTime: UInt64,
            trackID: UInt32,
            duration: UInt64,
            durationIs64Bit: Bool,
            layer: Int16,
            alternateGroup: Int16,
            volume: Double,
            matrix: TransformationMatrix,
            width: Double,
            height: Double,
            isEnabled: Bool,
            isInMovie: Bool,
            isInPreview: Bool
        ) {
            self.version = version
            self.flags = flags
            self.creationTime = creationTime
            self.modificationTime = modificationTime
            self.trackID = trackID
            self.duration = duration
            self.durationIs64Bit = durationIs64Bit
            self.layer = layer
            self.alternateGroup = alternateGroup
            self.volume = volume
            self.matrix = matrix
            self.width = width
            self.height = height
            self.isEnabled = isEnabled
            self.isInMovie = isInMovie
            self.isInPreview = isInPreview
        }

        public var isZeroSized: Bool { width == 0.0 || height == 0.0 }

        public var isZeroDuration: Bool { duration == 0 }
    }

    public struct SampleToChunkBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let firstChunk: UInt32
            public let samplesPerChunk: UInt32
            public let sampleDescriptionIndex: UInt32
            public let byteRange: Range<Int64>

            public init(
                firstChunk: UInt32,
                samplesPerChunk: UInt32,
                sampleDescriptionIndex: UInt32,
                byteRange: Range<Int64>
            ) {
                self.firstChunk = firstChunk
                self.samplesPerChunk = samplesPerChunk
                self.sampleDescriptionIndex = sampleDescriptionIndex
                self.byteRange = byteRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let entries: [Entry]

        public init(version: UInt8, flags: UInt32, entries: [Entry]) {
            self.version = version
            self.flags = flags
            self.entries = entries
        }
    }

    public struct ChunkOffsetBox: Equatable, Sendable {
        public enum Width: Equatable, Sendable {
            case bits32
            case bits64
        }

        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let offset: UInt64
            public let byteRange: Range<Int64>

            public init(index: UInt32, offset: UInt64, byteRange: Range<Int64>) {
                self.index = index
                self.offset = offset
                self.byteRange = byteRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let entryCount: UInt32
        public let width: Width
        public let entries: [Entry]

        public init(
            version: UInt8,
            flags: UInt32,
            entryCount: UInt32,
            width: Width,
            entries: [Entry]
        ) {
            self.version = version
            self.flags = flags
            self.entryCount = entryCount
            self.width = width
            self.entries = entries
        }
    }

    public struct SampleSizeBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let size: UInt32
            public let byteRange: Range<Int64>

            public init(index: UInt32, size: UInt32, byteRange: Range<Int64>) {
                self.index = index
                self.size = size
                self.byteRange = byteRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let defaultSampleSize: UInt32
        public let sampleCount: UInt32
        public let entries: [Entry]

        public init(
            version: UInt8,
            flags: UInt32,
            defaultSampleSize: UInt32,
            sampleCount: UInt32,
            entries: [Entry]
        ) {
            self.version = version
            self.flags = flags
            self.defaultSampleSize = defaultSampleSize
            self.sampleCount = sampleCount
            self.entries = entries
        }

        public var isConstant: Bool { defaultSampleSize != 0 }
    }

    public struct CompactSampleSizeBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let size: UInt32
            public let byteRange: Range<Int64>

            public init(index: UInt32, size: UInt32, byteRange: Range<Int64>) {
                self.index = index
                self.size = size
                self.byteRange = byteRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let fieldSize: UInt8
        public let sampleCount: UInt32
        public let entries: [Entry]

        public init(
            version: UInt8,
            flags: UInt32,
            fieldSize: UInt8,
            sampleCount: UInt32,
            entries: [Entry]
        ) {
            self.version = version
            self.flags = flags
            self.fieldSize = fieldSize
            self.sampleCount = sampleCount
            self.entries = entries
        }
    }

    public struct Field: Equatable, Sendable {
        public let name: String
        public let value: String
        public let description: String?
        public let byteRange: Range<Int64>?

        public init(
            name: String,
            value: String,
            description: String? = nil,
            byteRange: Range<Int64>? = nil
        ) {
            self.name = name
            self.value = value
            self.description = description
            self.byteRange = byteRange
        }
    }

    public let fields: [Field]
    public let detail: Detail?

    public init(fields: [Field] = [], detail: Detail? = nil) {
        self.fields = fields
        self.detail = detail
    }

    public var isEmpty: Bool {
        fields.isEmpty
    }

    public var fileType: FileTypeBox? {
        guard case let .fileType(box) = detail else { return nil }
        return box
    }

    public var movieHeader: MovieHeaderBox? {
        guard case let .movieHeader(box) = detail else { return nil }
        return box
    }

    public var trackHeader: TrackHeaderBox? {
        guard case let .trackHeader(box) = detail else { return nil }
        return box
    }

    public var sampleToChunk: SampleToChunkBox? {
        guard case let .sampleToChunk(box) = detail else { return nil }
        return box
    }

    public var chunkOffset: ChunkOffsetBox? {
        guard case let .chunkOffset(box) = detail else { return nil }
        return box
    }

    public var sampleSize: SampleSizeBox? {
        guard case let .sampleSize(box) = detail else { return nil }
        return box
    }

    public var compactSampleSize: CompactSampleSizeBox? {
        guard case let .compactSampleSize(box) = detail else { return nil }
        return box
    }
}
