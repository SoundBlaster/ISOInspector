import Foundation

extension BoxParserRegistry {
    enum DefaultParsers {
        static func registerAll(into registry: inout BoxParserRegistry) {
            if let ftyp = try? IIFourCharCode("ftyp") {
                registry.register(parser: fileType, for: ftyp)
            }
            if let mdat = try? IIFourCharCode("mdat") {
                registry.register(parser: mediaData, for: mdat)
            }
            if let free = try? IIFourCharCode("free") {
                registry.register(parser: padding, for: free)
            }
            if let skip = try? IIFourCharCode("skip") {
                registry.register(parser: padding, for: skip)
            }
            if let mvhd = try? IIFourCharCode("mvhd") {
                registry.register(parser: movieHeader, for: mvhd)
            }
            if let mvex = try? IIFourCharCode("mvex") {
                registry.register(parser: movieExtends, for: mvex)
            }
            if let moof = try? IIFourCharCode("moof") {
                registry.register(parser: movieFragment, for: moof)
            }
            if let mfra = try? IIFourCharCode("mfra") {
                registry.register(parser: movieFragmentRandomAccess, for: mfra)
            }
            if let tkhd = try? IIFourCharCode("tkhd") {
                registry.register(parser: trackHeader, for: tkhd)
            }
            if let trex = try? IIFourCharCode("trex") {
                registry.register(parser: trackExtends, for: trex)
            }
            if let mfhd = try? IIFourCharCode("mfhd") {
                registry.register(parser: movieFragmentHeader, for: mfhd)
            }
            if let tfhd = try? IIFourCharCode("tfhd") {
                registry.register(parser: trackFragmentHeader, for: tfhd)
            }
            if let tfdt = try? IIFourCharCode("tfdt") {
                registry.register(parser: trackFragmentDecodeTime, for: tfdt)
            }
            if let trun = try? IIFourCharCode("trun") {
                registry.register(parser: trackRun, for: trun)
            }
            if let traf = try? IIFourCharCode("traf") {
                registry.register(parser: trackFragment, for: traf)
            }
            if let senc = try? IIFourCharCode("senc") {
                registry.register(parser: sampleEncryption, for: senc)
            }
            if let saio = try? IIFourCharCode("saio") {
                registry.register(parser: sampleAuxInfoOffsets, for: saio)
            }
            if let saiz = try? IIFourCharCode("saiz") {
                registry.register(parser: sampleAuxInfoSizes, for: saiz)
            }
            if let tfra = try? IIFourCharCode("tfra") {
                registry.register(parser: trackFragmentRandomAccess, for: tfra)
            }
            if let mfro = try? IIFourCharCode("mfro") {
                registry.register(parser: movieFragmentRandomAccessOffset, for: mfro)
            }
            if let mdhd = try? IIFourCharCode("mdhd") {
                registry.register(parser: mediaHeader, for: mdhd)
            }
            if let smhd = try? IIFourCharCode("smhd") {
                registry.register(parser: soundMediaHeader, for: smhd)
            }
            if let vmhd = try? IIFourCharCode("vmhd") {
                registry.register(parser: videoMediaHeader, for: vmhd)
            }
            if let elst = try? IIFourCharCode("elst") {
                registry.register(parser: editList, for: elst)
            }
            if let hdlr = try? IIFourCharCode("hdlr") {
                registry.register(parser: handlerReference, for: hdlr)
            }
            if let dinf = try? IIFourCharCode("dinf") {
                registry.register(parser: dataInformation, for: dinf)
            }
            if let dref = try? IIFourCharCode("dref") {
                registry.register(parser: dataReference, for: dref)
            }
            if let udta = try? IIFourCharCode("udta") {
                registry.register(parser: userData, for: udta)
            }
            if let meta = try? IIFourCharCode("meta") {
                registry.register(parser: metadata, for: meta)
            }
            if let keys = try? IIFourCharCode("keys") {
                registry.register(parser: metadataKeys, for: keys)
            }
            if let ilst = try? IIFourCharCode("ilst") {
                registry.register(parser: metadataItemList, for: ilst)
            }
            if let stsd = try? IIFourCharCode("stsd") {
                registry.register(parser: sampleDescription, for: stsd)
            }
            if let stts = try? IIFourCharCode("stts") {
                registry.register(parser: decodingTimeToSample, for: stts)
            }
            if let ctts = try? IIFourCharCode("ctts") {
                registry.register(parser: compositionOffset, for: ctts)
            }
            if let stsc = try? IIFourCharCode("stsc") {
                registry.register(parser: sampleToChunk, for: stsc)
            }
            if let stsz = try? IIFourCharCode("stsz") {
                registry.register(parser: sampleSize, for: stsz)
            }
            if let stz2 = try? IIFourCharCode("stz2") {
                registry.register(parser: compactSampleSize, for: stz2)
            }
            if let stco = try? IIFourCharCode("stco") {
                registry.register(parser: chunkOffset32, for: stco)
            }
            if let co64 = try? IIFourCharCode("co64") {
                registry.register(parser: chunkOffset64, for: co64)
            }
            if let stss = try? IIFourCharCode("stss") {
                registry.register(parser: syncSampleTable, for: stss)
            }
        }
    }
}
