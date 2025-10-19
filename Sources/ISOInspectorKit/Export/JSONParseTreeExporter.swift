import Foundation

public struct JSONParseTreeExporter {
    private let encoder: JSONEncoder

    public init(encoder: JSONEncoder = JSONEncoder()) {
        let configured = encoder
        configured.outputFormatting.insert(.sortedKeys)
        self.encoder = configured
    }

    public func export(tree: ParseTree) throws -> Data {
        let payload = Payload(tree: tree)
        return try encoder.encode(payload)
    }
}

private struct Payload: Encodable {
    let nodes: [Node]
    let validationIssues: [Issue]

    init(tree: ParseTree) {
        self.nodes = tree.nodes.map(Node.init)
        self.validationIssues = tree.validationIssues.map(Issue.init)
    }
}

private struct Node: Encodable {
    let fourcc: String
    let uuid: UUID?
    let offsets: Offsets
    let sizes: Sizes
    let metadata: Metadata?
    let payload: [PayloadField]?
    let structured: StructuredPayload?
    let validationIssues: [Issue]
    let children: [Node]

    init(node: ParseTreeNode) {
        self.fourcc = node.header.type.rawValue
        self.uuid = node.header.uuid
        self.offsets = Offsets(header: node.header)
        self.sizes = Sizes(header: node.header)
        self.metadata = node.metadata.map(Metadata.init)
        if let payload = node.payload {
            let fields = payload.fields.map(PayloadField.init)
            self.payload = fields.isEmpty ? nil : fields
            self.structured = payload.detail.map(StructuredPayload.init)
        } else {
            self.payload = nil
            self.structured = nil
        }
        self.validationIssues = node.validationIssues.map(Issue.init)
        self.children = node.children.map(Node.init)
    }
}

private struct Offsets: Encodable {
    let start: Int
    let end: Int
    let payloadStart: Int
    let payloadEnd: Int

    init(header: BoxHeader) {
        self.start = Int(header.range.lowerBound)
        self.end = Int(header.range.upperBound)
        self.payloadStart = Int(header.payloadRange.lowerBound)
        self.payloadEnd = Int(header.payloadRange.upperBound)
    }
}

private struct Sizes: Encodable {
    let total: Int
    let header: Int
    let payload: Int

    init(header: BoxHeader) {
        self.total = Int(header.totalSize)
        self.header = Int(header.headerSize)
        self.payload = max(0, Int(header.payloadRange.upperBound - header.payloadRange.lowerBound))
    }
}

private struct Metadata: Encodable {
    let name: String
    let summary: String
    let category: String?
    let specification: String?
    let version: Int?
    let flags: UInt32?

    init(descriptor: BoxDescriptor) {
        self.name = descriptor.name
        self.summary = descriptor.summary
        self.category = descriptor.category
        self.specification = descriptor.specification
        self.version = descriptor.version
        self.flags = descriptor.flags
    }
}

private struct PayloadField: Encodable {
    let name: String
    let value: String
    let summary: String?
    let byteRange: ByteRange?

    init(field: ParsedBoxPayload.Field) {
        self.name = field.name
        self.value = field.value
        self.summary = field.description
        if let range = field.byteRange {
            self.byteRange = ByteRange(range: range)
        } else {
            self.byteRange = nil
        }
    }
}

private struct ByteRange: Encodable {
    let start: Int
    let end: Int

    init(range: Range<Int64>) {
        self.start = Int(range.lowerBound)
        self.end = Int(range.upperBound)
    }
}

private struct Issue: Encodable {
    let ruleID: String
    let message: String
    let severity: String

    init(issue: ValidationIssue) {
        self.ruleID = issue.ruleID
        self.message = issue.message
        self.severity = issue.severity.rawValue
    }
}

private struct StructuredPayload: Encodable {
    let fileType: FileTypeDetail?
    let movieHeader: MovieHeaderDetail?
    let trackHeader: TrackHeaderDetail?
    let sampleToChunk: SampleToChunkDetail?
    let sampleSize: SampleSizeDetail?
    let compactSampleSize: CompactSampleSizeDetail?

    init(detail: ParsedBoxPayload.Detail) {
        switch detail {
        case let .fileType(box):
            self.fileType = FileTypeDetail(box: box)
            self.movieHeader = nil
            self.trackHeader = nil
            self.sampleToChunk = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
        case let .movieHeader(box):
            self.fileType = nil
            self.movieHeader = MovieHeaderDetail(box: box)
            self.trackHeader = nil
            self.sampleToChunk = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
        case let .trackHeader(box):
            self.fileType = nil
            self.movieHeader = nil
            self.trackHeader = TrackHeaderDetail(box: box)
            self.sampleToChunk = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
        case let .sampleToChunk(box):
            self.fileType = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.sampleToChunk = SampleToChunkDetail(box: box)
            self.sampleSize = nil
            self.compactSampleSize = nil
        case let .sampleSize(box):
            self.fileType = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.sampleToChunk = nil
            self.sampleSize = SampleSizeDetail(box: box)
            self.compactSampleSize = nil
        case let .compactSampleSize(box):
            self.fileType = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.sampleToChunk = nil
            self.sampleSize = nil
            self.compactSampleSize = CompactSampleSizeDetail(box: box)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case fileType = "file_type"
        case movieHeader = "movie_header"
        case trackHeader = "track_header"
        case sampleToChunk = "sample_to_chunk"
        case sampleSize = "sample_size"
        case compactSampleSize = "compact_sample_size"
    }
}

private struct FileTypeDetail: Encodable {
    let majorBrand: String
    let minorVersion: UInt32
    let compatibleBrands: [String]

    init(box: ParsedBoxPayload.FileTypeBox) {
        self.majorBrand = box.majorBrand.rawValue
        self.minorVersion = box.minorVersion
        self.compatibleBrands = box.compatibleBrands.map(\.rawValue)
    }

    private enum CodingKeys: String, CodingKey {
        case majorBrand = "major_brand"
        case minorVersion = "minor_version"
        case compatibleBrands = "compatible_brands"
    }
}

private struct MovieHeaderDetail: Encodable {
    let version: UInt8
    let creationTime: UInt64
    let modificationTime: UInt64
    let timescale: UInt32
    let duration: UInt64
    let durationIs64Bit: Bool
    let rate: Double
    let volume: Double
    let matrix: MatrixDetail
    let nextTrackID: UInt32

    init(box: ParsedBoxPayload.MovieHeaderBox) {
        self.version = box.version
        self.creationTime = box.creationTime
        self.modificationTime = box.modificationTime
        self.timescale = box.timescale
        self.duration = box.duration
        self.durationIs64Bit = box.durationIs64Bit
        self.rate = box.rate
        self.volume = box.volume
        self.matrix = MatrixDetail(matrix: box.matrix)
        self.nextTrackID = box.nextTrackID
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case creationTime = "creation_time"
        case modificationTime = "modification_time"
        case timescale
        case duration
        case durationIs64Bit = "duration_is_64bit"
        case rate
        case volume
        case matrix
        case nextTrackID = "next_track_id"
    }
}

private struct SampleToChunkDetail: Encodable {
    struct Entry: Encodable {
        let firstChunk: UInt32
        let samplesPerChunk: UInt32
        let sampleDescriptionIndex: UInt32
        let byteRange: ByteRange

        init(entry: ParsedBoxPayload.SampleToChunkBox.Entry) {
            self.firstChunk = entry.firstChunk
            self.samplesPerChunk = entry.samplesPerChunk
            self.sampleDescriptionIndex = entry.sampleDescriptionIndex
            self.byteRange = ByteRange(range: entry.byteRange)
        }

        private enum CodingKeys: String, CodingKey {
            case firstChunk = "first_chunk"
            case samplesPerChunk = "samples_per_chunk"
            case sampleDescriptionIndex = "sample_description_index"
            case byteRange = "byte_range"
        }
    }

    let version: UInt8
    let flags: UInt32
    let entries: [Entry]

    init(box: ParsedBoxPayload.SampleToChunkBox) {
        self.version = box.version
        self.flags = box.flags
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case entries
    }
}

private struct SampleSizeDetail: Encodable {
    struct Entry: Encodable {
        let index: UInt32
        let size: UInt32
        let byteRange: ByteRange

        init(entry: ParsedBoxPayload.SampleSizeBox.Entry) {
            self.index = entry.index
            self.size = entry.size
            self.byteRange = ByteRange(range: entry.byteRange)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case size
            case byteRange = "byte_range"
        }
    }

    let version: UInt8
    let flags: UInt32
    let defaultSampleSize: UInt32
    let sampleCount: UInt32
    let isConstant: Bool
    let entries: [Entry]

    init(box: ParsedBoxPayload.SampleSizeBox) {
        self.version = box.version
        self.flags = box.flags
        self.defaultSampleSize = box.defaultSampleSize
        self.sampleCount = box.sampleCount
        self.isConstant = box.isConstant
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case defaultSampleSize = "default_sample_size"
        case sampleCount = "sample_count"
        case isConstant = "is_constant"
        case entries
    }
}

private struct CompactSampleSizeDetail: Encodable {
    struct Entry: Encodable {
        let index: UInt32
        let size: UInt32
        let byteRange: ByteRange

        init(entry: ParsedBoxPayload.CompactSampleSizeBox.Entry) {
            self.index = entry.index
            self.size = entry.size
            self.byteRange = ByteRange(range: entry.byteRange)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case size
            case byteRange = "byte_range"
        }
    }

    let version: UInt8
    let flags: UInt32
    let fieldSize: UInt8
    let sampleCount: UInt32
    let entries: [Entry]

    init(box: ParsedBoxPayload.CompactSampleSizeBox) {
        self.version = box.version
        self.flags = box.flags
        self.fieldSize = box.fieldSize
        self.sampleCount = box.sampleCount
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case fieldSize = "field_size"
        case sampleCount = "sample_count"
        case entries
    }
}

private struct MatrixDetail: Encodable {
    let a: Double
    let b: Double
    let u: Double
    let c: Double
    let d: Double
    let v: Double
    let x: Double
    let y: Double
    let w: Double

    init(matrix: ParsedBoxPayload.TransformationMatrix) {
        self.a = matrix.a
        self.b = matrix.b
        self.u = matrix.u
        self.c = matrix.c
        self.d = matrix.d
        self.v = matrix.v
        self.x = matrix.x
        self.y = matrix.y
        self.w = matrix.w
    }
}

private struct TrackHeaderDetail: Encodable {
    let version: UInt8
    let flags: UInt32
    let creationTime: UInt64
    let modificationTime: UInt64
    let trackID: UInt32
    let duration: UInt64
    let durationIs64Bit: Bool
    let layer: Int16
    let alternateGroup: Int16
    let volume: Double
    let matrix: MatrixDetail
    let width: Double
    let height: Double
    let isEnabled: Bool
    let isInMovie: Bool
    let isInPreview: Bool
    let isZeroSized: Bool
    let isZeroDuration: Bool

    init(box: ParsedBoxPayload.TrackHeaderBox) {
        self.version = box.version
        self.flags = box.flags
        self.creationTime = box.creationTime
        self.modificationTime = box.modificationTime
        self.trackID = box.trackID
        self.duration = box.duration
        self.durationIs64Bit = box.durationIs64Bit
        self.layer = box.layer
        self.alternateGroup = box.alternateGroup
        self.volume = box.volume
        self.matrix = MatrixDetail(matrix: box.matrix)
        self.width = box.width
        self.height = box.height
        self.isEnabled = box.isEnabled
        self.isInMovie = box.isInMovie
        self.isInPreview = box.isInPreview
        self.isZeroSized = box.isZeroSized
        self.isZeroDuration = box.isZeroDuration
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case creationTime = "creation_time"
        case modificationTime = "modification_time"
        case trackID = "track_id"
        case duration
        case durationIs64Bit = "duration_is_64bit"
        case layer
        case alternateGroup = "alternate_group"
        case volume
        case matrix
        case width
        case height
        case isEnabled = "is_enabled"
        case isInMovie = "is_in_movie"
        case isInPreview = "is_in_preview"
        case isZeroSized = "is_zero_sized"
        case isZeroDuration = "is_zero_duration"
    }
}
