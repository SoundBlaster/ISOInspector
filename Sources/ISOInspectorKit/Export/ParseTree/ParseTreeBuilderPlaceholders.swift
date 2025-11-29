import Foundation

extension ParseTreeBuilder {
    mutating func synthesizePlaceholdersIfNeeded(for node: MutableNode) {
        var existingTypes = Set(node.children.map { $0.header.type })
        let requirements = ParseTree.PlaceholderPlanner.missingRequirements(
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
                metadata: ParseTree.PlaceholderPlanner.metadata(for: placeholderHeader),
                payload: nil,
                validationIssues: [],
                depth: node.depth + 1
            )
            placeholderNode.status = .corrupt
            let issue = ParseTree.PlaceholderPlanner.makeIssue(
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
