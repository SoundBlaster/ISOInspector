//
//  MetadataItemIdentifier.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//


import Foundation

extension StructuredPayload {
    struct MetadataItemIdentifier: Encodable {
        let kind: String
        let display: String
        let rawValue: UInt32
        let rawValueHex: String
        let keyIndex: UInt32?
        
        init(identifier: ParsedBoxPayload.MetadataItemListBox.Entry.Identifier) {
            switch identifier {
            case .fourCC(let raw, let display):
                self.kind = "fourcc"
                self.rawValue = raw
                self.rawValueHex = String(format: "0x%08X", raw)
                self.keyIndex = nil
                if display.isEmpty {
                    self.display = self.rawValueHex
                } else {
                    self.display = display
                }
            case .keyIndex(let index):
                self.kind = "key_index"
                self.rawValue = index
                self.rawValueHex = String(format: "0x%08X", index)
                self.keyIndex = index
                self.display = "key[\(index)]"
            case .raw(let value):
                self.kind = "raw"
                self.rawValue = value
                self.rawValueHex = String(format: "0x%08X", value)
                self.keyIndex = nil
                self.display = self.rawValueHex
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case kind
            case display
            case rawValue = "raw_value"
            case rawValueHex = "raw_value_hex"
            case keyIndex = "key_index"
        }
    }
}