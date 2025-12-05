import Foundation

/// Validates version and flags fields in Full Boxes.
///
/// This rule verifies that boxes with version/flags metadata (Full Boxes as defined
/// in ISO/IEC 14496-12) contain the expected version and flags values in their payload.
/// The rule reads the first 4 bytes of the payload to extract:
/// - Byte 0: Version (8 bits)
/// - Bytes 1-3: Flags (24 bits)
///
/// ## Rule ID
/// - **VR-003**: Version/flags validation
///
/// ## Severity
/// - **Warning**: Version or flags mismatch, or payload too small/truncated
///
/// ## Example Violations
/// - A box declares version 1 in metadata but has version 0 in payload
/// - Flags mismatch between declared and actual values
/// - Payload is smaller than 4 bytes when version/flags are expected
struct VersionFlagsRule: BoxValidationRule {
    // swiftlint:disable:next function_body_length
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case .willStartBox(let header, _) = event.kind else { return [] }
        guard let descriptor = event.metadata else { return [] }
        guard descriptor.version != nil || descriptor.flags != nil else { return [] }

        let payloadRange = header.payloadRange
        guard payloadRange.count >= 4 else {
            return [
                ValidationIssue(
                    ruleID: "VR-003",
                    message:
                        "\(header.identifierString) payload too small for version/flags check (expected 4 bytes, found \(payloadRange.count)).",
                    severity: .warning)
            ]
        }

        do {
            let data = try reader.read(at: payloadRange.lowerBound, count: 4)
            guard data.count == 4 else {
                return [
                    ValidationIssue(
                        ruleID: "VR-003",
                        message:
                            "\(header.identifierString) payload truncated during version/flags check (expected 4 bytes, found \(data.count)).",
                        severity: .warning)
                ]
            }

            let actualVersion = Int(data[0])
            let actualFlags = data[1...3].reduce(UInt32(0)) { partial, byte in
                (partial << 8) | UInt32(byte)
            }

            var issues: [ValidationIssue] = []
            if let expectedVersion = descriptor.version, expectedVersion != actualVersion {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-003",
                        message:
                            "\(header.identifierString) version mismatch: expected \(expectedVersion) but found \(actualVersion).",
                        severity: .warning))
            }
            if let expectedFlags = descriptor.flags, expectedFlags != actualFlags {
                issues.append(
                    ValidationIssue(
                        ruleID: "VR-003",
                        message:
                            "\(header.identifierString) flags mismatch: expected 0x\(expectedFlags.paddedHex(length: 6)) but found 0x\(actualFlags.paddedHex(length: 6))",
                        severity: .warning))
            }
            return issues
        } catch {
            return [
                ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) failed to read version/flags: \(error)",
                    severity: .warning)
            ]
        }
    }
}
