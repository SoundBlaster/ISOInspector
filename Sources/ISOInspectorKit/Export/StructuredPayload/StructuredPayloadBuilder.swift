import Foundation

extension StructuredPayload {
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
}
