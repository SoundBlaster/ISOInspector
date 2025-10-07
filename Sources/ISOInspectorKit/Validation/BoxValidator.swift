import Foundation

protocol BoxValidationRule: Sendable {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue]
}

struct BoxValidator: Sendable {
    private let rules: [any BoxValidationRule]

    init(rules: [any BoxValidationRule] = BoxValidator.defaultRules) {
        self.rules = rules
    }

    func annotate(event: ParseEvent, reader: RandomAccessReader) -> ParseEvent {
        let issues = rules.flatMap { $0.issues(for: event, reader: reader) }
        guard !issues.isEmpty else {
            return event
        }
        return ParseEvent(
            kind: event.kind,
            offset: event.offset,
            metadata: event.metadata,
            validationIssues: issues
        )
    }
}

private extension BoxValidator {
    static var defaultRules: [any BoxValidationRule] {
        [
            StructuralSizeRule(),
            ContainerBoundaryRule(),
            FileTypeOrderingRule(),
            MovieDataOrderingRule(),
            VersionFlagsRule(),
            UnknownBoxRule()
        ]
    }
}

private struct StructuralSizeRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        var issues: [ValidationIssue] = []
        if header.totalSize < header.headerSize {
            let message = "Box \(header.identifierString) declares total size \(header.totalSize) smaller than header length \(header.headerSize)."
            issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
        }

        if header.endOffset > reader.length {
            let message = "Box \(header.identifierString) extends beyond file length (declared end \(header.endOffset), file length \(reader.length))."
            issues.append(ValidationIssue(ruleID: "VR-001", message: message, severity: .error))
        }

        return issues
    }
}

private final class ContainerBoundaryRule: BoxValidationRule, @unchecked Sendable {
    private struct State {
        let header: BoxHeader
        var nextChildOffset: Int64
        var hasChildren: Bool
    }

    private var stack: [State] = []

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        switch event.kind {
        case let .willStartBox(header, depth):
            if stack.count > depth {
                stack.removeLast(stack.count - depth)
            }
            if stack.count < depth {
                let message = "Start event for \(header.identifierString) arrived at depth \(depth) without a matching parent context."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                stack.removeAll()
            }

            if let parentIndex = stack.indices.last {
                var parent = stack[parentIndex]
                if parent.nextChildOffset != header.startOffset {
                    let message = "Container \(parent.header.identifierString) expected child to start at offset \(parent.nextChildOffset) but found \(header.startOffset)."
                    issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                    parent.nextChildOffset = header.startOffset
                }
                parent.nextChildOffset = header.endOffset
                parent.hasChildren = true
                stack[parentIndex] = parent
            }

            let childState = State(
                header: header,
                nextChildOffset: header.payloadRange.lowerBound,
                hasChildren: false
            )
            stack.append(childState)

        case let .didFinishBox(header, depth):
            if stack.count > depth + 1 {
                stack.removeLast(stack.count - (depth + 1))
            }
            guard stack.count >= depth + 1 else {
                let message = "Finish event for \(header.identifierString) arrived at depth \(depth) without an opening start event."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                stack.removeAll()
                return issues
            }

            let state = stack.removeLast()
            if state.header != header {
                let message = "Container stack mismatch: expected to finish \(state.header.identifierString) but received \(header.identifierString)."
                issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
            }

            if state.hasChildren {
                let expectedEnd = state.header.payloadRange.upperBound
                if state.nextChildOffset != expectedEnd {
                    let message = "Container \(state.header.identifierString) expected to close at offset \(expectedEnd) but consumed \(state.nextChildOffset)."
                    issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
                }
            }

            if let parentIndex = stack.indices.last {
                var parent = stack[parentIndex]
                parent.nextChildOffset = header.endOffset
                parent.hasChildren = true
                stack[parentIndex] = parent
            }
        }

        return issues
    }
}

private struct VersionFlagsRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard let descriptor = event.metadata else { return [] }
        guard descriptor.version != nil || descriptor.flags != nil else { return [] }

        let payloadRange = header.payloadRange
        guard payloadRange.count >= 4 else {
            return [ValidationIssue(
                ruleID: "VR-003",
                message: "\(header.identifierString) payload too small for version/flags check (expected 4 bytes, found \(payloadRange.count)).",
                severity: .warning
            )]
        }

        do {
            let data = try reader.read(at: payloadRange.lowerBound, count: 4)
            guard data.count == 4 else {
                return [ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) payload truncated during version/flags check (expected 4 bytes, found \(data.count)).",
                    severity: .warning
                )]
            }

            let actualVersion = Int(data[0])
            let actualFlags = data[1...3].reduce(UInt32(0)) { partial, byte in
                (partial << 8) | UInt32(byte)
            }

            var issues: [ValidationIssue] = []
            if let expectedVersion = descriptor.version, expectedVersion != actualVersion {
                issues.append(ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) version mismatch: expected \(expectedVersion) but found \(actualVersion).",
                    severity: .warning
                ))
            }
            if let expectedFlags = descriptor.flags, expectedFlags != actualFlags {
                issues.append(ValidationIssue(
                    ruleID: "VR-003",
                    message: "\(header.identifierString) flags mismatch: expected 0x\(expectedFlags.paddedHex(length: 6)) but found 0x\(actualFlags.paddedHex(length: 6))",
                    severity: .warning
                ))
            }
            return issues
        } catch {
            return [ValidationIssue(
                ruleID: "VR-003",
                message: "\(header.identifierString) failed to read version/flags: \(error)",
                severity: .warning
            )]
        }
    }
}

private struct UnknownBoxRule: BoxValidationRule {
    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }
        guard event.metadata == nil else { return [] }
        return [ValidationIssue(
            ruleID: "VR-006",
            message: "Unknown box type \(header.identifierString) encountered; schedule catalog research.",
            severity: .info
        )]
    }
}

private final class FileTypeOrderingRule: BoxValidationRule, @unchecked Sendable {
    private var hasSeenFileType = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        let type = header.type.rawValue
        if type == "ftyp" {
            hasSeenFileType = true
            return []
        }

        guard !hasSeenFileType, Self.mediaBoxTypes.contains(type) else {
            return []
        }

        let message = "Encountered \(header.identifierString) before required file type box (ftyp)."
        return [ValidationIssue(ruleID: "VR-004", message: message, severity: .error)]
    }

    private static let mediaBoxTypes: Set<String> = Set([
        FourCharContainerCode.moov.rawValue,
        "mdat",
        FourCharContainerCode.trak.rawValue,
        FourCharContainerCode.mdia.rawValue,
        FourCharContainerCode.minf.rawValue,
        FourCharContainerCode.stbl.rawValue,
        FourCharContainerCode.moof.rawValue,
        FourCharContainerCode.traf.rawValue,
        FourCharContainerCode.mvex.rawValue,
        "sidx",
        "styp"
    ])
}

private final class MovieDataOrderingRule: BoxValidationRule, @unchecked Sendable {
    private var hasSeenMovieBox = false
    private var hasStreamingIndicator = false

    func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
        guard case let .willStartBox(header, _) = event.kind else { return [] }

        let type = header.type.rawValue

        if Self.streamingIndicatorTypes.contains(type) {
            hasStreamingIndicator = true
        }

        if type == FourCharContainerCode.moov.rawValue {
            hasSeenMovieBox = true
            return []
        }

        guard type == "mdat" else { return [] }
        guard !hasSeenMovieBox, !hasStreamingIndicator else { return [] }

        let message = "Movie data box (mdat) encountered before movie box (moov); ensure initialization metadata precedes media."
        return [ValidationIssue(ruleID: "VR-005", message: message, severity: .warning)]
    }

    private static let streamingIndicatorTypes: Set<String> = Set([
        FourCharContainerCode.moof.rawValue,
        FourCharContainerCode.mvex.rawValue,
        "sidx",
        "styp",
        "ssix",
        "prft"
    ])
}

private extension Range where Bound == Int64 {
    var count: Int { Int(upperBound - lowerBound) }
}

private extension UInt32 {
    func paddedHex(length: Int) -> String {
        let value = String(self, radix: 16, uppercase: true)
        guard value.count < length else { return value }
        return String(repeating: "0", count: length - value.count) + value
    }
}
