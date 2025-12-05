import Foundation

extension ParseTree {
    public enum PlaceholderPlanner {
        public struct Requirement: Equatable, Sendable {
            public let childType: FourCharCode

            public init(childType: FourCharCode) { self.childType = childType }
        }

        private static let requirements: [FourCharCode: [Requirement]] = {
            var mapping: [FourCharCode: [Requirement]] = [:]
            if let minf = try? FourCharCode("minf"), let stbl = try? FourCharCode("stbl") {
                mapping[minf] = [Requirement(childType: stbl)]
            }
            if let traf = try? FourCharCode("traf"), let tfhd = try? FourCharCode("tfhd") {
                mapping[traf] = [Requirement(childType: tfhd)]
            }
            return mapping
        }()

        public static func missingRequirements(
            for parent: BoxHeader, existingChildTypes: Set<FourCharCode>
        ) -> [Requirement] {
            guard let expected = requirements[parent.type] else { return [] }
            return expected.filter { !existingChildTypes.contains($0.childType) }
        }

        public static func makeIssue(
            for requirement: Requirement, parent: BoxHeader, placeholder: BoxHeader
        ) -> ParseIssue {
            let message =
                "\(parent.identifierString) missing required child \(requirement.childType.rawValue)."
            let range = anchorRange(for: parent)
            let affected = [parent.startOffset, placeholder.startOffset]
            return ParseIssue(
                severity: .error, code: "structure.missing_child", message: message,
                byteRange: range, affectedNodeIDs: affected)
        }

        public static func metadata(for header: BoxHeader) -> BoxDescriptor? {
            BoxCatalog.shared.descriptor(for: header)
        }

        public static func anchorRange(for parent: BoxHeader) -> Range<Int64>? {
            if parent.payloadRange.isEmpty { return parent.range.isEmpty ? nil : parent.range }
            return parent.payloadRange
        }
    }
}
