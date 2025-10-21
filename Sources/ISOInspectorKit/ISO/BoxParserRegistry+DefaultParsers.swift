import Foundation

extension BoxParserRegistry {
    enum DefaultParsers {
        static func registerAll(into registry: inout BoxParserRegistry) {
            if let ftyp = try? FourCharCode("ftyp") {
                registry.register(parser: fileType, for: ftyp)
            }
            if let mdat = try? FourCharCode("mdat") {
                registry.register(parser: mediaData, for: mdat)
            }
            if let free = try? FourCharCode("free") {
                registry.register(parser: padding, for: free)
            }
            if let skip = try? FourCharCode("skip") {
                registry.register(parser: padding, for: skip)
            }
            if let mvhd = try? FourCharCode("mvhd") {
                registry.register(parser: movieHeader, for: mvhd)
            }
            if let mvex = try? FourCharCode("mvex") {
                registry.register(parser: movieExtends, for: mvex)
            }
            if let moof = try? FourCharCode("moof") {
                registry.register(parser: movieFragment, for: moof)
            }
            if let mfra = try? FourCharCode("mfra") {
                registry.register(parser: movieFragmentRandomAccess, for: mfra)
            }
            if let tkhd = try? FourCharCode("tkhd") {
                registry.register(parser: trackHeader, for: tkhd)
            }
            if let trex = try? FourCharCode("trex") {
                registry.register(parser: trackExtends, for: trex)
            }
            if let mfhd = try? FourCharCode("mfhd") {
                registry.register(parser: movieFragmentHeader, for: mfhd)
            }
            if let tfhd = try? FourCharCode("tfhd") {
                registry.register(parser: trackFragmentHeader, for: tfhd)
            }
            if let tfdt = try? FourCharCode("tfdt") {
                registry.register(parser: trackFragmentDecodeTime, for: tfdt)
            }
            if let trun = try? FourCharCode("trun") {
                registry.register(parser: trackRun, for: trun)
            }
            if let traf = try? FourCharCode("traf") {
                registry.register(parser: trackFragment, for: traf)
            }
            if let tfra = try? FourCharCode("tfra") {
                registry.register(parser: trackFragmentRandomAccess, for: tfra)
            }
            if let mfro = try? FourCharCode("mfro") {
                registry.register(parser: movieFragmentRandomAccessOffset, for: mfro)
            }
            if let mdhd = try? FourCharCode("mdhd") {
                registry.register(parser: mediaHeader, for: mdhd)
            }
            if let smhd = try? FourCharCode("smhd") {
                registry.register(parser: soundMediaHeader, for: smhd)
            }
            if let vmhd = try? FourCharCode("vmhd") {
                registry.register(parser: videoMediaHeader, for: vmhd)
            }
            if let elst = try? FourCharCode("elst") {
                registry.register(parser: editList, for: elst)
            }
            if let hdlr = try? FourCharCode("hdlr") {
                registry.register(parser: handlerReference, for: hdlr)
            }
            if let dinf = try? FourCharCode("dinf") {
                registry.register(parser: dataInformation, for: dinf)
            }
            if let dref = try? FourCharCode("dref") {
                registry.register(parser: dataReference, for: dref)
            }
            if let udta = try? FourCharCode("udta") {
                registry.register(parser: userData, for: udta)
            }
            if let meta = try? FourCharCode("meta") {
                registry.register(parser: metadata, for: meta)
            }
            if let keys = try? FourCharCode("keys") {
                registry.register(parser: metadataKeys, for: keys)
            }
            if let ilst = try? FourCharCode("ilst") {
                registry.register(parser: metadataItemList, for: ilst)
            }
            if let stsd = try? FourCharCode("stsd") {
                registry.register(parser: sampleDescription, for: stsd)
            }
            if let stsc = try? FourCharCode("stsc") {
                registry.register(parser: sampleToChunk, for: stsc)
            }
            if let stsz = try? FourCharCode("stsz") {
                registry.register(parser: sampleSize, for: stsz)
            }
            if let stz2 = try? FourCharCode("stz2") {
                registry.register(parser: compactSampleSize, for: stz2)
            }
            if let stco = try? FourCharCode("stco") {
                registry.register(parser: chunkOffset32, for: stco)
            }
            if let co64 = try? FourCharCode("co64") {
                registry.register(parser: chunkOffset64, for: co64)
            }
            if let stss = try? FourCharCode("stss") {
                registry.register(parser: syncSampleTable, for: stss)
            }
        }
    }
}
