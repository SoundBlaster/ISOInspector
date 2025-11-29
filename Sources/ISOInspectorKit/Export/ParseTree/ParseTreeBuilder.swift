import Foundation

public struct ParseTreeBuilder {
    private var rootNodes: [MutableNode] = []
    private var stack: [MutableNode] = []
    private var aggregatedIssues: [ValidationIssue] = []
    var placeholderIDGenerator = ParseTree.PlaceholderIDGenerator()
    
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
                if event.issues.containsGuardIssues() {
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
                    if event.issues.containsGuardIssues() {
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
