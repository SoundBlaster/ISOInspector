//
//  MetadataItemValue.swift
//  ISOInspector
//
//  Created by Egor Merkushev on 11/29/25.
//  Copyright © 2025 ISOInspector. All rights reserved.
//

import Foundation

extension StructuredPayload {
    struct MetadataItemValue: Encodable {
        let kind: String
        let stringValue: String?
        let integerValue: Int64?
        let unsignedValue: UInt64?
        let booleanValue: Bool?
        let float32Value: Double?
        let float64Value: Double?
        let byteLength: Int?
        let rawType: UInt32
        let rawTypeHex: String
        let dataFormat: String?
        let locale: UInt32?
        let fixedPointValue: Double?
        let fixedPointRaw: Int32?
        let fixedPointFormat: String?

        init(value: ParsedBoxPayload.MetadataItemListBox.Entry.Value) {
            self.rawType = value.rawType
            self.rawTypeHex = String(format: "0x%06X", value.rawType)
            self.locale = value.locale == 0 ? nil : value.locale

            let mapped = MetadataItemValue.map(kind: value.kind)
            self.kind = mapped.kind
            self.stringValue = mapped.stringValue
            self.integerValue = mapped.integerValue
            self.unsignedValue = mapped.unsignedValue
            self.booleanValue = mapped.booleanValue
            self.float32Value = mapped.float32Value
            self.float64Value = mapped.float64Value
            self.byteLength = mapped.byteLength
            self.dataFormat = mapped.dataFormat
            self.fixedPointValue = mapped.fixedPointValue
            self.fixedPointRaw = mapped.fixedPointRaw
            self.fixedPointFormat = mapped.fixedPointFormat
        }

        private static func map(kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind)
            -> MappedValue
        {
            if let mapped = mapText(kind) { return mapped }
            if let mapped = mapInteger(kind) { return mapped }
            if let mapped = mapFloatingPoint(kind) { return mapped }
            if let mapped = mapBinary(kind) { return mapped }
            return MappedValue(kind: "unknown")
        }

        private static func mapText(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind)
            -> MappedValue?
        {
            switch kind {
            case .utf8(let string): return MappedValue(kind: "utf8", stringValue: string)
            case .utf16(let string): return MappedValue(kind: "utf16", stringValue: string)
            default: return nil
            }
        }

        private static func mapInteger(
            _ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind
        ) -> MappedValue? {
            switch kind {
            case .integer(let number): return MappedValue(kind: "integer", integerValue: number)
            case .unsignedInteger(let number):
                return MappedValue(kind: "unsigned_integer", unsignedValue: number)
            case .boolean(let flag): return MappedValue(kind: "boolean", booleanValue: flag)
            default: return nil
            }
        }

        private static func mapFloatingPoint(
            _ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind
        ) -> MappedValue? {
            switch kind {
            case .float32(let number):
                return MappedValue(kind: "float32", float32Value: Double(number))
            case .float64(let number): return MappedValue(kind: "float64", float64Value: number)
            default: return nil
            }
        }

        private static func mapBinary(_ kind: ParsedBoxPayload.MetadataItemListBox.Entry.Value.Kind)
            -> MappedValue?
        {
            switch kind {
            case .data(let format, let data):
                return MappedValue(
                    kind: "data", byteLength: data.count, dataFormat: format.rawValue)
            case .bytes(let data): return MappedValue(kind: "bytes", byteLength: data.count)
            case .signedFixedPoint(let point):
                return MappedValue(
                    kind: "signed_fixed_point", fixedPointValue: point.value,
                    fixedPointRaw: point.rawValue, fixedPointFormat: point.format.rawValue)
            default: return nil
            }
        }

        private struct MappedValue {
            let kind: String
            let stringValue: String?
            let integerValue: Int64?
            let unsignedValue: UInt64?
            let booleanValue: Bool?
            let float32Value: Double?
            let float64Value: Double?
            let byteLength: Int?
            let dataFormat: String?
            let fixedPointValue: Double?
            let fixedPointRaw: Int32?
            let fixedPointFormat: String?

            init(
                kind: String, stringValue: String? = nil, integerValue: Int64? = nil,
                unsignedValue: UInt64? = nil, booleanValue: Bool? = nil,
                float32Value: Double? = nil, float64Value: Double? = nil, byteLength: Int? = nil,
                dataFormat: String? = nil, fixedPointValue: Double? = nil,
                fixedPointRaw: Int32? = nil, fixedPointFormat: String? = nil
            ) {
                self.kind = kind
                self.stringValue = stringValue
                self.integerValue = integerValue
                self.unsignedValue = unsignedValue
                self.booleanValue = booleanValue
                self.float32Value = float32Value
                self.float64Value = float64Value
                self.byteLength = byteLength
                self.dataFormat = dataFormat
                self.fixedPointValue = fixedPointValue
                self.fixedPointRaw = fixedPointRaw
                self.fixedPointFormat = fixedPointFormat
            }
        }

        private enum CodingKeys: String, CodingKey {
            case kind
            case stringValue = "string_value"
            case integerValue = "integer_value"
            case unsignedValue = "unsigned_value"
            case booleanValue = "boolean_value"
            case float32Value = "float32_value"
            case float64Value = "float64_value"
            case byteLength = "byte_length"
            case rawType = "raw_type"
            case rawTypeHex = "raw_type_hex"
            case dataFormat = "data_format"
            case locale
            case fixedPointValue = "fixed_point_value"
            case fixedPointRaw = "fixed_point_raw"
            case fixedPointFormat = "fixed_point_format"
        }
    }
}
