//
//  SampleEncryptionDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//


import Foundation

extension StructuredPayload {
    struct SampleEncryptionDetail: Encodable {
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
}
