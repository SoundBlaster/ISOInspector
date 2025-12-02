//
//  MetadataItemListDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Foundation

extension StructuredPayload {
    struct MetadataItemListDetail: Encodable {
        let handlerType: String?
        let entryCount: Int
        let entries: [MetadataItemEntry]

        init(box: ParsedBoxPayload.MetadataItemListBox) {
            self.handlerType = box.handlerType?.rawValue
            self.entries = box.entries.enumerated().map {
                MetadataItemEntry(entry: $0.element, index: $0.offset + 1)
            }
            self.entryCount = entries.count
        }

        private enum CodingKeys: String, CodingKey {
            case handlerType = "handler_type"
            case entryCount = "entry_count"
            case entries
        }
    }
}
