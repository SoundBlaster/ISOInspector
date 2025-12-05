import Foundation

public struct ParseTreeBuilder {
    private var rootNodes: [MutableNode] = []
    private var stack: [MutableNode] = []
    private var aggregatedIssues: [ValidationIssue] = []
    var placeholderIDGenerator = ParseTree.PlaceholderIDGenerator()

    public init() {}

    fileprivate mutating func popStackUntil(header: BoxHeader) {
        while let candidate = stack.last, candidate.header != header { _ = stack.popLast() }
    }

    fileprivate func copyIssuesTo(node: ParseTreeBuilder.MutableNode, from event: ParseEvent) {
        node.issues = event.issues
        if event.issues.containsGuardIssues() { node.status = .partial }
    }

    fileprivate func appendIssuesTo(node: ParseTreeBuilder.MutableNode, from event: ParseEvent) {
        node.validationIssues.append(contentsOf: event.validationIssues)
    }

    fileprivate mutating func boxDidFinish(_ header: BoxHeader, _ event: ParseEvent) {
        guard let current = stack.last else { return }

        if current.header != header { popStackUntil(header: header) }

        guard let node = stack.popLast() else { return }

        guard node.header == header else {
            stack.append(node)
            return
        }

        if node.metadata == nil || event.metadata != nil {
            node.metadata = event.metadata ?? node.metadata
        }
        if node.payload == nil || event.payload != nil {
            node.payload = event.payload ?? node.payload
        }
        if !event.validationIssues.isEmpty { appendIssuesTo(node: node, from: event) }
        if !event.issues.isEmpty { copyIssuesTo(node: node, from: event) }
        synthesizePlaceholdersIfNeeded(for: node)
    }

    fileprivate mutating func boxWillStart(_ header: BoxHeader, _ event: ParseEvent, _ depth: Int) {
        let node = MutableNode(
            header: header, metadata: event.metadata, payload: event.payload,
            validationIssues: event.validationIssues, depth: depth)
        if !event.issues.isEmpty {
            node.issues = event.issues
            if event.issues.containsGuardIssues() { node.status = .partial }
        }
        if let parent = stack.last { parent.children.append(node) } else { rootNodes.append(node) }
        stack.append(node)
    }

    public mutating func consume(_ event: ParseEvent) {
        aggregatedIssues.append(contentsOf: event.validationIssues)

        switch event.kind {
        case .willStartBox(let header, let depth): boxWillStart(header, event, depth)

        case .didFinishBox(let header, _): boxDidFinish(header, event)
        }
    }

    public func makeTree() -> ParseTree {
        ParseTree(nodes: rootNodes.map { $0.snapshot() }, validationIssues: aggregatedIssues)
    }
}
