import Foundation

public struct ParsedBoxPayload: Equatable, Sendable {
  public enum Detail: Equatable, Sendable {
    case fileType(FileTypeBox)
    case mediaData(MediaDataBox)
    case padding(PaddingBox)
    case movieHeader(MovieHeaderBox)
    case trackHeader(TrackHeaderBox)
    case trackExtends(TrackExtendsDefaultsBox)
    case trackFragmentHeader(TrackFragmentHeaderBox)
    case trackFragmentDecodeTime(TrackFragmentDecodeTimeBox)
    case trackRun(TrackRunBox)
    case sampleEncryption(SampleEncryptionBox)
    case sampleAuxInfoOffsets(SampleAuxInfoOffsetsBox)
    case sampleAuxInfoSizes(SampleAuxInfoSizesBox)
    case trackFragment(TrackFragmentBox)
    case movieFragmentHeader(MovieFragmentHeaderBox)
    case movieFragmentRandomAccess(MovieFragmentRandomAccessBox)
    case trackFragmentRandomAccess(TrackFragmentRandomAccessBox)
    case movieFragmentRandomAccessOffset(MovieFragmentRandomAccessOffsetBox)
    case soundMediaHeader(SoundMediaHeaderBox)
    case videoMediaHeader(VideoMediaHeaderBox)
    case editList(EditListBox)
    case decodingTimeToSample(DecodingTimeToSampleBox)
    case compositionOffset(CompositionOffsetBox)
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

  public struct TrackExtendsDefaultsBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let trackID: UInt32
    public let defaultSampleDescriptionIndex: UInt32
    public let defaultSampleDuration: UInt32
    public let defaultSampleSize: UInt32
    public let defaultSampleFlags: UInt32

    public init(
      version: UInt8,
      flags: UInt32,
      trackID: UInt32,
      defaultSampleDescriptionIndex: UInt32,
      defaultSampleDuration: UInt32,
      defaultSampleSize: UInt32,
      defaultSampleFlags: UInt32
    ) {
      self.version = version
      self.flags = flags
      self.trackID = trackID
      self.defaultSampleDescriptionIndex = defaultSampleDescriptionIndex
      self.defaultSampleDuration = defaultSampleDuration
      self.defaultSampleSize = defaultSampleSize
      self.defaultSampleFlags = defaultSampleFlags
    }
  }

  public struct TrackFragmentHeaderBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let trackID: UInt32
    public let baseDataOffset: UInt64?
    public let sampleDescriptionIndex: UInt32?
    public let defaultSampleDuration: UInt32?
    public let defaultSampleSize: UInt32?
    public let defaultSampleFlags: UInt32?
    public let durationIsEmpty: Bool
    public let defaultBaseIsMoof: Bool

    public init(
      version: UInt8,
      flags: UInt32,
      trackID: UInt32,
      baseDataOffset: UInt64?,
      sampleDescriptionIndex: UInt32?,
      defaultSampleDuration: UInt32?,
      defaultSampleSize: UInt32?,
      defaultSampleFlags: UInt32?,
      durationIsEmpty: Bool,
      defaultBaseIsMoof: Bool
    ) {
      self.version = version
      self.flags = flags
      self.trackID = trackID
      self.baseDataOffset = baseDataOffset
      self.sampleDescriptionIndex = sampleDescriptionIndex
      self.defaultSampleDuration = defaultSampleDuration
      self.defaultSampleSize = defaultSampleSize
      self.defaultSampleFlags = defaultSampleFlags
      self.durationIsEmpty = durationIsEmpty
      self.defaultBaseIsMoof = defaultBaseIsMoof
    }
  }

  public struct MovieFragmentHeaderBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let sequenceNumber: UInt32

    public init(version: UInt8, flags: UInt32, sequenceNumber: UInt32) {
      self.version = version
      self.flags = flags
      self.sequenceNumber = sequenceNumber
    }
  }

  public struct TrackFragmentDecodeTimeBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let baseMediaDecodeTime: UInt64
    public let baseMediaDecodeTimeIs64Bit: Bool

    public init(
      version: UInt8,
      flags: UInt32,
      baseMediaDecodeTime: UInt64,
      baseMediaDecodeTimeIs64Bit: Bool
    ) {
      self.version = version
      self.flags = flags
      self.baseMediaDecodeTime = baseMediaDecodeTime
      self.baseMediaDecodeTimeIs64Bit = baseMediaDecodeTimeIs64Bit
    }
  }

  public struct TrackRunBox: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
      public let index: UInt32
      public let decodeTime: UInt64?
      public let presentationTime: Int64?
      public let sampleDuration: UInt32?
      public let sampleSize: UInt32?
      public let sampleFlags: UInt32?
      public let sampleCompositionTimeOffset: Int32?
      public let dataOffset: UInt64?
      public let byteRange: Range<Int64>?

      public init(
        index: UInt32,
        decodeTime: UInt64?,
        presentationTime: Int64?,
        sampleDuration: UInt32?,
        sampleSize: UInt32?,
        sampleFlags: UInt32?,
        sampleCompositionTimeOffset: Int32?,
        dataOffset: UInt64?,
        byteRange: Range<Int64>?
      ) {
        self.index = index
        self.decodeTime = decodeTime
        self.presentationTime = presentationTime
        self.sampleDuration = sampleDuration
        self.sampleSize = sampleSize
        self.sampleFlags = sampleFlags
        self.sampleCompositionTimeOffset = sampleCompositionTimeOffset
        self.dataOffset = dataOffset
        self.byteRange = byteRange
      }
    }

    public let version: UInt8
    public let flags: UInt32
    public let sampleCount: UInt32
    public let dataOffset: Int32?
    public let firstSampleFlags: UInt32?
    public let entries: [Entry]
    public let totalSampleDuration: UInt64?
    public let totalSampleSize: UInt64?
    public let startDecodeTime: UInt64?
    public let endDecodeTime: UInt64?
    public let startPresentationTime: Int64?
    public let endPresentationTime: Int64?
    public let startDataOffset: UInt64?
    public let endDataOffset: UInt64?
    public let trackID: UInt32?
    public let sampleDescriptionIndex: UInt32?
    public let runIndex: UInt32?
    public let firstSampleGlobalIndex: UInt64?

    public init(
      version: UInt8,
      flags: UInt32,
      sampleCount: UInt32,
      dataOffset: Int32?,
      firstSampleFlags: UInt32?,
      entries: [Entry],
      totalSampleDuration: UInt64?,
      totalSampleSize: UInt64?,
      startDecodeTime: UInt64?,
      endDecodeTime: UInt64?,
      startPresentationTime: Int64?,
      endPresentationTime: Int64?,
      startDataOffset: UInt64?,
      endDataOffset: UInt64?,
      trackID: UInt32?,
      sampleDescriptionIndex: UInt32?,
      runIndex: UInt32?,
      firstSampleGlobalIndex: UInt64?
    ) {
      self.version = version
      self.flags = flags
      self.sampleCount = sampleCount
      self.dataOffset = dataOffset
      self.firstSampleFlags = firstSampleFlags
      self.entries = entries
      self.totalSampleDuration = totalSampleDuration
      self.totalSampleSize = totalSampleSize
      self.startDecodeTime = startDecodeTime
      self.endDecodeTime = endDecodeTime
      self.startPresentationTime = startPresentationTime
      self.endPresentationTime = endPresentationTime
      self.startDataOffset = startDataOffset
      self.endDataOffset = endDataOffset
      self.trackID = trackID
      self.sampleDescriptionIndex = sampleDescriptionIndex
      self.runIndex = runIndex
      self.firstSampleGlobalIndex = firstSampleGlobalIndex
    }
  }

  public struct SampleEncryptionBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let sampleCount: UInt32
    public let algorithmIdentifier: UInt32?
    public let perSampleIVSize: UInt8?
    public let keyIdentifierRange: Range<Int64>?
    public let sampleInfoRange: Range<Int64>?
    public let sampleInfoByteLength: Int64?
    public let constantIVRange: Range<Int64>?
    public let constantIVByteLength: Int64?

    public init(
      version: UInt8,
      flags: UInt32,
      sampleCount: UInt32,
      algorithmIdentifier: UInt32?,
      perSampleIVSize: UInt8?,
      keyIdentifierRange: Range<Int64>?,
      sampleInfoRange: Range<Int64>?,
      sampleInfoByteLength: Int64?,
      constantIVRange: Range<Int64>?,
      constantIVByteLength: Int64?
    ) {
      self.version = version
      self.flags = flags
      self.sampleCount = sampleCount
      self.algorithmIdentifier = algorithmIdentifier
      self.perSampleIVSize = perSampleIVSize
      self.keyIdentifierRange = keyIdentifierRange
      self.sampleInfoRange = sampleInfoRange
      self.sampleInfoByteLength = sampleInfoByteLength
      self.constantIVRange = constantIVRange
      self.constantIVByteLength = constantIVByteLength
    }

    public var overrideTrackEncryptionDefaults: Bool { (flags & 0x000001) != 0 }

    public var usesSubsampleEncryption: Bool { (flags & 0x000002) != 0 }
  }

  public struct SampleAuxInfoOffsetsBox: Equatable, Sendable {
    public enum EntrySize: Equatable, Sendable {
      case fourBytes
      case eightBytes
    }

    public let version: UInt8
    public let flags: UInt32
    public let entryCount: UInt32
    public let auxInfoType: FourCharCode?
    public let auxInfoTypeParameter: UInt32?
    public let entrySize: EntrySize
    public let entriesRange: Range<Int64>?
    public let entriesByteLength: Int64?

    public init(
      version: UInt8,
      flags: UInt32,
      entryCount: UInt32,
      auxInfoType: FourCharCode?,
      auxInfoTypeParameter: UInt32?,
      entrySize: EntrySize,
      entriesRange: Range<Int64>?,
      entriesByteLength: Int64?
    ) {
      self.version = version
      self.flags = flags
      self.entryCount = entryCount
      self.auxInfoType = auxInfoType
      self.auxInfoTypeParameter = auxInfoTypeParameter
      self.entrySize = entrySize
      self.entriesRange = entriesRange
      self.entriesByteLength = entriesByteLength
    }

    public var entrySizeBytes: Int {
      switch entrySize {
      case .fourBytes:
        return 4
      case .eightBytes:
        return 8
      }
    }
  }

  public struct SampleAuxInfoSizesBox: Equatable, Sendable {
    public let version: UInt8
    public let flags: UInt32
    public let defaultSampleInfoSize: UInt8
    public let entryCount: UInt32
    public let auxInfoType: FourCharCode?
    public let auxInfoTypeParameter: UInt32?
    public let variableEntriesRange: Range<Int64>?
    public let variableEntriesByteLength: Int64?

    public init(
      version: UInt8,
      flags: UInt32,
      defaultSampleInfoSize: UInt8,
      entryCount: UInt32,
      auxInfoType: FourCharCode?,
      auxInfoTypeParameter: UInt32?,
      variableEntriesRange: Range<Int64>?,
      variableEntriesByteLength: Int64?
    ) {
      self.version = version
      self.flags = flags
      self.defaultSampleInfoSize = defaultSampleInfoSize
      self.entryCount = entryCount
      self.auxInfoType = auxInfoType
      self.auxInfoTypeParameter = auxInfoTypeParameter
      self.variableEntriesRange = variableEntriesRange
      self.variableEntriesByteLength = variableEntriesByteLength
    }

    public var usesUniformSampleInfoSize: Bool { defaultSampleInfoSize != 0 }
  }

  public struct TrackFragmentBox: Equatable, Sendable {
    public let trackID: UInt32?
    public let sampleDescriptionIndex: UInt32?
    public let baseDataOffset: UInt64?
    public let defaultSampleDuration: UInt32?
    public let defaultSampleSize: UInt32?
    public let defaultSampleFlags: UInt32?
    public let durationIsEmpty: Bool
    public let defaultBaseIsMoof: Bool
    public let baseDecodeTime: UInt64?
    public let baseDecodeTimeIs64Bit: Bool
    public let runs: [TrackRunBox]
    public let totalSampleCount: UInt64
    public let totalSampleSize: UInt64?
    public let totalSampleDuration: UInt64?
    public let earliestPresentationTime: Int64?
    public let latestPresentationTime: Int64?
    public let firstDecodeTime: UInt64?
    public let lastDecodeTime: UInt64?

    public init(
      trackID: UInt32?,
      sampleDescriptionIndex: UInt32?,
      baseDataOffset: UInt64?,
      defaultSampleDuration: UInt32?,
      defaultSampleSize: UInt32?,
      defaultSampleFlags: UInt32?,
      durationIsEmpty: Bool,
      defaultBaseIsMoof: Bool,
      baseDecodeTime: UInt64?,
      baseDecodeTimeIs64Bit: Bool,
      runs: [TrackRunBox],
      totalSampleCount: UInt64,
      totalSampleSize: UInt64?,
      totalSampleDuration: UInt64?,
      earliestPresentationTime: Int64?,
      latestPresentationTime: Int64?,
      firstDecodeTime: UInt64?,
      lastDecodeTime: UInt64?
    ) {
      self.trackID = trackID
      self.sampleDescriptionIndex = sampleDescriptionIndex
      self.baseDataOffset = baseDataOffset
      self.defaultSampleDuration = defaultSampleDuration
      self.defaultSampleSize = defaultSampleSize
      self.defaultSampleFlags = defaultSampleFlags
      self.durationIsEmpty = durationIsEmpty
      self.defaultBaseIsMoof = defaultBaseIsMoof
      self.baseDecodeTime = baseDecodeTime
      self.baseDecodeTimeIs64Bit = baseDecodeTimeIs64Bit
      self.runs = runs
      self.totalSampleCount = totalSampleCount
      self.totalSampleSize = totalSampleSize
      self.totalSampleDuration = totalSampleDuration
      self.earliestPresentationTime = earliestPresentationTime
      self.latestPresentationTime = latestPresentationTime
      self.firstDecodeTime = firstDecodeTime
      self.lastDecodeTime = lastDecodeTime
    }
  }

  public struct TrackFragmentRandomAccessBox: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
      public let index: UInt32
      public let time: UInt64
      public let moofOffset: UInt64
      public let trafNumber: UInt64
      public let trunNumber: UInt64
      public let sampleNumber: UInt64
      public let fragmentSequenceNumber: UInt32?
      public let trackID: UInt32?
      public let sampleDescriptionIndex: UInt32?
      public let runIndex: UInt32?
      public let firstSampleGlobalIndex: UInt64?
      public let resolvedDecodeTime: UInt64?
      public let resolvedPresentationTime: Int64?
      public let resolvedDataOffset: UInt64?
      public let resolvedSampleSize: UInt32?
      public let resolvedSampleFlags: UInt32?

      public init(
        index: UInt32,
        time: UInt64,
        moofOffset: UInt64,
        trafNumber: UInt64,
        trunNumber: UInt64,
        sampleNumber: UInt64,
        fragmentSequenceNumber: UInt32?,
        trackID: UInt32?,
        sampleDescriptionIndex: UInt32?,
        runIndex: UInt32?,
        firstSampleGlobalIndex: UInt64?,
        resolvedDecodeTime: UInt64?,
        resolvedPresentationTime: Int64?,
        resolvedDataOffset: UInt64?,
        resolvedSampleSize: UInt32?,
        resolvedSampleFlags: UInt32?
      ) {
        self.index = index
        self.time = time
        self.moofOffset = moofOffset
        self.trafNumber = trafNumber
        self.trunNumber = trunNumber
        self.sampleNumber = sampleNumber
        self.fragmentSequenceNumber = fragmentSequenceNumber
        self.trackID = trackID
        self.sampleDescriptionIndex = sampleDescriptionIndex
        self.runIndex = runIndex
        self.firstSampleGlobalIndex = firstSampleGlobalIndex
        self.resolvedDecodeTime = resolvedDecodeTime
        self.resolvedPresentationTime = resolvedPresentationTime
        self.resolvedDataOffset = resolvedDataOffset
        self.resolvedSampleSize = resolvedSampleSize
        self.resolvedSampleFlags = resolvedSampleFlags
      }
    }

    public let version: UInt8
    public let flags: UInt32
    public let trackID: UInt32
    public let trafNumberLength: UInt8
    public let trunNumberLength: UInt8
    public let sampleNumberLength: UInt8
    public let entryCount: UInt32
    public let entries: [Entry]

    public init(
      version: UInt8,
      flags: UInt32,
      trackID: UInt32,
      trafNumberLength: UInt8,
      trunNumberLength: UInt8,
      sampleNumberLength: UInt8,
      entryCount: UInt32,
      entries: [Entry]
    ) {
      self.version = version
      self.flags = flags
      self.trackID = trackID
      self.trafNumberLength = trafNumberLength
      self.trunNumberLength = trunNumberLength
      self.sampleNumberLength = sampleNumberLength
      self.entryCount = entryCount
      self.entries = entries
    }
  }

  public struct MovieFragmentRandomAccessOffsetBox: Equatable, Sendable {
    public let mfraSize: UInt32

    public init(mfraSize: UInt32) {
      self.mfraSize = mfraSize
    }
  }

  public struct MovieFragmentRandomAccessBox: Equatable, Sendable {
    public struct TrackSummary: Equatable, Sendable {
      public let trackID: UInt32
      public let entryCount: Int
      public let earliestTime: UInt64?
      public let latestTime: UInt64?
      public let referencedFragmentSequenceNumbers: [UInt32]

      public init(
        trackID: UInt32,
        entryCount: Int,
        earliestTime: UInt64?,
        latestTime: UInt64?,
        referencedFragmentSequenceNumbers: [UInt32]
      ) {
        self.trackID = trackID
        self.entryCount = entryCount
        self.earliestTime = earliestTime
        self.latestTime = latestTime
        self.referencedFragmentSequenceNumbers = referencedFragmentSequenceNumbers
      }
    }

    public let tracks: [TrackSummary]
    public let totalEntryCount: Int
    public let offset: MovieFragmentRandomAccessOffsetBox?

    public init(
      tracks: [TrackSummary],
      totalEntryCount: Int,
      offset: MovieFragmentRandomAccessOffsetBox?
    ) {
      self.tracks = tracks
      self.totalEntryCount = totalEntryCount
      self.offset = offset
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

  public struct DecodingTimeToSampleBox: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
      public let index: UInt32
      public let sampleCount: UInt32
      public let sampleDelta: UInt32
      public let byteRange: Range<Int64>

      public init(index: UInt32, sampleCount: UInt32, sampleDelta: UInt32, byteRange: Range<Int64>)
      {
        self.index = index
        self.sampleCount = sampleCount
        self.sampleDelta = sampleDelta
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

    public var totalSampleCount: UInt64 {
      entries.reduce(UInt64(0)) { total, entry in
        let (next, overflow) = total.addingReportingOverflow(UInt64(entry.sampleCount))
        return overflow ? UInt64.max : next
      }
    }
  }

  public struct CompositionOffsetBox: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
      public let index: UInt32
      public let sampleCount: UInt32
      public let sampleOffset: Int32
      public let byteRange: Range<Int64>

      public init(index: UInt32, sampleCount: UInt32, sampleOffset: Int32, byteRange: Range<Int64>)
      {
        self.index = index
        self.sampleCount = sampleCount
        self.sampleOffset = sampleOffset
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

    public var totalSampleCount: UInt64 {
      entries.reduce(UInt64(0)) { total, entry in
        let (next, overflow) = total.addingReportingOverflow(UInt64(entry.sampleCount))
        return overflow ? UInt64.max : next
      }
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
        public enum DataFormat: String, Equatable, Sendable {
          case jpeg
          case png
          case bmp
          case gif
          case tiff

          var displayName: String {
            switch self {
            case .jpeg:
              return "JPEG Data"
            case .png:
              return "PNG Data"
            case .bmp:
              return "BMP Data"
            case .gif:
              return "GIF Data"
            case .tiff:
              return "TIFF Data"
            }
          }

          var valuePrefix: String {
            switch self {
            case .jpeg:
              return "JPEG data"
            case .png:
              return "PNG data"
            case .bmp:
              return "BMP data"
            case .gif:
              return "GIF data"
            case .tiff:
              return "TIFF data"
            }
          }
        }

        public struct SignedFixedPoint: Equatable, Sendable {
          public enum Format: String, Equatable, Sendable {
            case s8_8 = "S8.8"
            case s16_16 = "S16.16"
          }

          public let value: Double
          public let rawValue: Int32
          public let format: Format

          public init(value: Double, rawValue: Int32, format: Format) {
            self.value = value
            self.rawValue = rawValue
            self.format = format
          }
        }

        public enum Kind: Equatable, Sendable {
          case utf8(String)
          case utf16(String)
          case integer(Int64)
          case unsignedInteger(UInt64)
          case boolean(Bool)
          case float32(Float32)
          case float64(Double)
          case data(format: DataFormat, data: Data)
          case bytes(Data)
          case signedFixedPoint(SignedFixedPoint)
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
    guard case .fileType(let box) = detail else { return nil }
    return box
  }

  public var movieHeader: MovieHeaderBox? {
    guard case .movieHeader(let box) = detail else { return nil }
    return box
  }

  public var mediaData: MediaDataBox? {
    guard case .mediaData(let box) = detail else { return nil }
    return box
  }

  public var padding: PaddingBox? {
    guard case .padding(let box) = detail else { return nil }
    return box
  }

  public var trackHeader: TrackHeaderBox? {
    guard case .trackHeader(let box) = detail else { return nil }
    return box
  }

  public var trackExtends: TrackExtendsDefaultsBox? {
    guard case .trackExtends(let box) = detail else { return nil }
    return box
  }

  public var trackFragmentHeader: TrackFragmentHeaderBox? {
    guard case .trackFragmentHeader(let box) = detail else { return nil }
    return box
  }

  public var trackFragmentDecodeTime: TrackFragmentDecodeTimeBox? {
    guard case .trackFragmentDecodeTime(let box) = detail else { return nil }
    return box
  }

  public var trackRun: TrackRunBox? {
    guard case .trackRun(let box) = detail else { return nil }
    return box
  }

  public var sampleEncryption: SampleEncryptionBox? {
    guard case .sampleEncryption(let box) = detail else { return nil }
    return box
  }

  public var sampleAuxInfoOffsets: SampleAuxInfoOffsetsBox? {
    guard case .sampleAuxInfoOffsets(let box) = detail else { return nil }
    return box
  }

  public var sampleAuxInfoSizes: SampleAuxInfoSizesBox? {
    guard case .sampleAuxInfoSizes(let box) = detail else { return nil }
    return box
  }

  public var trackFragment: TrackFragmentBox? {
    guard case .trackFragment(let box) = detail else { return nil }
    return box
  }

  public var movieFragmentHeader: MovieFragmentHeaderBox? {
    guard case .movieFragmentHeader(let box) = detail else { return nil }
    return box
  }

  public var trackFragmentRandomAccess: TrackFragmentRandomAccessBox? {
    guard case .trackFragmentRandomAccess(let box) = detail else { return nil }
    return box
  }

  public var movieFragmentRandomAccess: MovieFragmentRandomAccessBox? {
    guard case .movieFragmentRandomAccess(let box) = detail else { return nil }
    return box
  }

  public var movieFragmentRandomAccessOffset: MovieFragmentRandomAccessOffsetBox? {
    guard case .movieFragmentRandomAccessOffset(let box) = detail else { return nil }
    return box
  }

  public var soundMediaHeader: SoundMediaHeaderBox? {
    guard case .soundMediaHeader(let box) = detail else { return nil }
    return box
  }

  public var videoMediaHeader: VideoMediaHeaderBox? {
    guard case .videoMediaHeader(let box) = detail else { return nil }
    return box
  }

  public var editList: EditListBox? {
    guard case .editList(let box) = detail else { return nil }
    return box
  }

  public var decodingTimeToSample: DecodingTimeToSampleBox? {
    guard case .decodingTimeToSample(let box) = detail else { return nil }
    return box
  }

  public var compositionOffset: CompositionOffsetBox? {
    guard case .compositionOffset(let box) = detail else { return nil }
    return box
  }

  public var sampleToChunk: SampleToChunkBox? {
    guard case .sampleToChunk(let box) = detail else { return nil }
    return box
  }

  public var chunkOffset: ChunkOffsetBox? {
    guard case .chunkOffset(let box) = detail else { return nil }
    return box
  }

  public var sampleSize: SampleSizeBox? {
    guard case .sampleSize(let box) = detail else { return nil }
    return box
  }

  public var compactSampleSize: CompactSampleSizeBox? {
    guard case .compactSampleSize(let box) = detail else { return nil }
    return box
  }

  public var syncSampleTable: SyncSampleTableBox? {
    guard case .syncSampleTable(let box) = detail else { return nil }
    return box
  }

  public var dataReference: DataReferenceBox? {
    guard case .dataReference(let box) = detail else { return nil }
    return box
  }

  public var metadataBox: MetadataBox? {
    guard case .metadata(let box) = detail else { return nil }
    return box
  }

  public var metadataKeyTable: MetadataKeyTableBox? {
    guard case .metadataKeyTable(let box) = detail else { return nil }
    return box
  }

  public var metadataItemList: MetadataItemListBox? {
    guard case .metadataItemList(let box) = detail else { return nil }
    return box
  }
}
