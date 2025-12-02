import Foundation

/// Protocol defining a validation rule for ISO base media file box structures.
///
/// Each rule inspects parse events and returns validation issues when violations
/// are detected. Rules are stateless (struct) or maintain mutable state (class)
/// marked `@unchecked Sendable` when necessary for tracking across events.
protocol BoxValidationRule: Sendable {
    /// Validates a parse event and returns any issues found.
    ///
    /// - Parameters:
    ///   - event: The parse event to validate
    ///   - reader: Random access reader for inspecting box payload data
    /// - Returns: Array of validation issues, empty if no violations found
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue]
}

// MARK: - Shared Utilities

extension Range where Bound == Int64 { var count: Int { Int(upperBound - lowerBound) } }

extension UInt32 {
    func paddedHex(length: Int) -> String {
        let value = String(self, radix: 16, uppercase: true)
        guard value.count < length else { return value }
        return String(repeating: "0", count: length - value.count) + value
    }
}
