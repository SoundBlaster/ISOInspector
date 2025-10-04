//
//  BoxTypes.swift
//  ISOInspectorKit
//

import Foundation

public struct BoxHeader {
    public let fourcc: String
    public let size32: UInt32
    public let largesize64: UInt64?
    public let headerSize: UInt64
    public let startOffset: UInt64
    public let endOffset: UInt64
    public let uuid: UUID?
    // NOTE: No logic. Fields only.
}

public struct BoxNode {
    public let header: BoxHeader
    public var children: [BoxNode]
    public var warnings: [String]
    // public var payload: Payload? // TODO: add when specific boxes are modeled
    public init(header: BoxHeader, children: [BoxNode] = [], warnings: [String] = []) {
        self.header = header
        self.children = children
        self.warnings = warnings
    }
}
