//
//  MetadataDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Foundation

extension StructuredPayload {
    struct MetadataDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let reserved: UInt32

        init(box: ParsedBoxPayload.MetadataBox) {
            self.version = box.version
            self.flags = box.flags
            self.reserved = box.reserved
        }
    }
}
