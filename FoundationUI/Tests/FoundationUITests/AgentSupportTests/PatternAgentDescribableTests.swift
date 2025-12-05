//
//  PatternAgentDescribableTests.swift
//  FoundationUI
//
//  Created by AI Assistant on 2025-11-09.
//  Copyright © 2025 ISO Inspector. All rights reserved.
//

#if canImport(SwiftUI)
    @testable import FoundationUI
    import SwiftUI
    import XCTest

    /// Unit tests for AgentDescribable conformance in Layer 3 patterns
    /// (InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern)
    ///
    /// These tests verify that all patterns correctly implement the AgentDescribable protocol
    /// and provide accurate property descriptions for AI agent consumption.
    @available(iOS 17.0, macOS 14.0, *) @MainActor
    final class PatternAgentDescribableTests: XCTestCase {
        // MARK: - InspectorPattern Tests

        func testInspectorPatternComponentType() {
            let inspector = InspectorPattern(title: "File Details") { Text("Content") }
            XCTAssertEqual(inspector.componentType, "InspectorPattern")
        }

        func testInspectorPatternProperties() {
            let inspector = InspectorPattern(title: "ISO Box Inspector", material: .regular) {
                Text("Content")
            }

            XCTAssertEqual(inspector.properties["title"] as? String, "ISO Box Inspector")
            XCTAssertNotNil(inspector.properties["material"])
        }

        func testInspectorPatternSemantics() {
            let inspector = InspectorPattern(title: "Metadata") { Text("Content") }

            XCTAssertFalse(inspector.semantics.isEmpty)
            XCTAssertTrue(inspector.semantics.contains("Metadata"))
        }

        func testInspectorPatternJSONSerialization() {
            let inspector = InspectorPattern(title: "Test") { Text("Content") }

            XCTAssertTrue(inspector.isJSONSerializable())
        }

        // MARK: - SidebarPattern Tests

        func testSidebarPatternComponentType() {
            let sidebar = SidebarPattern<String, Text>(sections: [], selection: .constant(nil)) {
                _ in Text("Detail")
            }

            XCTAssertEqual(sidebar.componentType, "SidebarPattern")
        }

        func testSidebarPatternProperties() {
            let sections = [
                SidebarPattern<String, Text>.Section(
                    title: "Files",
                    items: [
                        SidebarPattern<String, Text>.Item(
                            id: "item1", title: "Video", iconSystemName: "film")
                    ])
            ]

            let sidebar = SidebarPattern<String, Text>(
                sections: sections, selection: .constant("item1")
            ) { _ in Text("Detail") }

            XCTAssertNotNil(sidebar.properties["sections"])
            XCTAssertNotNil(sidebar.properties["selection"])
        }

        func testSidebarPatternSemantics() {
            let sidebar = SidebarPattern<String, Text>(sections: [], selection: .constant(nil)) {
                _ in Text("Detail")
            }

            XCTAssertFalse(sidebar.semantics.isEmpty)
        }

        func testSidebarPatternJSONSerialization() {
            let sidebar = SidebarPattern<String, Text>(sections: [], selection: .constant(nil)) {
                _ in Text("Detail")
            }

            XCTAssertTrue(sidebar.isJSONSerializable())
        }

        // MARK: - ToolbarPattern Tests

        func testToolbarPatternComponentType() {
            let toolbar = ToolbarPattern(items: ToolbarPattern.Items())
            XCTAssertEqual(toolbar.componentType, "ToolbarPattern")
        }

        func testToolbarPatternProperties() {
            let items = ToolbarPattern.Items(
                primary: [
                    ToolbarPattern.Item(id: "open", iconSystemName: "folder", title: "Open") {}
                ], secondary: [], overflow: [])

            let toolbar = ToolbarPattern(items: items)

            XCTAssertNotNil(toolbar.properties["items"])
        }

        func testToolbarPatternSemantics() {
            let toolbar = ToolbarPattern(items: ToolbarPattern.Items())

            XCTAssertFalse(toolbar.semantics.isEmpty)
        }

        func testToolbarPatternJSONSerialization() {
            let toolbar = ToolbarPattern(items: ToolbarPattern.Items())

            XCTAssertTrue(toolbar.isJSONSerializable())
        }

        // MARK: - BoxTreePattern Tests

        struct TestNode: Identifiable, Hashable {
            let id: String
            let name: String
            var children: [TestNode]

            static func == (lhs: TestNode, rhs: TestNode) -> Bool { lhs.id == rhs.id }

            func hash(into hasher: inout Hasher) { hasher.combine(id) }
        }

        func testBoxTreePatternComponentType() {
            let tree = BoxTreePattern(
                data: [TestNode(id: "root", name: "Root", children: [])], children: { $0.children }
            ) { node in Text(node.name) }

            XCTAssertEqual(tree.componentType, "BoxTreePattern")
        }

        func testBoxTreePatternProperties() {
            let tree = BoxTreePattern(
                data: [TestNode(id: "root", name: "Root", children: [])], children: { $0.children }
            ) { node in Text(node.name) }

            XCTAssertNotNil(tree.properties["nodeCount"])
        }

        func testBoxTreePatternSemantics() {
            let tree = BoxTreePattern(
                data: [TestNode(id: "root", name: "Root", children: [])], children: { $0.children }
            ) { node in Text(node.name) }

            XCTAssertFalse(tree.semantics.isEmpty)
        }

        func testBoxTreePatternJSONSerialization() {
            let tree = BoxTreePattern(
                data: [TestNode(id: "root", name: "Root", children: [])], children: { $0.children }
            ) { node in Text(node.name) }

            XCTAssertTrue(tree.isJSONSerializable())
        }

        // MARK: - agentDescription() Tests

        func testInspectorPatternAgentDescription() {
            let inspector = InspectorPattern(title: "Test Inspector") { Text("Content") }
            let description = inspector.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("InspectorPattern"))
            XCTAssertTrue(description.contains("Test Inspector"))
        }

        func testSidebarPatternAgentDescription() {
            let sidebar = SidebarPattern<String, Text>(sections: [], selection: .constant(nil)) {
                _ in Text("Detail")
            }

            let description = sidebar.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("SidebarPattern"))
        }

        func testToolbarPatternAgentDescription() {
            let toolbar = ToolbarPattern(items: ToolbarPattern.Items())
            let description = toolbar.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("ToolbarPattern"))
        }

        func testBoxTreePatternAgentDescription() {
            let tree = BoxTreePattern(
                data: [TestNode(id: "root", name: "Root", children: [])], children: { $0.children }
            ) { node in Text(node.name) }

            let description = tree.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("BoxTreePattern"))
        }

        // MARK: - Edge Cases

        func testInspectorPatternEmptyTitle() {
            let inspector = InspectorPattern(title: "") { Text("Content") }

            XCTAssertEqual(inspector.properties["title"] as? String, "")
            XCTAssertTrue(inspector.isJSONSerializable())
        }

        func testSidebarPatternEmptySections() {
            let sidebar = SidebarPattern<String, Text>(sections: [], selection: .constant(nil)) {
                _ in Text("Detail")
            }

            XCTAssertNotNil(sidebar.properties["sections"])
            XCTAssertTrue(sidebar.isJSONSerializable())
        }

        func testToolbarPatternEmptyItems() {
            let toolbar = ToolbarPattern(items: ToolbarPattern.Items())

            XCTAssertNotNil(toolbar.properties["items"])
            XCTAssertTrue(toolbar.isJSONSerializable())
        }

        func testBoxTreePatternEmptyData() {
            let tree = BoxTreePattern(data: [] as [TestNode], children: { $0.children }) { node in
                Text(node.name)
            }

            XCTAssertTrue(tree.isJSONSerializable())
        }
    }
#endif
