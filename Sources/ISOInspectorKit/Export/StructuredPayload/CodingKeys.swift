import Foundation

extension StructuredPayload {
    init(
        fileType: FileTypeDetail? = nil, mediaData: MediaDataDetail? = nil,
        padding: PaddingDetail? = nil, movieHeader: MovieHeaderDetail? = nil,
        trackHeader: TrackHeaderDetail? = nil, trackExtends: TrackExtendsDetail? = nil,
        trackFragmentHeader: TrackFragmentHeaderDetail? = nil,
        trackFragmentDecodeTime: TrackFragmentDecodeTimeDetail? = nil,
        trackRun: TrackRunDetail? = nil, trackFragment: TrackFragmentDetail? = nil,
        movieFragmentHeader: MovieFragmentHeaderDetail? = nil,
        movieFragmentRandomAccess: MovieFragmentRandomAccessDetail? = nil,
        trackFragmentRandomAccess: TrackFragmentRandomAccessDetail? = nil,
        movieFragmentRandomAccessOffset: MovieFragmentRandomAccessOffsetDetail? = nil,
        sampleEncryption: SampleEncryptionDetail? = nil,
        sampleAuxInfoOffsets: SampleAuxInfoOffsetsDetail? = nil,
        sampleAuxInfoSizes: SampleAuxInfoSizesDetail? = nil,
        soundMediaHeader: SoundMediaHeaderDetail? = nil,
        videoMediaHeader: VideoMediaHeaderDetail? = nil, editList: EditListDetail? = nil,
        timeToSample: TimeToSampleDetail? = nil, compositionOffset: CompositionOffsetDetail? = nil,
        sampleToChunk: SampleToChunkDetail? = nil, chunkOffset: ChunkOffsetDetail? = nil,
        sampleSize: SampleSizeDetail? = nil, compactSampleSize: CompactSampleSizeDetail? = nil,
        syncSampleTable: SyncSampleTableDetail? = nil, dataReference: DataReferenceDetail? = nil,
        metadata: MetadataDetail? = nil, metadataKeys: MetadataKeyTableDetail? = nil,
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
