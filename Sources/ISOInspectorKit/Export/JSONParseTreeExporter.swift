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

    init(detail: ParsedBoxPayload.Detail) {
        switch detail {
        case let .fileType(box):
            self.fileType = FileTypeDetail(box: box)
            self.movieHeader = nil
        case let .movieHeader(box):
            self.fileType = nil
            self.movieHeader = MovieHeaderDetail(box: box)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case fileType = "file_type"
        case movieHeader = "movie_header"
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

    init(matrix: ParsedBoxPayload.MovieHeaderBox.TransformationMatrix) {
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
