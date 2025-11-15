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
    let payload: Payload?
    let validationIssues: [Issue]
    let parseIssues: [ParseIssuePayload]

    init(event: ParseEvent) {
      switch event.kind {
      case .willStartBox(let header, let depth):
        self.kind = .willStart
        self.header = Header(header: header)
        self.depth = depth
      case .didFinishBox(let header, let depth):
        self.kind = .didFinish
        self.header = Header(header: header)
        self.depth = depth
      }
      self.offset = event.offset
      self.metadata = event.metadata.map(Metadata.init)
      self.payload = event.payload.map(Payload.init)
      self.validationIssues = event.validationIssues.map(Issue.init)
      self.parseIssues = event.issues.map(ParseIssuePayload.init)
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.kind = try container.decode(Kind.self, forKey: .kind)
      self.header = try container.decode(Header.self, forKey: .header)
      self.depth = try container.decode(Int.self, forKey: .depth)
      self.offset = try container.decode(Int64.self, forKey: .offset)
      self.metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata)
      self.payload = try container.decodeIfPresent(Payload.self, forKey: .payload)
      self.validationIssues =
        try container.decodeIfPresent([Issue].self, forKey: .validationIssues) ?? []
      self.parseIssues =
        try container.decodeIfPresent([ParseIssuePayload].self, forKey: .parseIssues) ?? []
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(kind, forKey: .kind)
      try container.encode(header, forKey: .header)
      try container.encode(depth, forKey: .depth)
      try container.encode(offset, forKey: .offset)
      try container.encodeIfPresent(metadata, forKey: .metadata)
      try container.encodeIfPresent(payload, forKey: .payload)
      try container.encode(validationIssues, forKey: .validationIssues)
      if !parseIssues.isEmpty {
        try container.encode(parseIssues, forKey: .parseIssues)
      }
    }

    func makeEvent() throws -> ParseEvent {
      let header = try self.header.makeHeader()
      let metadata = try self.metadata?.makeDescriptor()
      let payload = self.payload?.makePayload()
      let validationIssues = self.validationIssues.map { $0.makeIssue() }
      let parseIssues = self.parseIssues.map { $0.makeIssue() }
      switch kind {
      case .willStart:
        return ParseEvent(
          kind: .willStartBox(header: header, depth: depth),
          offset: offset,
          metadata: metadata,
          payload: payload,
          validationIssues: validationIssues,
          issues: parseIssues
        )
      case .didFinish:
        return ParseEvent(
          kind: .didFinishBox(header: header, depth: depth),
          offset: offset,
          metadata: metadata,
          payload: payload,
          validationIssues: validationIssues,
          issues: parseIssues
        )
      }
    }

    private enum CodingKeys: String, CodingKey {
      case kind
      case header
      case depth
      case offset
      case metadata
      case payload
      case validationIssues
      case parseIssues
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

  struct Payload: Codable {
    let fields: [Field]

    init(payload: ParsedBoxPayload) {
      self.fields = payload.fields.map(Field.init)
    }

    func makePayload() -> ParsedBoxPayload {
      ParsedBoxPayload(fields: fields.map { $0.makeField() })
    }
  }

  struct Field: Codable {
    let name: String
    let value: String
    let summary: String?
    let start: Int64?
    let end: Int64?

    init(field: ParsedBoxPayload.Field) {
      self.name = field.name
      self.value = field.value
      self.summary = field.description
      self.start = field.byteRange?.lowerBound
      self.end = field.byteRange?.upperBound
    }

    func makeField() -> ParsedBoxPayload.Field {
      let range: Range<Int64>?
      if let start, let end {
        range = start..<end
      } else {
        range = nil
      }
      return ParsedBoxPayload.Field(
        name: name,
        value: value,
        description: summary,
        byteRange: range
      )
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

  struct ParseIssuePayload: Codable {
    let severity: String
    let code: String
    let message: String
    let start: Int64?
    let end: Int64?
    let affectedNodeIDs: [Int64]

    init(issue: ParseIssue) {
      severity = issue.severity.rawValue
      code = issue.code
      message = issue.message
      if let range = issue.byteRange {
        start = range.lowerBound
        end = range.upperBound
      } else {
        start = nil
        end = nil
      }
      affectedNodeIDs = issue.affectedNodeIDs
    }

    func makeIssue() -> ParseIssue {
      let severityValue = ParseIssue.Severity(rawValue: severity) ?? .error
      let range: Range<Int64>?
      if let start, let end, end > start {
        range = start..<end
      } else {
        range = nil
      }
      return ParseIssue(
        severity: severityValue,
        code: code,
        message: message,
        byteRange: range,
        affectedNodeIDs: affectedNodeIDs
      )
    }
  }
}
