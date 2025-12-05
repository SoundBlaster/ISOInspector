//
//  PaddingDetail.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Foundation

extension StructuredPayload {
    struct PaddingDetail: Encodable {
        let type: String
        let headerStartOffset: Int64
        let headerEndOffset: Int64
        let payloadStartOffset: Int64
        let payloadEndOffset: Int64
        let payloadLength: Int64
        let totalSize: Int64

        init(box: ParsedBoxPayload.PaddingBox) {
            self.type = box.type.rawValue
            self.headerStartOffset = box.headerStartOffset
            self.headerEndOffset = box.headerEndOffset
            self.payloadStartOffset = box.payloadStartOffset
            self.payloadEndOffset = box.payloadEndOffset
            self.payloadLength = box.payloadLength
            self.totalSize = box.totalSize
        }
    }
}
