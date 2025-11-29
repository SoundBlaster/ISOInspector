import Foundation

struct StructuredPayload: Encodable {
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
