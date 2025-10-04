//
//  Errors.swift
//  ISOInspectorKit
//

import Foundation

public enum IOError: Error {
    case fileNotFound
    case readFailed
    case outOfBounds
}

public enum ParseError: Error {
    case invalidHeader
    case invalidSize
    case overflow
    case unsupported
}

public enum ValidationError: Error {
    case hierarchyViolation
    case overlap
    case noProgress
}
