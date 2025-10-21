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
    let mediaData: MediaDataDetail?
    let padding: PaddingDetail?
    let movieHeader: MovieHeaderDetail?
    let trackHeader: TrackHeaderDetail?
    let trackExtends: TrackExtendsDetail?
    let movieFragmentHeader: MovieFragmentHeaderDetail?
    let soundMediaHeader: SoundMediaHeaderDetail?
    let videoMediaHeader: VideoMediaHeaderDetail?
    let editList: EditListDetail?
    let sampleToChunk: SampleToChunkDetail?
    let chunkOffset: ChunkOffsetDetail?
    let sampleSize: SampleSizeDetail?
    let compactSampleSize: CompactSampleSizeDetail?
    let syncSampleTable: SyncSampleTableDetail?
    let dataReference: DataReferenceDetail?
    let metadata: MetadataDetail?
    let metadataKeys: MetadataKeyTableDetail?
    let metadataItems: MetadataItemListDetail?

    init(detail: ParsedBoxPayload.Detail) {
        switch detail {
        case let .fileType(box):
            self.fileType = FileTypeDetail(box: box)
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .mediaData(box):
            self.fileType = nil
            self.mediaData = MediaDataDetail(box: box)
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .padding(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = PaddingDetail(box: box)
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .movieHeader(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = MovieHeaderDetail(box: box)
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .trackHeader(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = TrackHeaderDetail(box: box)
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .trackExtends(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = TrackExtendsDetail(box: box)
            self.movieFragmentHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .movieFragmentHeader(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = MovieFragmentHeaderDetail(box: box)
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .soundMediaHeader(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.soundMediaHeader = SoundMediaHeaderDetail(box: box)
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .videoMediaHeader(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.videoMediaHeader = VideoMediaHeaderDetail(box: box)
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .editList(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.editList = EditListDetail(box: box)
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .sampleToChunk(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.sampleToChunk = SampleToChunkDetail(box: box)
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .chunkOffset(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.trackExtends = nil
            self.sampleToChunk = nil
            self.movieFragmentHeader = nil
            self.chunkOffset = ChunkOffsetDetail(box: box)
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .sampleSize(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.sampleSize = SampleSizeDetail(box: box)
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .compactSampleSize(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.compactSampleSize = CompactSampleSizeDetail(box: box)
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .syncSampleTable(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.syncSampleTable = SyncSampleTableDetail(box: box)
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .dataReference(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.dataReference = DataReferenceDetail(box: box)
            self.metadata = nil
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .metadata(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.metadata = MetadataDetail(box: box)
            self.metadataKeys = nil
            self.metadataItems = nil
        case let .metadataKeyTable(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.metadataKeys = MetadataKeyTableDetail(box: box)
            self.metadataItems = nil
        case let .metadataItemList(box):
            self.fileType = nil
            self.mediaData = nil
            self.padding = nil
            self.movieHeader = nil
            self.trackHeader = nil
            self.soundMediaHeader = nil
            self.videoMediaHeader = nil
            self.editList = nil
            self.sampleToChunk = nil
            self.chunkOffset = nil
            self.sampleSize = nil
            self.compactSampleSize = nil
            self.syncSampleTable = nil
            self.dataReference = nil
            self.metadata = nil
            self.metadataKeys = nil
            self.trackExtends = nil
            self.movieFragmentHeader = nil
            self.metadataItems = MetadataItemListDetail(box: box)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case fileType = "file_type"
        case mediaData = "media_data"
        case padding = "padding"
        case movieHeader = "movie_header"
        case trackHeader = "track_header"
        case trackExtends = "track_extends"
        case movieFragmentHeader = "movie_fragment_header"
        case soundMediaHeader = "sound_media_header"
        case videoMediaHeader = "video_media_header"
        case editList = "edit_list"
        case sampleToChunk = "sample_to_chunk"
        case chunkOffset = "chunk_offset"
        case sampleSize = "sample_size"
        case compactSampleSize = "compact_sample_size"
        case syncSampleTable = "sync_sample_table"
        case dataReference = "data_reference"
        case metadata = "metadata"
        case metadataKeys = "metadata_keys"
        case metadataItems = "metadata_items"
    }
}

private struct MediaDataDetail: Encodable {
    let headerStartOffset: Int64
    let headerEndOffset: Int64
    let payloadStartOffset: Int64
    let payloadEndOffset: Int64
    let payloadLength: Int64
    let totalSize: Int64

    init(box: ParsedBoxPayload.MediaDataBox) {
        self.headerStartOffset = box.headerStartOffset
        self.headerEndOffset = box.headerEndOffset
        self.payloadStartOffset = box.payloadStartOffset
        self.payloadEndOffset = box.payloadEndOffset
        self.payloadLength = box.payloadLength
        self.totalSize = box.totalSize
    }
}

private struct PaddingDetail: Encodable {
    let type: String
    let headerStartOffset: Int64
    let headerEndOffset: Int64
    let payloadStartOffset: Int64
    let payloadEndOffset: Int64
    let payloadLength: Int64
    let totalSize: Int64

    init(box: ParsedBoxPayload.PaddingBox) {
        self.type = box.type.rawValue
        self.headerStartOffset = box.headerStartOffset
        self.headerEndOffset = box.headerEndOffset
        self.payloadStartOffset = box.payloadStartOffset
        self.payloadEndOffset = box.payloadEndOffset
        self.payloadLength = box.payloadLength
        self.totalSize = box.totalSize
    }
}

private struct MetadataDetail: Encodable {
    let version: UInt8
    let flags: UInt32
    let reserved: UInt32

    init(box: ParsedBoxPayload.MetadataBox) {
        self.version = box.version
        self.flags = box.flags
        self.reserved = box.reserved
    }
}

private struct MetadataKeyTableDetail: Encodable {
    struct Entry: Encodable {
        let index: UInt32
        let namespace: String
        let name: String
    }

    let version: UInt8
    let flags: UInt32
    let entryCount: Int
    let entries: [Entry]

    init(box: ParsedBoxPayload.MetadataKeyTableBox) {
        self.version = box.version
        self.flags = box.flags
        self.entries = box.entries.map { Entry(index: $0.index, namespace: $0.namespace, name: $0.name) }
        self.entryCount = entries.count
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case entryCount = "entry_count"
        case entries
    }
}

private struct MetadataItemListDetail: Encodable {
    struct Entry: Encodable {
        struct Identifier: Encodable {
            let kind: String
            let display: String
            let rawValue: UInt32
            let rawValueHex: String
            let keyIndex: UInt32?

            init(identifier: ParsedBoxPayload.MetadataItemListBox.Entry.Identifier) {
                switch identifier {
                case let .fourCC(raw, display):
                    self.kind = "fourcc"
                    self.rawValue = raw
                    self.rawValueHex = String(format: "0x%08X", raw)
                    self.keyIndex = nil
                    if display.isEmpty {
                        self.display = self.rawValueHex
                    } else {
                        self.display = display
                    }
                case let .keyIndex(index):
                    self.kind = "key_index"
                    self.rawValue = index
                    self.rawValueHex = String(format: "0x%08X", index)
                    self.keyIndex = index
                    self.display = "key[\(index)]"
                case let .raw(value):
                    self.kind = "raw"
                    self.rawValue = value
                    self.rawValueHex = String(format: "0x%08X", value)
                    self.keyIndex = nil
                    self.display = self.rawValueHex
                }
            }

            private enum CodingKeys: String, CodingKey {
                case kind
                case display
                case rawValue = "raw_value"
                case rawValueHex = "raw_value_hex"
                case keyIndex = "key_index"
            }
        }

        struct Value: Encodable {
            let kind: String
            let stringValue: String?
            let integerValue: Int64?
            let unsignedValue: UInt64?
            let booleanValue: Bool?
            let float32Value: Double?
            let float64Value: Double?
            let bytesBase64: String?
            let rawType: UInt32
            let rawTypeHex: String
            let dataFormat: String?
            let locale: UInt32?
            let fixedPointValue: Double?
            let fixedPointRaw: Int32?
            let fixedPointFormat: String?

            init(value: ParsedBoxPayload.MetadataItemListBox.Entry.Value) {
                self.rawType = value.rawType
                self.rawTypeHex = String(format: "0x%06X", value.rawType)
                self.locale = value.locale == 0 ? nil : value.locale

                var stringValue: String?
                var integerValue: Int64?
                var unsignedValue: UInt64?
                var booleanValue: Bool?
                var float32Value: Double?
                var float64Value: Double?
                var bytesBase64: String?
                var dataFormat: String?
                var fixedPointValue: Double?
                var fixedPointRaw: Int32?
                var fixedPointFormat: String?

                switch value.kind {
                case let .utf8(string):
                    self.kind = "utf8"
                    stringValue = string
                case let .utf16(string):
                    self.kind = "utf16"
                    stringValue = string
                case let .integer(number):
                    self.kind = "integer"
                    integerValue = number
                case let .unsignedInteger(number):
                    self.kind = "unsigned_integer"
                    unsignedValue = number
                case let .boolean(flag):
                    self.kind = "boolean"
                    booleanValue = flag
                case let .float32(number):
                    self.kind = "float32"
                    float32Value = Double(number)
                case let .float64(number):
                    self.kind = "float64"
                    float64Value = number
                case let .data(format, data):
                    self.kind = "data"
                    dataFormat = format.rawValue
                    bytesBase64 = data.isEmpty ? nil : Data(data).base64EncodedString()
                case let .bytes(data):
                    self.kind = "bytes"
                    bytesBase64 = data.isEmpty ? nil : Data(data).base64EncodedString()
                case let .signedFixedPoint(point):
                    self.kind = "signed_fixed_point"
                    fixedPointValue = point.value
                    fixedPointRaw = point.rawValue
                    fixedPointFormat = point.format.rawValue
                }

                self.stringValue = stringValue
                self.integerValue = integerValue
                self.unsignedValue = unsignedValue
                self.booleanValue = booleanValue
                self.float32Value = float32Value
                self.float64Value = float64Value
                self.bytesBase64 = bytesBase64
                self.dataFormat = dataFormat
                self.fixedPointValue = fixedPointValue
                self.fixedPointRaw = fixedPointRaw
                self.fixedPointFormat = fixedPointFormat
            }

            private enum CodingKeys: String, CodingKey {
                case kind
                case stringValue = "string_value"
                case integerValue = "integer_value"
                case unsignedValue = "unsigned_value"
                case booleanValue = "boolean_value"
                case float32Value = "float32_value"
                case float64Value = "float64_value"
                case bytesBase64 = "bytes_base64"
                case rawType = "raw_type"
                case rawTypeHex = "raw_type_hex"
                case dataFormat = "data_format"
                case locale
                case fixedPointValue = "fixed_point_value"
                case fixedPointRaw = "fixed_point_raw"
                case fixedPointFormat = "fixed_point_format"
            }
        }

        let index: Int
        let identifier: Identifier
        let namespace: String?
        let name: String?
        let values: [Value]

        init(entry: ParsedBoxPayload.MetadataItemListBox.Entry, index: Int) {
            self.index = index
            self.identifier = Identifier(identifier: entry.identifier)
            self.namespace = entry.namespace
            self.name = entry.name
            self.values = entry.values.map(Value.init)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case identifier
            case namespace
            case name
            case values
        }
    }

    let handlerType: String?
    let entryCount: Int
    let entries: [Entry]

    init(box: ParsedBoxPayload.MetadataItemListBox) {
        self.handlerType = box.handlerType?.rawValue
        self.entries = box.entries.enumerated().map { Entry(entry: $0.element, index: $0.offset + 1) }
        self.entryCount = entries.count
    }

    private enum CodingKeys: String, CodingKey {
        case handlerType = "handler_type"
        case entryCount = "entry_count"
        case entries
    }
}

private struct DataReferenceDetail: Encodable {
    struct Entry: Encodable {
        let index: Int
        let type: String
        let version: Int
        let flags: UInt32
        let selfContained: Bool
        let url: String?
        let urn: URN?
        let payloadLength: Int?
        let payloadBase64: String?

        init(entry: ParsedBoxPayload.DataReferenceBox.Entry) {
            self.index = Int(entry.index)
            self.type = entry.type.rawValue
            self.version = Int(entry.version)
            self.flags = entry.flags
            self.selfContained = (entry.flags & 0x000001) != 0

            let payloadLengthValue = entry.payloadRange.map { Int($0.upperBound - $0.lowerBound) } ?? 0

            switch entry.location {
            case .selfContained:
                self.url = nil
                self.urn = nil
                self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                self.payloadBase64 = nil
            case let .url(string):
                self.url = string
                self.urn = nil
                self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                self.payloadBase64 = nil
            case let .urn(name, location):
                self.url = nil
                self.urn = URN(name: name, location: location)
                self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                self.payloadBase64 = nil
            case let .data(data):
                self.url = nil
                self.urn = nil
                self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                self.payloadBase64 = data.isEmpty ? nil : Data(data).base64EncodedString()
            case .empty:
                self.url = nil
                self.urn = nil
                self.payloadLength = nil
                self.payloadBase64 = nil
            }
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case type
            case version
            case flags
            case selfContained = "self_contained"
            case url
            case urn
            case payloadLength = "payload_length"
            case payloadBase64 = "payload_base64"
        }
    }

    struct URN: Encodable {
        let name: String?
        let location: String?
    }

    let version: Int
    let flags: UInt32
    let entryCount: Int
    let entries: [Entry]

    init(box: ParsedBoxPayload.DataReferenceBox) {
        self.version = Int(box.version)
        self.flags = box.flags
        self.entryCount = Int(box.entryCount)
        self.entries = box.entries.map { Entry(entry: $0) }
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

private struct SoundMediaHeaderDetail: Encodable {
    let version: UInt8
    let flags: UInt32
    let balance: Double
    let balanceRaw: Int16

    init(box: ParsedBoxPayload.SoundMediaHeaderBox) {
        self.version = box.version
        self.flags = box.flags
        self.balance = box.balance
        self.balanceRaw = box.balanceRaw
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case balance
        case balanceRaw = "balance_raw"
    }
}

private struct VideoMediaHeaderDetail: Encodable {
    struct Opcolor: Encodable {
        struct Component: Encodable {
            let raw: UInt16
            let normalized: Double
        }

        let red: Component
        let green: Component
        let blue: Component
    }

    let version: UInt8
    let flags: UInt32
    let graphicsMode: UInt16
    let graphicsModeDescription: String?
    let opcolor: Opcolor

    init(box: ParsedBoxPayload.VideoMediaHeaderBox) {
        self.version = box.version
        self.flags = box.flags
        self.graphicsMode = box.graphicsMode
        self.graphicsModeDescription = box.graphicsModeDescription
        self.opcolor = Opcolor(
            red: .init(raw: box.opcolor.red.raw, normalized: box.opcolor.red.normalized),
            green: .init(raw: box.opcolor.green.raw, normalized: box.opcolor.green.normalized),
            blue: .init(raw: box.opcolor.blue.raw, normalized: box.opcolor.blue.normalized)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case graphicsMode = "graphics_mode"
        case graphicsModeDescription = "graphics_mode_description"
        case opcolor
    }
}

private struct EditListDetail: Encodable {
    struct Entry: Encodable {
        let index: UInt32
        let segmentDuration: UInt64
        let mediaTime: Int64
        let mediaRateInteger: Int16
        let mediaRateFraction: UInt16
        let mediaRate: Double
        let segmentDurationSeconds: Double?
        let mediaTimeSeconds: Double?
        let presentationStart: UInt64
        let presentationEnd: UInt64
        let presentationStartSeconds: Double?
        let presentationEndSeconds: Double?
        let isEmptyEdit: Bool

        init(entry: ParsedBoxPayload.EditListBox.Entry) {
            self.index = entry.index
            self.segmentDuration = entry.segmentDuration
            self.mediaTime = entry.mediaTime
            self.mediaRateInteger = entry.mediaRateInteger
            self.mediaRateFraction = entry.mediaRateFraction
            self.mediaRate = entry.mediaRate
            self.segmentDurationSeconds = entry.segmentDurationSeconds
            self.mediaTimeSeconds = entry.mediaTimeSeconds
            self.presentationStart = entry.presentationStart
            self.presentationEnd = entry.presentationEnd
            self.presentationStartSeconds = entry.presentationStartSeconds
            self.presentationEndSeconds = entry.presentationEndSeconds
            self.isEmptyEdit = entry.isEmptyEdit
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case segmentDuration = "segment_duration"
            case mediaTime = "media_time"
            case mediaRateInteger = "media_rate_integer"
            case mediaRateFraction = "media_rate_fraction"
            case mediaRate = "media_rate"
            case segmentDurationSeconds = "segment_duration_seconds"
            case mediaTimeSeconds = "media_time_seconds"
            case presentationStart = "presentation_start"
            case presentationEnd = "presentation_end"
            case presentationStartSeconds = "presentation_start_seconds"
            case presentationEndSeconds = "presentation_end_seconds"
            case isEmptyEdit = "is_empty_edit"
        }
    }

    let version: UInt8
    let flags: UInt32
    let entryCount: UInt32
    let movieTimescale: UInt32?
    let mediaTimescale: UInt32?
    let entries: [Entry]

    init(box: ParsedBoxPayload.EditListBox) {
        self.version = box.version
        self.flags = box.flags
        self.entryCount = box.entryCount
        self.movieTimescale = box.movieTimescale
        self.mediaTimescale = box.mediaTimescale
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case entryCount = "entry_count"
        case movieTimescale = "movie_timescale"
        case mediaTimescale = "media_timescale"
        case entries
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

private struct ChunkOffsetDetail: Encodable {
    enum Width: String, Encodable {
        case bits32 = "32"
        case bits64 = "64"
    }

    struct Entry: Encodable {
        let index: UInt32
        let offset: UInt64
        let byteRange: ByteRange

        init(entry: ParsedBoxPayload.ChunkOffsetBox.Entry) {
            self.index = entry.index
            self.offset = entry.offset
            self.byteRange = ByteRange(range: entry.byteRange)
        }
    }

    let version: UInt8
    let flags: UInt32
    let entryCount: UInt32
    let width: Width
    let entries: [Entry]

    init(box: ParsedBoxPayload.ChunkOffsetBox) {
        self.version = box.version
        self.flags = box.flags
        self.entryCount = box.entryCount
        switch box.width {
        case .bits32:
            self.width = .bits32
        case .bits64:
            self.width = .bits64
        }
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case entryCount = "entry_count"
        case width
        case entries
    }
}

private struct SyncSampleTableDetail: Encodable {
    struct Entry: Encodable {
        let index: UInt32
        let sampleNumber: UInt32
        let byteRange: ByteRange

        init(entry: ParsedBoxPayload.SyncSampleTableBox.Entry) {
            self.index = entry.index
            self.sampleNumber = entry.sampleNumber
            self.byteRange = ByteRange(range: entry.byteRange)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case sampleNumber = "sample_number"
            case byteRange = "byte_range"
        }
    }

    let version: UInt8
    let flags: UInt32
    let entryCount: UInt32
    let entries: [Entry]

    init(box: ParsedBoxPayload.SyncSampleTableBox) {
        self.version = box.version
        self.flags = box.flags
        self.entryCount = box.entryCount
        self.entries = box.entries.map(Entry.init)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case entryCount = "entry_count"
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

private struct TrackExtendsDetail: Encodable {
    let version: UInt8
    let flags: UInt32
    let trackID: UInt32
    let defaultSampleDescriptionIndex: UInt32
    let defaultSampleDuration: UInt32
    let defaultSampleSize: UInt32
    let defaultSampleFlags: UInt32

    init(box: ParsedBoxPayload.TrackExtendsDefaultsBox) {
        self.version = box.version
        self.flags = box.flags
        self.trackID = box.trackID
        self.defaultSampleDescriptionIndex = box.defaultSampleDescriptionIndex
        self.defaultSampleDuration = box.defaultSampleDuration
        self.defaultSampleSize = box.defaultSampleSize
        self.defaultSampleFlags = box.defaultSampleFlags
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case trackID = "track_ID"
        case defaultSampleDescriptionIndex = "default_sample_description_index"
        case defaultSampleDuration = "default_sample_duration"
        case defaultSampleSize = "default_sample_size"
        case defaultSampleFlags = "default_sample_flags"
    }
}

private struct MovieFragmentHeaderDetail: Encodable {
    let version: UInt8
    let flags: UInt32
    let sequenceNumber: UInt32

    init(box: ParsedBoxPayload.MovieFragmentHeaderBox) {
        self.version = box.version
        self.flags = box.flags
        self.sequenceNumber = box.sequenceNumber
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case flags
        case sequenceNumber = "sequence_number"
    }
}
