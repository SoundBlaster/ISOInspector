import Foundation

extension ParseTreeBuilder {
    fileprivate func boxHeaderFrom(
        _ requirement: ParseTree.PlaceholderPlanner.Requirement, _ placeholderRange: Range<Int64>
    ) -> BoxHeader {
        return BoxHeader(
            type: requirement.childType, totalSize: 0, headerSize: 0,
            payloadRange: placeholderRange, range: placeholderRange, uuid: nil)
    }

    fileprivate func mutableCorrupedNodeFrom(
        _ placeholderHeader: BoxHeader, _ node: ParseTreeBuilder.MutableNode
    ) -> ParseTreeBuilder.MutableNode {
        let placeholderNode = MutableNode(
            header: placeholderHeader,
            metadata: ParseTree.PlaceholderPlanner.metadata(for: placeholderHeader), payload: nil,
            validationIssues: [], depth: node.depth + 1)
        placeholderNode.status = .corrupt
        return placeholderNode
    }

    fileprivate func issueFrom(
        _ requirement: ParseTree.PlaceholderPlanner.Requirement,
        _ node: ParseTreeBuilder.MutableNode, _ placeholderHeader: BoxHeader
    ) -> ParseIssue {
        return ParseTree.PlaceholderPlanner.makeIssue(
            for: requirement, parent: node.header, placeholder: placeholderHeader)
    }

    mutating func synthesizePlaceholdersIfNeeded(for node: MutableNode) {
        var existingTypes = Set(node.children.map { $0.header.type })
        let requirements = ParseTree.PlaceholderPlanner.missingRequirements(
            for: node.header, existingChildTypes: existingTypes)
        guard !requirements.isEmpty else { return }

        if node.status != .corrupt { node.status = .partial }

        for requirement in requirements {
            existingTypes.insert(requirement.childType)
            let startOffset = placeholderIDGenerator.next()
            let placeholderRange = startOffset..<startOffset
            let placeholderHeader = boxHeaderFrom(requirement, placeholderRange)
            let placeholderNode = mutableCorrupedNodeFrom(placeholderHeader, node)
            let issue = issueFrom(requirement, node, placeholderHeader)
            placeholderNode.issues = [issue]
            node.issues.append(issue)
            node.children.append(placeholderNode)
        }
    }
}
