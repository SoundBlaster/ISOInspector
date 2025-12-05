//
//  DataReferenceDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Foundation

extension StructuredPayload {
    struct DataReferenceDetail: Encodable {
        struct Entry: Encodable {
            let index: Int
            let type: String
            let version: Int
            let flags: UInt32
            let selfContained: Bool
            let url: String?
            let urn: URN?
            let payloadLength: Int?

            init(entry: ParsedBoxPayload.DataReferenceBox.Entry) {
                self.index = Int(entry.index)
                self.type = entry.type.rawValue
                self.version = Int(entry.version)
                self.flags = entry.flags
                self.selfContained = (entry.flags & 0x000001) != 0

                let payloadLengthValue =
                    entry.payloadRange.map { Int($0.upperBound - $0.lowerBound) } ?? 0

                switch entry.location {
                case .selfContained:
                    self.url = nil
                    self.urn = nil
                    self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                case .url(let string):
                    self.url = string
                    self.urn = nil
                    self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                case .urn(let name, let location):
                    self.url = nil
                    self.urn = URN(name: name, location: location)
                    self.payloadLength = payloadLengthValue > 0 ? payloadLengthValue : nil
                case .data(let data):
                    self.url = nil
                    self.urn = nil
                    if payloadLengthValue > 0 {
                        self.payloadLength = payloadLengthValue
                    } else if !data.isEmpty {
                        self.payloadLength = data.count
                    } else {
                        self.payloadLength = nil
                    }
                case .empty:
                    self.url = nil
                    self.urn = nil
                    self.payloadLength = nil
                }
            }

            private enum CodingKeys: String, CodingKey {
                case index
                case type
                case version
                case flags
                case selfContained = "self_contained"
                case url
                case urn
                case payloadLength = "payload_length"
            }
        }

        struct URN: Encodable {
            let name: String?
            let location: String?
        }

        let version: Int
        let flags: UInt32
        let entryCount: Int
        let entries: [Entry]

        init(box: ParsedBoxPayload.DataReferenceBox) {
            self.version = Int(box.version)
            self.flags = box.flags
            self.entryCount = Int(box.entryCount)
            self.entries = box.entries.map { Entry(entry: $0) }
        }
    }
}
