import Foundation

public struct ParseTreeBuilder {
    private var rootNodes: [MutableNode] = []
    private var stack: [MutableNode] = []
    private var aggregatedIssues: [ValidationIssue] = []

    public init() {}

    public mutating func consume(_ event: ParseEvent) {
        aggregatedIssues.append(contentsOf: event.validationIssues)

        switch event.kind {
        case let .willStartBox(header, _):
            let node = MutableNode(
                header: header,
                metadata: event.metadata,
                validationIssues: event.validationIssues
            )
            if let parent = stack.last {
                parent.children.append(node)
            } else {
                rootNodes.append(node)
            }
            stack.append(node)

        case let .didFinishBox(header, _):
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
                if !event.validationIssues.isEmpty {
                    node.validationIssues.append(contentsOf: event.validationIssues)
                }
            } else {
                stack.append(node)
            }
        }
    }

    public func makeTree() -> ParseTree {
        ParseTree(nodes: rootNodes.map { $0.snapshot() }, validationIssues: aggregatedIssues)
    }
}

private final class MutableNode {
    let header: BoxHeader
    var metadata: BoxDescriptor?
    var validationIssues: [ValidationIssue]
    var children: [MutableNode]

    init(header: BoxHeader, metadata: BoxDescriptor?, validationIssues: [ValidationIssue]) {
        self.header = header
        self.metadata = metadata
        self.validationIssues = validationIssues
        self.children = []
    }

    func snapshot() -> ParseTreeNode {
        ParseTreeNode(
            header: header,
            metadata: metadata,
            validationIssues: validationIssues,
            children: children.map { $0.snapshot() }
        )
    }
}
