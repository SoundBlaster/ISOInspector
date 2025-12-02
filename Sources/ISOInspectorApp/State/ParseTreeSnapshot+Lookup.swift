#if canImport(Combine)
    import ISOInspectorKit

    extension ParseTreeSnapshot {
        func containsNode(with id: ParseTreeNode.ID) -> Bool {
            nodes.contains { $0.containsNode(with: id) }
        }
    }

    extension ParseTreeNode {
        fileprivate func containsNode(with id: ParseTreeNode.ID) -> Bool {
            if self.id == id { return true }
            for child in children where child.containsNode(with: id) { return true }
            return false
        }
    }
#endif
