//
//  MetadataItemEntry.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//


import Foundation

extension StructuredPayload {
    struct MetadataItemEntry: Encodable {
        let index: Int
        let identifier: MetadataItemIdentifier
        let namespace: String?
        let name: String?
        let values: [MetadataItemValue]
        
        init(entry: ParsedBoxPayload.MetadataItemListBox.Entry, index: Int) {
            self.index = index
            self.identifier = MetadataItemIdentifier(identifier: entry.identifier)
            self.namespace = entry.namespace
            self.name = entry.name
            self.values = entry.values.map(MetadataItemValue.init)
        }
        
        private enum CodingKeys: String, CodingKey {
            case index
            case identifier
            case namespace
            case name
            case values
        }
    }
}