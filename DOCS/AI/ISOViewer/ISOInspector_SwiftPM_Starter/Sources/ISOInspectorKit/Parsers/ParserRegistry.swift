//
//  ParserRegistry.swift
//  ISOInspectorKit
//

import Foundation

public enum FourCC: String {
    case ftyp, moov, mdat, free, skip, uuid
    case mvhd, trak, tkhd, mdia, mdhd, hdlr, minf, stbl
    case stsd, stts, ctts, stsc, stsz, stz2, stco, co64, stss
    case dinf, dref, smhd, vmhd, edts, elst
    case mvex, trex, moof, mfhd, traf, tfhd, tfdt, trun
    case sidx, mfra, tfra, mfro
    case avcC, hvcC, esds
}

public struct BoxParserRegistry {
    // map: fourcc -> parser placeholder name
    public static let known: Set<String> = [
        "ftyp", "moov", "mdat", "free", "skip", "uuid",
        "mvhd", "trak", "tkhd", "mdia", "mdhd", "hdlr", "minf", "stbl",
        "stsd", "stts", "ctts", "stsc", "stsz", "stz2", "stco", "co64", "stss",
        "dinf", "dref", "smhd", "vmhd", "edts", "elst",
        "mvex", "trex", "moof", "mfhd", "traf", "tfhd", "tfdt", "trun",
        "sidx", "mfra", "tfra", "mfro",
        "avcC", "hvcC", "esds"
    ]
}
