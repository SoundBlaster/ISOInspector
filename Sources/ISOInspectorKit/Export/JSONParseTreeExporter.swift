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
  let schema: SchemaDescriptor?
  let nodes: [Node]
  let validationIssues: [Issue]
  let validation: ValidationMetadataPayload?
  let format: FormatSummary?
  let issueMetrics: IssueMetricsSummary

  init(tree: ParseTree) {
    self.nodes = tree.nodes.map(Node.init)
    self.validationIssues = tree.validationIssues.map(Issue.init)
    if let metadata = tree.validationMetadata {
      self.validation = ValidationMetadataPayload(metadata: metadata)
    } else {
      self.validation = nil
    }
    self.format = FormatSummary(tree: tree)
    let metrics = IssueMetricsSummary(tree: tree)
    self.issueMetrics = metrics
    if metrics.totalCount > 0 {
      self.schema = .tolerantIssuesV2
    } else {
      self.schema = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case schema
    case nodes
    case validationIssues
    case validation
    case format
    case issueMetrics = "issue_metrics"
  }
}

private struct SchemaDescriptor: Encodable {
  let version: Int

  static let tolerantIssuesV2 = SchemaDescriptor(version: 2)
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
  let status: String
  let issues: [ParseIssuePayload]
  let children: [Node]
  let compatibilityName: String
  let compatibilityHeaderSize: Int
  let compatibilityTotalSize: Int

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
    self.status = node.status.rawValue
    self.issues = node.issues.map(ParseIssuePayload.init)
    self.children = node.children.map(Node.init)
    self.compatibilityName = node.header.type.rawValue
    self.compatibilityHeaderSize = Int(clamping: node.header.headerSize)
    self.compatibilityTotalSize = Int(clamping: node.header.totalSize)
  }

  private enum CodingKeys: String, CodingKey {
    case fourcc
    case uuid
    case offsets
    case sizes
    case metadata
    case payload
    case structured
    case validationIssues
    case status
    case issues
    case children
    case compatibilityName = "name"
    case compatibilityHeaderSize = "header_size"
    case compatibilityTotalSize = "size"
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

private struct RangeSummary: Encodable {
  let range: ByteRange
  let length: Int

  init(range: Range<Int64>, length: Int64?) {
    self.range = ByteRange(range: range)
    let resolved = length ?? (range.upperBound - range.lowerBound)
    if resolved <= 0 {
      self.length = 0
    } else if resolved >= Int64(Int.max) {
      self.length = Int.max
    } else {
      self.length = Int(resolved)
    }
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

private struct ParseIssuePayload: Encodable {
  let severity: String
  let code: String
  let message: String
  let byteRange: ByteRange?
  let affectedNodeIDs: [Int64]

  init(issue: ParseIssue) {
    self.severity = issue.severity.rawValue
    self.code = issue.code
    self.message = issue.message
    if let range = issue.byteRange {
      self.byteRange = ByteRange(range: range)
    } else {
      self.byteRange = nil
    }
    self.affectedNodeIDs = issue.affectedNodeIDs
  }
}

private struct ValidationMetadataPayload: Encodable {
  let activePresetID: String
  let disabledRules: [String]

  init(metadata: ValidationMetadata) {
    self.activePresetID = metadata.activePresetID
    self.disabledRules = metadata.disabledRuleIDs
  }
}

private struct IssueMetricsSummary: Encodable {
  let errorCount: Int
  let warningCount: Int
  let infoCount: Int
  let deepestAffectedDepth: Int

  var totalCount: Int {
    errorCount + warningCount + infoCount
  }

  init(tree: ParseTree) {
    var counter = IssueMetricsCounter()
    counter.accumulate(nodes: tree.nodes, depth: 0)
    self.errorCount = counter.errorCount
    self.warningCount = counter.warningCount
    self.infoCount = counter.infoCount
    self.deepestAffectedDepth = counter.deepestDepth
  }

  private enum CodingKeys: String, CodingKey {
    case errorCount = "error_count"
    case warningCount = "warning_count"
    case infoCount = "info_count"
    case deepestAffectedDepth = "deepest_affected_depth"
  }

  private struct IssueMetricsCounter {
    var errorCount: Int = 0
    var warningCount: Int = 0
    var infoCount: Int = 0
    var deepestDepth: Int = 0

    private var trackedIssues: [IssueIdentifier: Int] = [:]

    mutating func accumulate(nodes: [ParseTreeNode], depth: Int) {
      for node in nodes {
        if !node.issues.isEmpty {
          for issue in node.issues {
            let identifier = IssueIdentifier(issue: issue)
            let previousDepth = trackedIssues[identifier]
            if previousDepth == nil {
              switch issue.severity {
              case .error:
                errorCount += 1
              case .warning:
                warningCount += 1
              case .info:
                infoCount += 1
              }
            }
            let resolvedDepth = max(previousDepth ?? depth, depth)
            trackedIssues[identifier] = resolvedDepth
            deepestDepth = max(deepestDepth, resolvedDepth)
          }
        }
        accumulate(nodes: node.children, depth: depth + 1)
      }
    }

    private struct IssueIdentifier: Hashable {
      let severity: String
      let code: String
      let message: String
      let byteRangeLowerBound: Int64?
      let byteRangeUpperBound: Int64?
      let affectedNodeIDs: [Int64]

      init(issue: ParseIssue) {
        self.severity = issue.severity.rawValue
        self.code = issue.code
        self.message = issue.message
        self.byteRangeLowerBound = issue.byteRange?.lowerBound
        self.byteRangeUpperBound = issue.byteRange?.upperBound
        self.affectedNodeIDs = issue.affectedNodeIDs
      }
    }
  }
}

private struct FormatSummary: Encodable {
  let majorBrand: String?
  let minorVersion: Int?
  let compatibleBrands: [String]?
  let durationSeconds: Double?
  let byteSize: Int?
  let bitrate: Int?
  let trackCount: Int?

  init?(tree: ParseTree) {
    let scan = FormatSummary.scan(tree: tree)
    let majorBrand = scan.fileType?.majorBrand.rawValue
    let minorVersion = scan.fileType.map { Int($0.minorVersion) }
    let compatibleBrands = scan.fileType?.compatibleBrands.map(\.rawValue)
    let durationSeconds = FormatSummary.durationSeconds(from: scan.movieHeader)
    let byteSize = FormatSummary.byteSize(from: scan.maximumEndOffset)
    let bitrate = FormatSummary.bitrate(byteSize: byteSize, durationSeconds: durationSeconds)
    let trackCount = scan.trackCount > 0 ? scan.trackCount : nil

    guard majorBrand != nil || minorVersion != nil || !(compatibleBrands?.isEmpty ?? true)
      || durationSeconds != nil || byteSize != nil || bitrate != nil || trackCount != nil else {
      return nil
    }

    self.majorBrand = majorBrand
    self.minorVersion = minorVersion
    self.compatibleBrands = compatibleBrands
    self.durationSeconds = durationSeconds
    self.byteSize = byteSize
    self.bitrate = bitrate
    self.trackCount = trackCount
  }

  private static func scan(tree: ParseTree) -> ScanResult {
    var fileTypeBox: ParsedBoxPayload.FileTypeBox?
    var movieHeaderBox: ParsedBoxPayload.MovieHeaderBox?
    var maximumEndOffset: Int64 = 0
    var trackCounter = 0

    for node in flatten(nodes: tree.nodes) {
      if fileTypeBox == nil, let fileType = node.payload?.fileType {
        fileTypeBox = fileType
      }
      if movieHeaderBox == nil, let movieHeader = node.payload?.movieHeader {
        movieHeaderBox = movieHeader
      }
      if node.header.type.rawValue == "trak" {
        trackCounter += 1
      }
      maximumEndOffset = max(maximumEndOffset, node.header.endOffset)
    }

    return ScanResult(
      fileType: fileTypeBox,
      movieHeader: movieHeaderBox,
      maximumEndOffset: maximumEndOffset,
      trackCount: trackCounter
    )
  }

  private static func durationSeconds(from movieHeader: ParsedBoxPayload.MovieHeaderBox?) -> Double? {
    guard let header = movieHeader, header.timescale > 0 else { return nil }
    return Double(header.duration) / Double(header.timescale)
  }

  private static func byteSize(from maximumEndOffset: Int64) -> Int? {
    guard maximumEndOffset > 0 else { return nil }
    return Int(clamping: maximumEndOffset)
  }

  private static func bitrate(byteSize: Int?, durationSeconds: Double?) -> Int? {
    guard let bytes = byteSize, let duration = durationSeconds, duration > 0 else { return nil }
    return Int((Double(bytes) * 8.0 / duration).rounded())
  }

  private struct ScanResult {
    let fileType: ParsedBoxPayload.FileTypeBox?
    let movieHeader: ParsedBoxPayload.MovieHeaderBox?
    let maximumEndOffset: Int64
    let trackCount: Int
  }

  private static func flatten(nodes: [ParseTreeNode]) -> [ParseTreeNode] {
    var result: [ParseTreeNode] = []
    for node in nodes {
      result.append(node)
      result.append(contentsOf: flatten(nodes: node.children))
    }
    return result
  }

  private enum CodingKeys: String, CodingKey {
    case majorBrand = "major_brand"
    case minorVersion = "minor_version"
    case compatibleBrands = "compatible_brands"
    case durationSeconds = "duration_seconds"
    case byteSize = "byte_size"
    case bitrate
    case trackCount = "track_count"
  }
}

private struct StructuredPayload: Encodable {
  let fileType: FileTypeDetail?
  let mediaData: MediaDataDetail?
  let padding: PaddingDetail?
  let movieHeader: MovieHeaderDetail?
  let trackHeader: TrackHeaderDetail?
  let trackExtends: TrackExtendsDetail?
  let trackFragmentHeader: TrackFragmentHeaderDetail?
  let trackFragmentDecodeTime: TrackFragmentDecodeTimeDetail?
  let trackRun: TrackRunDetail?
  let trackFragment: TrackFragmentDetail?
  let movieFragmentHeader: MovieFragmentHeaderDetail?
  let movieFragmentRandomAccess: MovieFragmentRandomAccessDetail?
  let trackFragmentRandomAccess: TrackFragmentRandomAccessDetail?
  let movieFragmentRandomAccessOffset: MovieFragmentRandomAccessOffsetDetail?
  let sampleEncryption: SampleEncryptionDetail?
  let sampleAuxInfoOffsets: SampleAuxInfoOffsetsDetail?
  let sampleAuxInfoSizes: SampleAuxInfoSizesDetail?
  let soundMediaHeader: SoundMediaHeaderDetail?
  let videoMediaHeader: VideoMediaHeaderDetail?
  let editList: EditListDetail?
  let timeToSample: TimeToSampleDetail?
  let compositionOffset: CompositionOffsetDetail?
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
    self = StructuredPayload.build(from: detail)
  }
}

private extension StructuredPayload {
  static func build(from detail: ParsedBoxPayload.Detail) -> StructuredPayload {
    if let payload = buildFile(detail) { return payload }
    if let payload = buildTrackHeaders(detail) { return payload }
    if let payload = buildFragments(detail) { return payload }
    if let payload = buildSampleProtection(detail) { return payload }
    if let payload = buildTiming(detail) { return payload }
    if let payload = buildMetadata(detail) { return payload }
    if let payload = buildMedia(detail) { return payload }
    return StructuredPayload()
  }

  static func buildFile(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .fileType(let box):
      return StructuredPayload(fileType: FileTypeDetail(box: box))
    case .mediaData(let box):
      return StructuredPayload(mediaData: MediaDataDetail(box: box))
    case .padding(let box):
      return StructuredPayload(padding: PaddingDetail(box: box))
    default:
      return nil
    }
  }

  static func buildTrackHeaders(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .movieHeader(let box):
      return StructuredPayload(movieHeader: MovieHeaderDetail(box: box))
    case .trackHeader(let box):
      return StructuredPayload(trackHeader: TrackHeaderDetail(box: box))
    case .trackExtends(let box):
      return StructuredPayload(trackExtends: TrackExtendsDetail(box: box))
    default:
      return nil
    }
  }

  static func buildFragments(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    if let payload = buildTrackFragments(detail) { return payload }
    if let payload = buildMovieFragments(detail) { return payload }
    return nil
  }

  static func buildTrackFragments(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .trackFragmentHeader(let box):
      return StructuredPayload(trackFragmentHeader: TrackFragmentHeaderDetail(box: box))
    case .trackFragmentDecodeTime(let box):
      return StructuredPayload(trackFragmentDecodeTime: TrackFragmentDecodeTimeDetail(box: box))
    case .trackRun(let box):
      return StructuredPayload(trackRun: TrackRunDetail(box: box))
    case .trackFragment(let box):
      return StructuredPayload(trackFragment: TrackFragmentDetail(box: box))
    default:
      return nil
    }
  }

  static func buildMovieFragments(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .movieFragmentHeader(let box):
      return StructuredPayload(movieFragmentHeader: MovieFragmentHeaderDetail(box: box))
    case .movieFragmentRandomAccess(let box):
      return StructuredPayload(movieFragmentRandomAccess: MovieFragmentRandomAccessDetail(box: box))
    case .trackFragmentRandomAccess(let box):
      return StructuredPayload(trackFragmentRandomAccess: TrackFragmentRandomAccessDetail(box: box))
    case .movieFragmentRandomAccessOffset(let box):
      return StructuredPayload(movieFragmentRandomAccessOffset: MovieFragmentRandomAccessOffsetDetail(box: box))
    default:
      return nil
    }
  }

  static func buildSampleProtection(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .sampleEncryption(let box):
      return StructuredPayload(sampleEncryption: SampleEncryptionDetail(box: box))
    case .sampleAuxInfoOffsets(let box):
      return StructuredPayload(sampleAuxInfoOffsets: SampleAuxInfoOffsetsDetail(box: box))
    case .sampleAuxInfoSizes(let box):
      return StructuredPayload(sampleAuxInfoSizes: SampleAuxInfoSizesDetail(box: box))
    default:
      return nil
    }
  }

  static func buildTiming(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    if let payload = buildEditTiming(detail) { return payload }
    if let payload = buildSampleTables(detail) { return payload }
    return nil
  }

  static func buildEditTiming(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .editList(let box):
      return StructuredPayload(editList: EditListDetail(box: box))
    case .decodingTimeToSample(let box):
      return StructuredPayload(timeToSample: TimeToSampleDetail(box: box))
    case .compositionOffset(let box):
      return StructuredPayload(compositionOffset: CompositionOffsetDetail(box: box))
    default:
      return nil
    }
  }

  static func buildSampleTables(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .sampleToChunk(let box):
      return StructuredPayload(sampleToChunk: SampleToChunkDetail(box: box))
    case .chunkOffset(let box):
      return StructuredPayload(chunkOffset: ChunkOffsetDetail(box: box))
    case .sampleSize(let box):
      return StructuredPayload(sampleSize: SampleSizeDetail(box: box))
    case .compactSampleSize(let box):
      return StructuredPayload(compactSampleSize: CompactSampleSizeDetail(box: box))
    case .syncSampleTable(let box):
      return StructuredPayload(syncSampleTable: SyncSampleTableDetail(box: box))
    default:
      return nil
    }
  }

  static func buildMetadata(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .dataReference(let box):
      return StructuredPayload(dataReference: DataReferenceDetail(box: box))
    case .metadata(let box):
      return StructuredPayload(metadata: MetadataDetail(box: box))
    case .metadataKeyTable(let box):
      return StructuredPayload(metadataKeys: MetadataKeyTableDetail(box: box))
    case .metadataItemList(let box):
      return StructuredPayload(metadataItems: MetadataItemListDetail(box: box))
    default:
      return nil
    }
  }

  static func buildMedia(_ detail: ParsedBoxPayload.Detail) -> StructuredPayload? {
    switch detail {
    case .soundMediaHeader(let box):
      return StructuredPayload(soundMediaHeader: SoundMediaHeaderDetail(box: box))
    case .videoMediaHeader(let box):
      return StructuredPayload(videoMediaHeader: VideoMediaHeaderDetail(box: box))
    default:
      return nil
    }
  }

  init(
    fileType: FileTypeDetail? = nil,
    mediaData: MediaDataDetail? = nil,
    padding: PaddingDetail? = nil,
    movieHeader: MovieHeaderDetail? = nil,
    trackHeader: TrackHeaderDetail? = nil,
    trackExtends: TrackExtendsDetail? = nil,
    trackFragmentHeader: TrackFragmentHeaderDetail? = nil,
    trackFragmentDecodeTime: TrackFragmentDecodeTimeDetail? = nil,
    trackRun: TrackRunDetail? = nil,
    trackFragment: TrackFragmentDetail? = nil,
    movieFragmentHeader: MovieFragmentHeaderDetail? = nil,
    movieFragmentRandomAccess: MovieFragmentRandomAccessDetail? = nil,
    trackFragmentRandomAccess: TrackFragmentRandomAccessDetail? = nil,
    movieFragmentRandomAccessOffset: MovieFragmentRandomAccessOffsetDetail? = nil,
    sampleEncryption: SampleEncryptionDetail? = nil,
    sampleAuxInfoOffsets: SampleAuxInfoOffsetsDetail? = nil,
    sampleAuxInfoSizes: SampleAuxInfoSizesDetail? = nil,
    soundMediaHeader: SoundMediaHeaderDetail? = nil,
    videoMediaHeader: VideoMediaHeaderDetail? = nil,
    editList: EditListDetail? = nil,
    timeToSample: TimeToSampleDetail? = nil,
    compositionOffset: CompositionOffsetDetail? = nil,
    sampleToChunk: SampleToChunkDetail? = nil,
    chunkOffset: ChunkOffsetDetail? = nil,
    sampleSize: SampleSizeDetail? = nil,
    compactSampleSize: CompactSampleSizeDetail? = nil,
    syncSampleTable: SyncSampleTableDetail? = nil,
    dataReference: DataReferenceDetail? = nil,
    metadata: MetadataDetail? = nil,
    metadataKeys: MetadataKeyTableDetail? = nil,
    metadataItems: MetadataItemListDetail? = nil
  ) {
    self.fileType = fileType
    self.mediaData = mediaData
    self.padding = padding
    self.movieHeader = movieHeader
    self.trackHeader = trackHeader
    self.trackExtends = trackExtends
    self.trackFragmentHeader = trackFragmentHeader
    self.trackFragmentDecodeTime = trackFragmentDecodeTime
    self.trackRun = trackRun
    self.trackFragment = trackFragment
    self.movieFragmentHeader = movieFragmentHeader
    self.movieFragmentRandomAccess = movieFragmentRandomAccess
    self.trackFragmentRandomAccess = trackFragmentRandomAccess
    self.movieFragmentRandomAccessOffset = movieFragmentRandomAccessOffset
    self.sampleEncryption = sampleEncryption
    self.sampleAuxInfoOffsets = sampleAuxInfoOffsets
    self.sampleAuxInfoSizes = sampleAuxInfoSizes
    self.soundMediaHeader = soundMediaHeader
    self.videoMediaHeader = videoMediaHeader
    self.editList = editList
    self.timeToSample = timeToSample
    self.compositionOffset = compositionOffset
    self.sampleToChunk = sampleToChunk
    self.chunkOffset = chunkOffset
    self.sampleSize = sampleSize
    self.compactSampleSize = compactSampleSize
    self.syncSampleTable = syncSampleTable
    self.dataReference = dataReference
    self.metadata = metadata
    self.metadataKeys = metadataKeys
    self.metadataItems = metadataItems
  }

  enum CodingKeys: String, CodingKey {
    case fileType = "file_type"
    case mediaData = "media_data"
    case padding = "padding"
    case movieHeader = "movie_header"
    case trackHeader = "track_header"
    case trackExtends = "track_extends"
    case trackFragmentHeader = "track_fragment_header"
    case trackFragmentDecodeTime = "track_fragment_decode_time"
    case trackRun = "track_run"
    case trackFragment = "track_fragment"
    case movieFragmentHeader = "movie_fragment_header"
    case movieFragmentRandomAccess = "movie_fragment_random_access"
    case trackFragmentRandomAccess = "track_fragment_random_access"
    case movieFragmentRandomAccessOffset = "movie_fragment_random_access_offset"
    case sampleEncryption = "sample_encryption"
    case sampleAuxInfoOffsets = "sample_aux_info_offsets"
    case sampleAuxInfoSizes = "sample_aux_info_sizes"
    case soundMediaHeader = "sound_media_header"
    case videoMediaHeader = "video_media_header"
    case editList = "edit_list"
    case timeToSample = "time_to_sample"
    case compositionOffset = "composition_offset"
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

private struct SampleEncryptionDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let sampleCount: UInt32
  let overrideTrackEncryptionDefaults: Bool
  let usesSubsampleEncryption: Bool
  let algorithmIdentifier: String?
  let perSampleIVSize: UInt8?
  let keyIdentifierRange: ByteRange?
  let sampleInfo: RangeSummary?
  let constantIV: RangeSummary?

  init(box: ParsedBoxPayload.SampleEncryptionBox) {
    self.version = box.version
    self.flags = box.flags
    self.sampleCount = box.sampleCount
    self.overrideTrackEncryptionDefaults = box.overrideTrackEncryptionDefaults
    self.usesSubsampleEncryption = box.usesSubsampleEncryption
    if let algorithm = box.algorithmIdentifier {
      self.algorithmIdentifier = String(format: "0x%06X", algorithm)
    } else {
      self.algorithmIdentifier = nil
    }
    self.perSampleIVSize = box.perSampleIVSize
    if let range = box.keyIdentifierRange {
      self.keyIdentifierRange = ByteRange(range: range)
    } else {
      self.keyIdentifierRange = nil
    }
    if let range = box.sampleInfoRange {
      self.sampleInfo = RangeSummary(range: range, length: box.sampleInfoByteLength)
    } else {
      self.sampleInfo = nil
    }
    if let range = box.constantIVRange {
      self.constantIV = RangeSummary(range: range, length: box.constantIVByteLength)
    } else {
      self.constantIV = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case sampleCount = "sample_count"
    case overrideTrackEncryptionDefaults = "override_track_encryption_defaults"
    case usesSubsampleEncryption = "uses_subsample_encryption"
    case algorithmIdentifier = "algorithm_identifier"
    case perSampleIVSize = "per_sample_iv_size"
    case keyIdentifierRange = "key_identifier_range"
    case sampleInfo = "sample_info"
    case constantIV = "constant_iv"
  }
}

private struct SampleAuxInfoOffsetsDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let entryCount: UInt32
  let auxInfoType: String?
  let auxInfoTypeParameter: UInt32?
  let entrySizeBytes: Int
  let entries: RangeSummary?

  init(box: ParsedBoxPayload.SampleAuxInfoOffsetsBox) {
    self.version = box.version
    self.flags = box.flags
    self.entryCount = box.entryCount
    self.auxInfoType = box.auxInfoType?.rawValue
    self.auxInfoTypeParameter = box.auxInfoTypeParameter
    self.entrySizeBytes = box.entrySizeBytes
    if let range = box.entriesRange {
      self.entries = RangeSummary(range: range, length: box.entriesByteLength)
    } else {
      self.entries = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case entryCount = "entry_count"
    case auxInfoType = "aux_info_type"
    case auxInfoTypeParameter = "aux_info_type_parameter"
    case entrySizeBytes = "entry_size_bytes"
    case entries
  }
}

private struct SampleAuxInfoSizesDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let defaultSampleInfoSize: UInt8
  let entryCount: UInt32
  let auxInfoType: String?
  let auxInfoTypeParameter: UInt32?
  let variableSizes: RangeSummary?

  init(box: ParsedBoxPayload.SampleAuxInfoSizesBox) {
    self.version = box.version
    self.flags = box.flags
    self.defaultSampleInfoSize = box.defaultSampleInfoSize
    self.entryCount = box.entryCount
    self.auxInfoType = box.auxInfoType?.rawValue
    self.auxInfoTypeParameter = box.auxInfoTypeParameter
    if let range = box.variableEntriesRange {
      self.variableSizes = RangeSummary(range: range, length: box.variableEntriesByteLength)
    } else {
      self.variableSizes = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case defaultSampleInfoSize = "default_sample_info_size"
    case entryCount = "entry_count"
    case auxInfoType = "aux_info_type"
    case auxInfoTypeParameter = "aux_info_type_parameter"
    case variableSizes = "variable_sizes"
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
    self.entries = box.entries.map {
      Entry(index: $0.index, namespace: $0.namespace, name: $0.name)
    }
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
  let handlerType: String?
  let entryCount: Int
  let entries: [MetadataItemEntry]

  init(box: ParsedBoxPayload.MetadataItemListBox) {
    self.handlerType = box.handlerType?.rawValue
    self.entries = box.entries.enumerated().map {
      MetadataItemEntry(entry: $0.element, index: $0.offset + 1)
    }
    self.entryCount = entries.count
  }

  private enum CodingKeys: String, CodingKey {
    case handlerType = "handler_type"
    case entryCount = "entry_count"
    case entries
  }
}

private struct MetadataItemEntry: Encodable {
  let index: Int
  let identifier: MetadataItemIdentifier
  let namespace: String?
  let name: String?
  let values: [MetadataItemValue]

  init(entry: ParsedBoxPayload.MetadataItemListBox.Entry, index: Int) {
    self.index = index
    self.identifier = MetadataItemIdentifier(identifier: entry.identifier)
    self.namespace = entry.namespace
    self.name = entry.name
    self.values = entry.values.map(MetadataItemValue.init)
  }

  private enum CodingKeys: String, CodingKey {
    case index
    case identifier
    case namespace
    case name
    case values
  }
}

private struct MetadataItemIdentifier: Encodable {
  let kind: String
  let display: String
  let rawValue: UInt32
  let rawValueHex: String
  let keyIndex: UInt32?

  init(identifier: ParsedBoxPayload.MetadataItemListBox.Entry.Identifier) {
    switch identifier {
    case .fourCC(let raw, let display):
      self.kind = "fourcc"
      self.rawValue = raw
      self.rawValueHex = String(format: "0x%08X", raw)
      self.keyIndex = nil
      if display.isEmpty {
        self.display = self.rawValueHex
      } else {
        self.display = display
      }
    case .keyIndex(let index):
      self.kind = "key_index"
      self.rawValue = index
      self.rawValueHex = String(format: "0x%08X", index)
      self.keyIndex = index
      self.display = "key[\(index)]"
    case .raw(let value):
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

private struct MetadataItemValue: Encodable {
  let kind: String
  let stringValue: String?
  let integerValue: Int64?
  let unsignedValue: UInt64?
  let booleanValue: Bool?
  let float32Value: Double?
  let float64Value: Double?
  let byteLength: Int?
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

    let mapped = MetadataItemValue.map(kind: value.kind)
    self.kind = mapped.kind
    self.stringValue = mapped.stringValue
    self.integerValue = mapped.integerValue
    self.unsignedValue = mapped.unsignedValue
    self.booleanValue = mapped.booleanValue
    self.float32Value = mapped.float32Value
    self.float64Value = mapped.float64Value
    self.byteLength = mapped.byteLength
    self.dataFormat = mapped.dataFormat
    self.fixedPointValue = mapped.fixedPointValue
    self.fixedPointRaw = mapped.fixedPointRaw
    self.fixedPointFormat = mapped.fixedPointFormat
  }

  private static func map(kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind) -> MappedValue {
    if let mapped = mapText(kind) { return mapped }
    if let mapped = mapInteger(kind) { return mapped }
    if let mapped = mapFloatingPoint(kind) { return mapped }
    if let mapped = mapBinary(kind) { return mapped }
    return MappedValue(kind: "unknown")
  }

  private static func mapText(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind) -> MappedValue? {
    switch kind {
    case .utf8(let string):
      return MappedValue(kind: "utf8", stringValue: string)
    case .utf16(let string):
      return MappedValue(kind: "utf16", stringValue: string)
    default:
      return nil
    }
  }

  private static func mapInteger(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind) -> MappedValue? {
    switch kind {
    case .integer(let number):
      return MappedValue(kind: "integer", integerValue: number)
    case .unsignedInteger(let number):
      return MappedValue(kind: "unsigned_integer", unsignedValue: number)
    case .boolean(let flag):
      return MappedValue(kind: "boolean", booleanValue: flag)
    default:
      return nil
    }
  }

  private static func mapFloatingPoint(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind) -> MappedValue? {
    switch kind {
    case .float32(let number):
      return MappedValue(kind: "float32", float32Value: Double(number))
    case .float64(let number):
      return MappedValue(kind: "float64", float64Value: number)
    default:
      return nil
    }
  }

  private static func mapBinary(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind) -> MappedValue? {
    switch kind {
    case .data(let format, let data):
      return MappedValue(kind: "data", byteLength: data.count, dataFormat: format.rawValue)
    case .bytes(let data):
      return MappedValue(kind: "bytes", byteLength: data.count)
    case .signedFixedPoint(let point):
      return MappedValue(
        kind: "signed_fixed_point",
        fixedPointValue: point.value,
        fixedPointRaw: point.rawValue,
        fixedPointFormat: point.format.rawValue
      )
    default:
      return nil
    }
  }

  private struct MappedValue {
    let kind: String
    let stringValue: String?
    let integerValue: Int64?
    let unsignedValue: UInt64?
    let booleanValue: Bool?
    let float32Value: Double?
    let float64Value: Double?
    let byteLength: Int?
    let dataFormat: String?
    let fixedPointValue: Double?
    let fixedPointRaw: Int32?
    let fixedPointFormat: String?
  }

  private enum CodingKeys: String, CodingKey {
    case kind
    case stringValue = "string_value"
    case integerValue = "integer_value"
    case unsignedValue = "unsigned_value"
    case booleanValue = "boolean_value"
    case float32Value = "float32_value"
    case float64Value = "float64_value"
    case byteLength = "byte_length"
    case rawType = "raw_type"
    case rawTypeHex = "raw_type_hex"
    case dataFormat = "data_format"
    case locale
    case fixedPointValue = "fixed_point_value"
    case fixedPointRaw = "fixed_point_raw"
    case fixedPointFormat = "fixed_point_format"
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

    init(entry: ParsedBoxPayload.DataReferenceBox.Entry) {
      self.index = Int(entry.index)
      self.type = entry.type.rawValue
      self.version = Int(entry.version)
      self.flags = entry.flags
      self.selfContained = (entry.flags & 0x000001) != 0

      let payloadLengthValue =
        entry.payloadRange.map { Int($0.upperBound - $0.lowerBound) } ?? 0

      switch entry.location {
      case .selfContained:
        self.url = nil
        self.urn = nil
        self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
      case .url(let string):
        self.url = string
        self.urn = nil
        self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
      case .urn(let name, let location):
        self.url = nil
        self.urn = URN(name: name, location: location)
        self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
      case .data(let data):
        self.url = nil
        self.urn = nil
        if payloadLengthValue > 0 {
          self.payloadLength = payloadLengthValue
        } else if !data.isEmpty {
          self.payloadLength = data.count
        } else {
          self.payloadLength = nil
        }
      case .empty:
        self.url = nil
        self.urn = nil
        self.payloadLength = nil
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

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(index, forKey: .index)
      try container.encode(segmentDuration, forKey: .segmentDuration)
      try container.encode(mediaTime, forKey: .mediaTime)
      try container.encode(mediaRateInteger, forKey: .mediaRateInteger)
      try container.encode(mediaRateFraction, forKey: .mediaRateFraction)
      try container.encode(mediaRate, forKey: .mediaRate)

      try encodeSecondsValue(
        segmentDurationSeconds, forKey: .segmentDurationSeconds, in: &container)
      try encodeSecondsValue(mediaTimeSeconds, forKey: .mediaTimeSeconds, in: &container)

      try container.encode(presentationStart, forKey: .presentationStart)
      try container.encode(presentationEnd, forKey: .presentationEnd)

      try encodeSecondsValue(
        presentationStartSeconds, forKey: .presentationStartSeconds, in: &container)
      try encodeSecondsValue(
        presentationEndSeconds, forKey: .presentationEndSeconds, in: &container)

      try container.encode(isEmptyEdit, forKey: .isEmptyEdit)
    }

    private func encodeSecondsValue(
      _ value: Double?,
      forKey key: CodingKeys,
      in container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
      guard let value, let decimal = Self.decimal(from: value) else { return }
      try container.encode(decimal, forKey: key)
    }

    private static func decimal(from seconds: Double) -> Decimal? {
      let formatted = BoxParserRegistry.DefaultParsers.formatSeconds(seconds)
      return Decimal(string: formatted, locale: Locale(identifier: "en_US_POSIX"))
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

private struct TimeToSampleDetail: Encodable {
  struct Entry: Encodable {
    let index: UInt32
    let sampleCount: UInt32
    let sampleDelta: UInt32
    let byteRange: ByteRange

    init(entry: ParsedBoxPayload.DecodingTimeToSampleBox.Entry) {
      self.index = entry.index
      self.sampleCount = entry.sampleCount
      self.sampleDelta = entry.sampleDelta
      self.byteRange = ByteRange(range: entry.byteRange)
    }

    private enum CodingKeys: String, CodingKey {
      case index
      case sampleCount = "sample_count"
      case sampleDelta = "sample_delta"
      case byteRange = "byte_range"
    }
  }

  let version: UInt8
  let flags: UInt32
  let entryCount: UInt32
  let entries: [Entry]

  init(box: ParsedBoxPayload.DecodingTimeToSampleBox) {
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

private struct CompositionOffsetDetail: Encodable {
  struct Entry: Encodable {
    let index: UInt32
    let sampleCount: UInt32
    let sampleOffset: Int32
    let byteRange: ByteRange

    init(entry: ParsedBoxPayload.CompositionOffsetBox.Entry) {
      self.index = entry.index
      self.sampleCount = entry.sampleCount
      self.sampleOffset = entry.sampleOffset
      self.byteRange = ByteRange(range: entry.byteRange)
    }

    private enum CodingKeys: String, CodingKey {
      case index
      case sampleCount = "sample_count"
      case sampleOffset = "sample_offset"
      case byteRange = "byte_range"
    }
  }

  let version: UInt8
  let flags: UInt32
  let entryCount: UInt32
  let entries: [Entry]

  init(box: ParsedBoxPayload.CompositionOffsetBox) {
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

private struct TrackFragmentHeaderDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let trackID: UInt32
  let baseDataOffset: UInt64?
  let sampleDescriptionIndex: UInt32?
  let defaultSampleDuration: UInt32?
  let defaultSampleSize: UInt32?
  let defaultSampleFlags: UInt32?
  let durationIsEmpty: Bool
  let defaultBaseIsMoof: Bool

  init(box: ParsedBoxPayload.TrackFragmentHeaderBox) {
    self.version = box.version
    self.flags = box.flags
    self.trackID = box.trackID
    self.baseDataOffset = box.baseDataOffset
    self.sampleDescriptionIndex = box.sampleDescriptionIndex
    self.defaultSampleDuration = box.defaultSampleDuration
    self.defaultSampleSize = box.defaultSampleSize
    self.defaultSampleFlags = box.defaultSampleFlags
    self.durationIsEmpty = box.durationIsEmpty
    self.defaultBaseIsMoof = box.defaultBaseIsMoof
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case trackID = "track_ID"
    case baseDataOffset = "base_data_offset"
    case sampleDescriptionIndex = "sample_description_index"
    case defaultSampleDuration = "default_sample_duration"
    case defaultSampleSize = "default_sample_size"
    case defaultSampleFlags = "default_sample_flags"
    case durationIsEmpty = "duration_is_empty"
    case defaultBaseIsMoof = "default_base_is_moof"
  }
}

private struct TrackFragmentDecodeTimeDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let baseMediaDecodeTime: UInt64
  let baseMediaDecodeTimeIs64Bit: Bool

  init(box: ParsedBoxPayload.TrackFragmentDecodeTimeBox) {
    self.version = box.version
    self.flags = box.flags
    self.baseMediaDecodeTime = box.baseMediaDecodeTime
    self.baseMediaDecodeTimeIs64Bit = box.baseMediaDecodeTimeIs64Bit
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case baseMediaDecodeTime = "base_media_decode_time"
    case baseMediaDecodeTimeIs64Bit = "base_media_decode_time_is_64bit"
  }
}

private struct TrackRunEntryDetail: Encodable {
  let index: UInt32
  let decodeTime: UInt64?
  let presentationTime: Int64?
  let sampleDuration: UInt32?
  let sampleSize: UInt32?
  let sampleFlags: UInt32?
  let sampleCompositionTimeOffset: Int32?
  let dataOffset: UInt64?
  let byteRange: ByteRange?

  init(entry: ParsedBoxPayload.TrackRunBox.Entry) {
    self.index = entry.index
    self.decodeTime = entry.decodeTime
    self.presentationTime = entry.presentationTime
    self.sampleDuration = entry.sampleDuration
    self.sampleSize = entry.sampleSize
    self.sampleFlags = entry.sampleFlags
    self.sampleCompositionTimeOffset = entry.sampleCompositionTimeOffset
    self.dataOffset = entry.dataOffset
    if let range = entry.byteRange {
      self.byteRange = ByteRange(range: range)
    } else {
      self.byteRange = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case index
    case decodeTime = "decode_time"
    case presentationTime = "presentation_time"
    case sampleDuration = "sample_duration"
    case sampleSize = "sample_size"
    case sampleFlags = "sample_flags"
    case sampleCompositionTimeOffset = "sample_composition_time_offset"
    case dataOffset = "data_offset"
    case byteRange
  }
}

private struct TrackRunDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let sampleCount: UInt32
  let dataOffset: Int32?
  let firstSampleFlags: UInt32?
  let totalSampleDuration: UInt64?
  let totalSampleSize: UInt64?
  let startDecodeTime: UInt64?
  let endDecodeTime: UInt64?
  let startPresentationTime: Int64?
  let endPresentationTime: Int64?
  let startDataOffset: UInt64?
  let endDataOffset: UInt64?
  let trackID: UInt32?
  let sampleDescriptionIndex: UInt32?
  let runIndex: UInt32?
  let firstSampleGlobalIndex: UInt64?
  let entries: [TrackRunEntryDetail]

  init(box: ParsedBoxPayload.TrackRunBox) {
    self.version = box.version
    self.flags = box.flags
    self.sampleCount = box.sampleCount
    self.dataOffset = box.dataOffset
    self.firstSampleFlags = box.firstSampleFlags
    self.totalSampleDuration = box.totalSampleDuration
    self.totalSampleSize = box.totalSampleSize
    self.startDecodeTime = box.startDecodeTime
    self.endDecodeTime = box.endDecodeTime
    self.startPresentationTime = box.startPresentationTime
    self.endPresentationTime = box.endPresentationTime
    self.startDataOffset = box.startDataOffset
    self.endDataOffset = box.endDataOffset
    self.trackID = box.trackID
    self.sampleDescriptionIndex = box.sampleDescriptionIndex
    self.runIndex = box.runIndex
    self.firstSampleGlobalIndex = box.firstSampleGlobalIndex
    self.entries = box.entries.map(TrackRunEntryDetail.init)
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case sampleCount = "sample_count"
    case dataOffset = "data_offset"
    case firstSampleFlags = "first_sample_flags"
    case totalSampleDuration = "total_sample_duration"
    case totalSampleSize = "total_sample_size"
    case startDecodeTime = "start_decode_time"
    case endDecodeTime = "end_decode_time"
    case startPresentationTime = "start_presentation_time"
    case endPresentationTime = "end_presentation_time"
    case startDataOffset = "start_data_offset"
    case endDataOffset = "end_data_offset"
    case trackID = "track_ID"
    case sampleDescriptionIndex = "sample_description_index"
    case runIndex = "run_index"
    case firstSampleGlobalIndex = "first_sample_global_index"
    case entries
  }
}

private struct TrackFragmentRandomAccessEntryDetail: Encodable {
  let index: UInt32
  let time: UInt64
  let moofOffset: UInt64
  let trafNumber: UInt64
  let trunNumber: UInt64
  let sampleNumber: UInt64
  let fragmentSequenceNumber: UInt32?
  let trackID: UInt32?
  let sampleDescriptionIndex: UInt32?
  let runIndex: UInt32?
  let firstSampleGlobalIndex: UInt64?
  let resolvedDecodeTime: UInt64?
  let resolvedPresentationTime: Int64?
  let resolvedDataOffset: UInt64?
  let resolvedSampleSize: UInt32?
  let resolvedSampleFlags: UInt32?

  init(entry: ParsedBoxPayload.TrackFragmentRandomAccessBox.Entry) {
    self.index = entry.index
    self.time = entry.time
    self.moofOffset = entry.moofOffset
    self.trafNumber = entry.trafNumber
    self.trunNumber = entry.trunNumber
    self.sampleNumber = entry.sampleNumber
    self.fragmentSequenceNumber = entry.fragmentSequenceNumber
    self.trackID = entry.trackID
    self.sampleDescriptionIndex = entry.sampleDescriptionIndex
    self.runIndex = entry.runIndex
    self.firstSampleGlobalIndex = entry.firstSampleGlobalIndex
    self.resolvedDecodeTime = entry.resolvedDecodeTime
    self.resolvedPresentationTime = entry.resolvedPresentationTime
    self.resolvedDataOffset = entry.resolvedDataOffset
    self.resolvedSampleSize = entry.resolvedSampleSize
    self.resolvedSampleFlags = entry.resolvedSampleFlags
  }

  private enum CodingKeys: String, CodingKey {
    case index
    case time
    case moofOffset = "moof_offset"
    case trafNumber = "traf_number"
    case trunNumber = "trun_number"
    case sampleNumber = "sample_number"
    case fragmentSequenceNumber = "fragment_sequence_number"
    case trackID = "track_ID"
    case sampleDescriptionIndex = "sample_description_index"
    case runIndex = "run_index"
    case firstSampleGlobalIndex = "first_sample_global_index"
    case resolvedDecodeTime = "resolved_decode_time"
    case resolvedPresentationTime = "resolved_presentation_time"
    case resolvedDataOffset = "resolved_data_offset"
    case resolvedSampleSize = "resolved_sample_size"
    case resolvedSampleFlags = "resolved_sample_flags"
  }
}

private struct TrackFragmentRandomAccessDetail: Encodable {
  let version: UInt8
  let flags: UInt32
  let trackID: UInt32
  let trafNumberLength: UInt8
  let trunNumberLength: UInt8
  let sampleNumberLength: UInt8
  let entryCount: UInt32
  let entries: [TrackFragmentRandomAccessEntryDetail]

  init(box: ParsedBoxPayload.TrackFragmentRandomAccessBox) {
    self.version = box.version
    self.flags = box.flags
    self.trackID = box.trackID
    self.trafNumberLength = box.trafNumberLength
    self.trunNumberLength = box.trunNumberLength
    self.sampleNumberLength = box.sampleNumberLength
    self.entryCount = box.entryCount
    self.entries = box.entries.map(TrackFragmentRandomAccessEntryDetail.init)
  }

  private enum CodingKeys: String, CodingKey {
    case version
    case flags
    case trackID = "track_ID"
    case trafNumberLength = "traf_number_length_bytes"
    case trunNumberLength = "trun_number_length_bytes"
    case sampleNumberLength = "sample_number_length_bytes"
    case entryCount = "entry_count"
    case entries
  }
}

private struct MovieFragmentRandomAccessOffsetDetail: Encodable {
  let mfraSize: UInt32

  init(box: ParsedBoxPayload.MovieFragmentRandomAccessOffsetBox) {
    self.mfraSize = box.mfraSize
  }

  private enum CodingKeys: String, CodingKey {
    case mfraSize = "mfra_size"
  }
}

private struct MovieFragmentRandomAccessTrackDetail: Encodable {
  let trackID: UInt32
  let entryCount: Int
  let earliestTime: UInt64?
  let latestTime: UInt64?
  let fragments: [UInt32]

  init(summary: ParsedBoxPayload.MovieFragmentRandomAccessBox.TrackSummary) {
    self.trackID = summary.trackID
    self.entryCount = summary.entryCount
    self.earliestTime = summary.earliestTime
    self.latestTime = summary.latestTime
    self.fragments = summary.referencedFragmentSequenceNumbers
  }

  private enum CodingKeys: String, CodingKey {
    case trackID = "track_ID"
    case entryCount = "entry_count"
    case earliestTime = "earliest_time"
    case latestTime = "latest_time"
    case fragments
  }
}

private struct MovieFragmentRandomAccessDetail: Encodable {
  let tracks: [MovieFragmentRandomAccessTrackDetail]
  let totalEntryCount: Int
  let offset: MovieFragmentRandomAccessOffsetDetail?

  init(box: ParsedBoxPayload.MovieFragmentRandomAccessBox) {
    self.tracks = box.tracks.map(MovieFragmentRandomAccessTrackDetail.init)
    self.totalEntryCount = box.totalEntryCount
    if let offset = box.offset {
      self.offset = MovieFragmentRandomAccessOffsetDetail(box: offset)
    } else {
      self.offset = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case tracks
    case totalEntryCount = "total_entry_count"
    case offset
  }
}

private struct TrackFragmentDetail: Encodable {
  let trackID: UInt32?
  let sampleDescriptionIndex: UInt32?
  let baseDataOffset: UInt64?
  let defaultSampleDuration: UInt32?
  let defaultSampleSize: UInt32?
  let defaultSampleFlags: UInt32?
  let durationIsEmpty: Bool
  let defaultBaseIsMoof: Bool
  let baseDecodeTime: UInt64?
  let baseDecodeTimeIs64Bit: Bool
  let runs: [TrackRunDetail]
  let totalSampleCount: UInt64
  let totalSampleSize: UInt64?
  let totalSampleDuration: UInt64?
  let earliestPresentationTime: Int64?
  let latestPresentationTime: Int64?
  let firstDecodeTime: UInt64?
  let lastDecodeTime: UInt64?

  init(box: ParsedBoxPayload.TrackFragmentBox) {
    self.trackID = box.trackID
    self.sampleDescriptionIndex = box.sampleDescriptionIndex
    self.baseDataOffset = box.baseDataOffset
    self.defaultSampleDuration = box.defaultSampleDuration
    self.defaultSampleSize = box.defaultSampleSize
    self.defaultSampleFlags = box.defaultSampleFlags
    self.durationIsEmpty = box.durationIsEmpty
    self.defaultBaseIsMoof = box.defaultBaseIsMoof
    self.baseDecodeTime = box.baseDecodeTime
    self.baseDecodeTimeIs64Bit = box.baseDecodeTimeIs64Bit
    self.runs = box.runs.map(TrackRunDetail.init)
    self.totalSampleCount = box.totalSampleCount
    self.totalSampleSize = box.totalSampleSize
    self.totalSampleDuration = box.totalSampleDuration
    self.earliestPresentationTime = box.earliestPresentationTime
    self.latestPresentationTime = box.latestPresentationTime
    self.firstDecodeTime = box.firstDecodeTime
    self.lastDecodeTime = box.lastDecodeTime
  }

  private enum CodingKeys: String, CodingKey {
    case trackID = "track_ID"
    case sampleDescriptionIndex = "sample_description_index"
    case baseDataOffset = "base_data_offset"
    case defaultSampleDuration = "default_sample_duration"
    case defaultSampleSize = "default_sample_size"
    case defaultSampleFlags = "default_sample_flags"
    case durationIsEmpty = "duration_is_empty"
    case defaultBaseIsMoof = "default_base_is_moof"
    case baseDecodeTime = "base_decode_time"
    case baseDecodeTimeIs64Bit = "base_decode_time_is_64bit"
    case runs
    case totalSampleCount = "total_sample_count"
    case totalSampleSize = "total_sample_size"
    case totalSampleDuration = "total_sample_duration"
    case earliestPresentationTime = "earliest_presentation_time"
    case latestPresentationTime = "latest_presentation_time"
    case firstDecodeTime = "first_decode_time"
    case lastDecodeTime = "last_decode_time"
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
