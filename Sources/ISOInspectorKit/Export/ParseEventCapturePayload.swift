import Foundation

struct ParseEventCapturePayload: Codable {
    let version: Int
    let events: [Event]

    init(events: [ParseEvent]) {
        self.version = 1
        self.events = events.map(Event.init)
    }

    func parseEvents() throws -> [ParseEvent] {
        try events.map { try $0.makeEvent() }
    }

    struct Event: Codable {
        enum Kind: String, Codable {
            case willStart
            case didFinish
        }

        let kind: Kind
        let header: Header
        let depth: Int
        let offset: Int64
        let metadata: Metadata?
        let validationIssues: [Issue]

        init(event: ParseEvent) {
            switch event.kind {
            case let .willStartBox(header, depth):
                self.kind = .willStart
                self.header = Header(header: header)
                self.depth = depth
            case let .didFinishBox(header, depth):
                self.kind = .didFinish
                self.header = Header(header: header)
                self.depth = depth
            }
            self.offset = event.offset
            self.metadata = event.metadata.map(Metadata.init)
            self.validationIssues = event.validationIssues.map(Issue.init)
        }

        func makeEvent() throws -> ParseEvent {
            let header = try self.header.makeHeader()
            let metadata = try self.metadata?.makeDescriptor()
            let issues = validationIssues.map { $0.makeIssue() }
            switch kind {
            case .willStart:
                return ParseEvent(
                    kind: .willStartBox(header: header, depth: depth),
                    offset: offset,
                    metadata: metadata,
                    validationIssues: issues
                )
            case .didFinish:
                return ParseEvent(
                    kind: .didFinishBox(header: header, depth: depth),
                    offset: offset,
                    metadata: metadata,
                    validationIssues: issues
                )
            }
        }
    }

    struct Header: Codable {
        let type: String
        let uuid: UUID?
        let totalSize: Int64
        let headerSize: Int64
        let payloadStart: Int64
        let payloadEnd: Int64
        let rangeStart: Int64
        let rangeEnd: Int64

        init(header: BoxHeader) {
            self.type = header.type.rawValue
            self.uuid = header.uuid
            self.totalSize = header.totalSize
            self.headerSize = header.headerSize
            self.payloadStart = header.payloadRange.lowerBound
            self.payloadEnd = header.payloadRange.upperBound
            self.rangeStart = header.range.lowerBound
            self.rangeEnd = header.range.upperBound
        }

        func makeHeader() throws -> BoxHeader {
            do {
                let fourcc = try FourCharCode(type)
                return BoxHeader(
                    type: fourcc,
                    totalSize: totalSize,
                    headerSize: headerSize,
                    payloadRange: payloadStart..<payloadEnd,
                    range: rangeStart..<rangeEnd,
                    uuid: uuid
                )
            } catch {
                throw ParseEventCaptureDecodingError.invalidFourCharCode(type)
            }
        }
    }

    struct Metadata: Codable {
        let type: String
        let uuid: UUID?
        let name: String
        let summary: String
        let category: String?
        let specification: String?
        let version: Int?
        let flags: UInt32?

        init(descriptor: BoxDescriptor) {
            self.type = descriptor.identifier.type.rawValue
            self.uuid = descriptor.identifier.extendedType
            self.name = descriptor.name
            self.summary = descriptor.summary
            self.category = descriptor.category
            self.specification = descriptor.specification
            self.version = descriptor.version
            self.flags = descriptor.flags
        }

        func makeDescriptor() throws -> BoxDescriptor {
            do {
                let fourcc = try FourCharCode(type)
                let identifier = BoxDescriptor.Identifier(type: fourcc, extendedType: uuid)
                return BoxDescriptor(
                    identifier: identifier,
                    name: name,
                    summary: summary,
                    category: category,
                    specification: specification,
                    version: version,
                    flags: flags
                )
            } catch {
                throw ParseEventCaptureDecodingError.invalidFourCharCode(type)
            }
        }
    }

    struct Issue: Codable {
        let ruleID: String
        let message: String
        let severity: String

        init(issue: ValidationIssue) {
            self.ruleID = issue.ruleID
            self.message = issue.message
            self.severity = issue.severity.rawValue
        }

        func makeIssue() -> ValidationIssue {
            ValidationIssue(
                ruleID: ruleID,
                message: message,
                severity: ValidationIssue.Severity(rawValue: severity) ?? .info
            )
        }
    }
}
