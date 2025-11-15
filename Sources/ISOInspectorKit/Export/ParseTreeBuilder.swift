import Foundation

public struct ParseTreeBuilder {
  private var rootNodes: [MutableNode] = []
  private var stack: [MutableNode] = []
  private var aggregatedIssues: [ValidationIssue] = []
  private var placeholderIDGenerator = ParseTreePlaceholderIDGenerator()

  public init() {}

  public mutating func consume(_ event: ParseEvent) {
    aggregatedIssues.append(contentsOf: event.validationIssues)

    switch event.kind {
    case .willStartBox(let header, let depth):
      let node = MutableNode(
        header: header,
        metadata: event.metadata,
        payload: event.payload,
        validationIssues: event.validationIssues,
        depth: depth
      )
      if !event.issues.isEmpty {
        node.issues = event.issues
        if Self.containsGuardIssues(event.issues) {
          node.status = .partial
        }
      }
      if let parent = stack.last {
        parent.children.append(node)
      } else {
        rootNodes.append(node)
      }
      stack.append(node)

    case .didFinishBox(let header, _):
      guard let current = stack.last else {
        return
      }

      if current.header != header {
        while let candidate = stack.last, candidate.header != header {
          _ = stack.popLast()
        }
      }

      guard let node = stack.popLast() else {
        return
      }

      if node.header == header {
        if node.metadata == nil || event.metadata != nil {
          node.metadata = event.metadata ?? node.metadata
        }
        if node.payload == nil || event.payload != nil {
          node.payload = event.payload ?? node.payload
        }
        if !event.validationIssues.isEmpty {
          node.validationIssues.append(contentsOf: event.validationIssues)
        }
        if !event.issues.isEmpty {
          node.issues = event.issues
          if Self.containsGuardIssues(event.issues) {
            node.status = .partial
          }
        }
        synthesizePlaceholdersIfNeeded(for: node)
      } else {
        stack.append(node)
      }
    }
  }

  public func makeTree() -> ParseTree {
    ParseTree(nodes: rootNodes.map { $0.snapshot() }, validationIssues: aggregatedIssues)
  }
}

extension ParseTreeBuilder {
  fileprivate static func containsGuardIssues(_ issues: [ParseIssue]) -> Bool {
    issues.contains { $0.code.hasPrefix("guard.") }
  }
}

private final class MutableNode {
  let header: BoxHeader
  var metadata: BoxDescriptor?
  var payload: ParsedBoxPayload?
  var validationIssues: [ValidationIssue]
  var issues: [ParseIssue]
  var status: BoxNode.Status
  var children: [MutableNode]
  let depth: Int

  init(
    header: BoxHeader,
    metadata: BoxDescriptor?,
    payload: ParsedBoxPayload?,
    validationIssues: [ValidationIssue],
    depth: Int
  ) {
    self.header = header
    self.metadata = metadata
    self.payload = payload
    self.validationIssues = validationIssues
    self.issues = []
    self.status = .valid
    self.children = []
    self.depth = depth
  }

  func snapshot() -> ParseTreeNode {
    ParseTreeNode(
      header: header,
      metadata: metadata,
      payload: payload,
      validationIssues: validationIssues,
      issues: issues,
      status: status,
      children: children.map { $0.snapshot() }
    )
  }
}

extension ParseTreeBuilder {
  fileprivate mutating func synthesizePlaceholdersIfNeeded(for node: MutableNode) {
    var existingTypes = Set(node.children.map { $0.header.type })
    let requirements = ParseTreePlaceholderPlanner.missingRequirements(
      for: node.header,
      existingChildTypes: existingTypes
    )
    guard !requirements.isEmpty else { return }

    if node.status != .corrupt {
      node.status = .partial
    }

    for requirement in requirements {
      existingTypes.insert(requirement.childType)
      let startOffset = placeholderIDGenerator.next()
      let placeholderRange = startOffset..<startOffset
      let placeholderHeader = BoxHeader(
        type: requirement.childType,
        totalSize: 0,
        headerSize: 0,
        payloadRange: placeholderRange,
        range: placeholderRange,
        uuid: nil
      )
      let placeholderNode = MutableNode(
        header: placeholderHeader,
        metadata: ParseTreePlaceholderPlanner.metadata(for: placeholderHeader),
        payload: nil,
        validationIssues: [],
        depth: node.depth + 1
      )
      placeholderNode.status = .corrupt
      let issue = ParseTreePlaceholderPlanner.makeIssue(
        for: requirement,
        parent: node.header,
        placeholder: placeholderHeader
      )
      placeholderNode.issues = [issue]
      node.issues.append(issue)
      node.children.append(placeholderNode)
    }
  }
}
