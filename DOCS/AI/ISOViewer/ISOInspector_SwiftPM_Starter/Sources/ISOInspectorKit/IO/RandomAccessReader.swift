//
//  RandomAccessReader.swift
//  ISOInspectorKit
//
//  NOTE: Declarations only. Do not implement here.
//

import Foundation

public protocol RandomAccessReader {
    var length: Int64 { get }
    func read(at offset: Int64, count: Int) throws -> Data
    // TODO: BE helpers (readU16BE, readU24BE, readU32BE, readU64BE, readFourCC)
}
