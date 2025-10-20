import Foundation

public struct ParsedBoxPayload: Equatable, Sendable {
    public enum Detail: Equatable, Sendable {
        case fileType(FileTypeBox)
        case mediaData(MediaDataBox)
        case padding(PaddingBox)
        case movieHeader(MovieHeaderBox)
        case trackHeader(TrackHeaderBox)
        case soundMediaHeader(SoundMediaHeaderBox)
        case videoMediaHeader(VideoMediaHeaderBox)
        case editList(EditListBox)
        case sampleToChunk(SampleToChunkBox)
        case chunkOffset(ChunkOffsetBox)
        case sampleSize(SampleSizeBox)
        case compactSampleSize(CompactSampleSizeBox)
        case syncSampleTable(SyncSampleTableBox)
        case dataReference(DataReferenceBox)
        case metadata(MetadataBox)
        case metadataKeyTable(MetadataKeyTableBox)
        case metadataItemList(MetadataItemListBox)
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

    public struct MediaDataBox: Equatable, Sendable {
        public let headerStartOffset: Int64
        public let headerEndOffset: Int64
        public let totalSize: Int64
        public let payloadRange: Range<Int64>

        public init(
            headerStartOffset: Int64,
            headerEndOffset: Int64,
            totalSize: Int64,
            payloadRange: Range<Int64>
        ) {
            self.headerStartOffset = headerStartOffset
            self.headerEndOffset = headerEndOffset
            self.totalSize = totalSize
            self.payloadRange = payloadRange
        }

        public var payloadLength: Int64 { max(0, payloadRange.upperBound - payloadRange.lowerBound) }

        public var payloadStartOffset: Int64 { payloadRange.lowerBound }

        public var payloadEndOffset: Int64 { payloadRange.upperBound }
    }

    public struct PaddingBox: Equatable, Sendable {
        public let type: FourCharCode
        public let headerStartOffset: Int64
        public let headerEndOffset: Int64
        public let totalSize: Int64
        public let payloadRange: Range<Int64>

        public init(
            type: FourCharCode,
            headerStartOffset: Int64,
            headerEndOffset: Int64,
            totalSize: Int64,
            payloadRange: Range<Int64>
        ) {
            self.type = type
            self.headerStartOffset = headerStartOffset
            self.headerEndOffset = headerEndOffset
            self.totalSize = totalSize
            self.payloadRange = payloadRange
        }

        public var payloadLength: Int64 { max(0, payloadRange.upperBound - payloadRange.lowerBound) }

        public var payloadStartOffset: Int64 { payloadRange.lowerBound }

        public var payloadEndOffset: Int64 { payloadRange.upperBound }
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

    public struct SoundMediaHeaderBox: Equatable, Sendable {
        public let version: UInt8
        public let flags: UInt32
        public let balance: Double
        public let balanceRaw: Int16

        public init(version: UInt8, flags: UInt32, balance: Double, balanceRaw: Int16) {
            self.version = version
            self.flags = flags
            self.balance = balance
            self.balanceRaw = balanceRaw
        }
    }

    public struct VideoMediaHeaderBox: Equatable, Sendable {
        public struct OpcolorComponent: Equatable, Sendable {
            public let raw: UInt16
            public let normalized: Double

            public init(raw: UInt16, normalized: Double) {
                self.raw = raw
                self.normalized = normalized
            }
        }

        public struct Opcolor: Equatable, Sendable {
            public let red: OpcolorComponent
            public let green: OpcolorComponent
            public let blue: OpcolorComponent

            public init(red: OpcolorComponent, green: OpcolorComponent, blue: OpcolorComponent) {
                self.red = red
                self.green = green
                self.blue = blue
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let graphicsMode: UInt16
        public let graphicsModeDescription: String?
        public let opcolor: Opcolor

        public init(
            version: UInt8,
            flags: UInt32,
            graphicsMode: UInt16,
            graphicsModeDescription: String?,
            opcolor: Opcolor
        ) {
            self.version = version
            self.flags = flags
            self.graphicsMode = graphicsMode
            self.graphicsModeDescription = graphicsModeDescription
            self.opcolor = opcolor
        }
    }

    public struct EditListBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let segmentDuration: UInt64
            public let mediaTime: Int64
            public let mediaRateInteger: Int16
            public let mediaRateFraction: UInt16
            public let mediaRate: Double
            public let segmentDurationSeconds: Double?
            public let mediaTimeSeconds: Double?
            public let presentationStart: UInt64
            public let presentationEnd: UInt64
            public let presentationStartSeconds: Double?
            public let presentationEndSeconds: Double?
            public let isEmptyEdit: Bool

            public init(
                index: UInt32,
                segmentDuration: UInt64,
                mediaTime: Int64,
                mediaRateInteger: Int16,
                mediaRateFraction: UInt16,
                mediaRate: Double,
                segmentDurationSeconds: Double?,
                mediaTimeSeconds: Double?,
                presentationStart: UInt64,
                presentationEnd: UInt64,
                presentationStartSeconds: Double?,
                presentationEndSeconds: Double?,
                isEmptyEdit: Bool
            ) {
                self.index = index
                self.segmentDuration = segmentDuration
                self.mediaTime = mediaTime
                self.mediaRateInteger = mediaRateInteger
                self.mediaRateFraction = mediaRateFraction
                self.mediaRate = mediaRate
                self.segmentDurationSeconds = segmentDurationSeconds
                self.mediaTimeSeconds = mediaTimeSeconds
                self.presentationStart = presentationStart
                self.presentationEnd = presentationEnd
                self.presentationStartSeconds = presentationStartSeconds
                self.presentationEndSeconds = presentationEndSeconds
                self.isEmptyEdit = isEmptyEdit
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let entryCount: UInt32
        public let movieTimescale: UInt32?
        public let mediaTimescale: UInt32?
        public let entries: [Entry]

        public init(
            version: UInt8,
            flags: UInt32,
            entryCount: UInt32,
            movieTimescale: UInt32?,
            mediaTimescale: UInt32?,
            entries: [Entry]
        ) {
            self.version = version
            self.flags = flags
            self.entryCount = entryCount
            self.movieTimescale = movieTimescale
            self.mediaTimescale = mediaTimescale
            self.entries = entries
        }
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

    /// Parsed representation of the `stss` sync sample table.
    ///
    /// Downstream validation (e.g., VR-015) combines these sync sample numbers with
    /// chunk and sample size tables to confirm that random access entries align with
    /// chunk boundaries exposed by `stsc`, `stsz/stz2`, and `stco/co64`.
    public struct SyncSampleTableBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let sampleNumber: UInt32
            public let byteRange: Range<Int64>

            public init(index: UInt32, sampleNumber: UInt32, byteRange: Range<Int64>) {
                self.index = index
                self.sampleNumber = sampleNumber
                self.byteRange = byteRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let entryCount: UInt32
        public let entries: [Entry]

        public init(version: UInt8, flags: UInt32, entryCount: UInt32, entries: [Entry]) {
            self.version = version
            self.flags = flags
            self.entryCount = entryCount
            self.entries = entries
        }
    }

    public struct DataReferenceBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public enum Location: Equatable, Sendable {
                case selfContained
                case url(String)
                case urn(name: String?, location: String?)
                case data(Data)
                case empty
            }

            public let index: UInt32
            public let type: FourCharCode
            public let version: UInt8
            public let flags: UInt32
            public let location: Location
            public let byteRange: Range<Int64>
            public let payloadRange: Range<Int64>?

            public init(
                index: UInt32,
                type: FourCharCode,
                version: UInt8,
                flags: UInt32,
                location: Location,
                byteRange: Range<Int64>,
                payloadRange: Range<Int64>?
            ) {
                self.index = index
                self.type = type
                self.version = version
                self.flags = flags
                self.location = location
                self.byteRange = byteRange
                self.payloadRange = payloadRange
            }
        }

        public let version: UInt8
        public let flags: UInt32
        public let entryCount: UInt32
        public let entries: [Entry]

        public init(version: UInt8, flags: UInt32, entryCount: UInt32, entries: [Entry]) {
            self.version = version
            self.flags = flags
            self.entryCount = entryCount
            self.entries = entries
        }
    }

    public struct MetadataBox: Equatable, Sendable {
        public let version: UInt8
        public let flags: UInt32
        public let reserved: UInt32

        public init(version: UInt8, flags: UInt32, reserved: UInt32) {
            self.version = version
            self.flags = flags
            self.reserved = reserved
        }
    }

    public struct MetadataKeyTableBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public let index: UInt32
            public let namespace: String
            public let name: String

            public init(index: UInt32, namespace: String, name: String) {
                self.index = index
                self.namespace = namespace
                self.name = name
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

    public struct MetadataItemListBox: Equatable, Sendable {
        public struct Entry: Equatable, Sendable {
            public enum Identifier: Equatable, Sendable {
                case fourCC(raw: UInt32, display: String)
                case keyIndex(UInt32)
                case raw(UInt32)
            }

            public struct Value: Equatable, Sendable {
                public enum Kind: Equatable, Sendable {
                    case utf8(String)
                    case utf16(String)
                    case integer(Int64)
                    case unsignedInteger(UInt64)
                    case bytes(Data)
                }

                public let kind: Kind
                public let rawType: UInt32
                public let locale: UInt32

                public init(kind: Kind, rawType: UInt32, locale: UInt32) {
                    self.kind = kind
                    self.rawType = rawType
                    self.locale = locale
                }
            }

            public let identifier: Identifier
            public let namespace: String?
            public let name: String?
            public let values: [Value]

            public init(
                identifier: Identifier,
                namespace: String?,
                name: String?,
                values: [Value]
            ) {
                self.identifier = identifier
                self.namespace = namespace
                self.name = name
                self.values = values
            }
        }

        public let handlerType: HandlerType?
        public let entries: [Entry]

        public init(handlerType: HandlerType?, entries: [Entry]) {
            self.handlerType = handlerType
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

    public var mediaData: MediaDataBox? {
        guard case let .mediaData(box) = detail else { return nil }
        return box
    }

    public var padding: PaddingBox? {
        guard case let .padding(box) = detail else { return nil }
        return box
    }

    public var trackHeader: TrackHeaderBox? {
        guard case let .trackHeader(box) = detail else { return nil }
        return box
    }

    public var soundMediaHeader: SoundMediaHeaderBox? {
        guard case let .soundMediaHeader(box) = detail else { return nil }
        return box
    }

    public var videoMediaHeader: VideoMediaHeaderBox? {
        guard case let .videoMediaHeader(box) = detail else { return nil }
        return box
    }

    public var editList: EditListBox? {
        guard case let .editList(box) = detail else { return nil }
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

    public var syncSampleTable: SyncSampleTableBox? {
        guard case let .syncSampleTable(box) = detail else { return nil }
        return box
    }

    public var dataReference: DataReferenceBox? {
        guard case let .dataReference(box) = detail else { return nil }
        return box
    }

    public var metadataBox: MetadataBox? {
        guard case let .metadata(box) = detail else { return nil }
        return box
    }

    public var metadataKeyTable: MetadataKeyTableBox? {
        guard case let .metadataKeyTable(box) = detail else { return nil }
        return box
    }

    public var metadataItemList: MetadataItemListBox? {
        guard case let .metadataItemList(box) = detail else { return nil }
        return box
    }
}
