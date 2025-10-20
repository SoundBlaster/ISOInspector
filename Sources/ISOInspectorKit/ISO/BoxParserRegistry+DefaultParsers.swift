import Foundation

extension BoxParserRegistry {
    enum DefaultParsers {
        static func registerAll(into registry: inout BoxParserRegistry) {
            if let ftyp = try? FourCharCode("ftyp") {
                registry.register(parser: fileType, for: ftyp)
            }
            if let mvhd = try? FourCharCode("mvhd") {
                registry.register(parser: movieHeader, for: mvhd)
            }
            if let tkhd = try? FourCharCode("tkhd") {
                registry.register(parser: trackHeader, for: tkhd)
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
