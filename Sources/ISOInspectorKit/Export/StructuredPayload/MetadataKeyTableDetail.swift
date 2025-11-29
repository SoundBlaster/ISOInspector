//
//  MetadataKeyTableDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//


import Foundation

extension StructuredPayload {
    struct MetadataKeyTableDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let namespace: String
            let name: String
        }
        
        let version: UInt8
        let flags: UInt32
        let entryCount: Int
        let entries: [Entry]
        
        init(box: ParsedBoxPayload.MetadataKeyTableBox) {
            self.version = box.version
            self.flags = box.flags
            self.entries = box.entries.map {
                Entry(index: $0.index, namespace: $0.namespace, name: $0.name)
            }
            self.entryCount = entries.count
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entryCount = "entry_count"
            case entries
        }
    }
}