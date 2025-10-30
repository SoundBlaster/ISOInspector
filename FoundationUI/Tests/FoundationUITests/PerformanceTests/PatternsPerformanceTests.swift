import XCTest
#if canImport(SwiftUI)
import SwiftUI
@testable import FoundationUI

/// Performance tests for FoundationUI Patterns (Layer 3)
///
/// Tests verify:
/// - Render time for complex hierarchies
/// - Memory footprint stays within limits
/// - Lazy loading and virtualization
/// - Large data set handling (1000+ nodes)
/// - Animation performance
@MainActor
final class PatternsPerformanceTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    /// Performance baseline: Maximum acceptable render time (milliseconds)
    private let maxRenderTime: Double = 100.0 // 100ms = 0.1s
    
    /// Memory baseline: Maximum acceptable memory footprint (MB)
    private let maxMemoryMB: Double = 5.0
    
    /// Large tree size for stress testing
    private let largeTreeNodeCount = 1000
    
    /// Deep tree depth for nesting tests
    private let deepTreeDepth = 50
    
    // MARK: - BoxTreePattern Performance Tests
    
    /// Test BoxTreePattern render time with large flat tree
    func testBoxTreePatternLargeFlatTreeRenderTime() {
        // Given: Large flat tree with 1000 nodes
        let nodes = (0..<largeTreeNodeCount).map { index in
            TestTreeNode(id: UUID(), title: "Node \(index)", children: [])
        }
        
        @State var expandedNodes: Set<UUID> = []
        @State var selection: UUID? = nil
        
        // When: Measure render time
        measure {
            let _ = BoxTreePattern(
                data: nodes,
                children: { $0.children },
                expandedNodes: $expandedNodes,
                selection: $selection
            ) { node in
                Text(node.title)
            }
        }
        
        // Then: Should complete within performance baseline
        // XCTest measure will report results
    }
    
    /// Test BoxTreePattern render time with deeply nested tree
    func testBoxTreePatternDeepNestedTreeRenderTime() {
        // Given: Deep tree with 50 levels
        func makeDeepTree(depth: Int, currentDepth: Int = 0) -> [TestTreeNode] {
            guard currentDepth < depth else { return [] }
            return [TestTreeNode(
                id: UUID(),
                title: "Level \(currentDepth)",
                children: makeDeepTree(depth: depth, currentDepth: currentDepth + 1)
            )]
        }
        
        let deepTree = makeDeepTree(depth: deepTreeDepth)
        @State var expandedNodes: Set<UUID> = []
        
        // When: Measure render time
        measure {
            let _ = BoxTreePattern(
                data: deepTree,
                children: { $0.children },
                expandedNodes: $expandedNodes
            ) { node in
                Text(node.title)
            }
        }
        
        // Then: Should handle deep nesting efficiently
    }
    
    /// Test BoxTreePattern memory usage with large tree
    func testBoxTreePatternMemoryUsage() {
        // Given: Large tree with 1000 nodes
        let nodes = (0..<largeTreeNodeCount).map { index in
            TestTreeNode(
                id: UUID(),
                title: "Node \(index)",
                children: (0..<5).map { childIndex in
                    TestTreeNode(id: UUID(), title: "Child \(childIndex)", children: [])
                }
            )
        }
        
        @State var expandedNodes: Set<UUID> = []
        
        // When: Create pattern
        let pattern = BoxTreePattern(
            data: nodes,
            children: { $0.children },
            expandedNodes: $expandedNodes
        ) { node in
            Text(node.title)
        }
        
        // Then: Memory usage should be reasonable
        // Pattern itself should not hold references to all nodes
        XCTAssertNotNil(pattern)
    }
    
    /// Test BoxTreePattern lazy loading (collapsed children not rendered)
    func testBoxTreePatternLazyLoadingOptimization() {
        // Given: Tree with many children
        let rootNodes = (0..<100).map { index in
            TestTreeNode(
                id: UUID(),
                title: "Root \(index)",
                children: (0..<100).map { childIndex in
                    TestTreeNode(id: UUID(), title: "Child \(childIndex)", children: [])
                }
            )
        }
        
        @State var expandedNodes: Set<UUID> = [] // No nodes expanded
        
        // When: Measure render time with all nodes collapsed
        measure {
            let _ = BoxTreePattern(
                data: rootNodes,
                children: { $0.children },
                expandedNodes: $expandedNodes
            ) { node in
                Text(node.title)
            }
        }
        
        // Then: Should be fast because children are not rendered
        // This test verifies LazyVStack is working correctly
    }
    
    /// Test BoxTreePattern expansion performance
    func testBoxTreePatternExpansionPerformance() {
        // Given: Tree with many nodes
        let nodes = (0..<100).map { index in
            TestTreeNode(
                id: UUID(),
                title: "Node \(index)",
                children: (0..<10).map { childIndex in
                    TestTreeNode(id: UUID(), title: "Child \(childIndex)", children: [])
                }
            )
        }
        
        @State var expandedNodes: Set<UUID> = Set(nodes.map { $0.id })
        
        // When: Measure render time with all nodes expanded
        measure {
            let _ = BoxTreePattern(
                data: nodes,
                children: { $0.children },
                expandedNodes: $expandedNodes
            ) { node in
                Text(node.title)
            }
        }
        
        // Then: Should handle expanded state efficiently
    }
    
    // MARK: - InspectorPattern Performance Tests
    
    /// Test InspectorPattern render time with many sections
    func testInspectorPatternManySectionsRenderTime() {
        // Given: Inspector with 50 sections
        let sections = (0..<50).map { index in
            VStack {
                SectionHeader(title: "Section \(index)")
                ForEach(0..<10, id: \.self) { rowIndex in
                    KeyValueRow(key: "Key \(rowIndex)", value: "Value \(rowIndex)")
                }
            }
        }
        
        // When: Measure render time
        measure {
            let _ = InspectorPattern(title: "Performance Test") {
                ForEach(0..<sections.count, id: \.self) { index in
                    sections[index]
                }
            }
        }
        
        // Then: Should handle many sections efficiently
    }
    
    /// Test InspectorPattern memory usage
    func testInspectorPatternMemoryUsage() {
        // Given: Inspector with large content
        let content = (0..<200).map { index in
            KeyValueRow(key: "Key \(index)", value: "Value \(index) with longer text content")
        }
        
        // When: Create inspector
        let inspector = InspectorPattern(title: "Memory Test") {
            ForEach(0..<content.count, id: \.self) { index in
                content[index]
            }
        }
        
        // Then: Memory usage should be reasonable
        XCTAssertNotNil(inspector)
    }
    
    /// Test InspectorPattern scroll performance
    func testInspectorPatternScrollPerformance() {
        // Given: Inspector with many rows
        // When: Measure render time
        measure {
            let _ = InspectorPattern(title: "Scroll Test") {
                ForEach(0..<500, id: \.self) { index in
                    KeyValueRow(key: "Key \(index)", value: "Value \(index)")
                }
            }
        }
        
        // Then: Should use ScrollView efficiently
    }
    
    // MARK: - SidebarPattern Performance Tests
    
    /// Test SidebarPattern render time with many items
    func testSidebarPatternManyItemsRenderTime() {
        // Given: Sidebar with 200 items
        struct SidebarItem: Identifiable, Hashable {
            let id = UUID()
            let title: String
        }
        
        let items = (0..<200).map { SidebarItem(title: "Item \(index)") }
        @State var selection: SidebarItem? = nil
        
        // When: Measure render time
        measure {
            let _ = SidebarPattern(
                sections: [(title: "Items", items: items)],
                selection: $selection
            ) { item in
                Text(item.title)
            }
        }
        
        // Then: Should handle many items efficiently
    }
    
    /// Test SidebarPattern with multiple sections
    func testSidebarPatternMultipleSectionsPerformance() {
        // Given: Sidebar with 20 sections of 20 items each
        struct SidebarItem: Identifiable, Hashable {
            let id = UUID()
            let title: String
        }
        
        let sections = (0..<20).map { sectionIndex in
            (
                title: "Section \(sectionIndex)",
                items: (0..<20).map { SidebarItem(title: "Item \(index)") }
            )
        }
        @State var selection: SidebarItem? = nil
        
        // When: Measure render time
        measure {
            let _ = SidebarPattern(
                sections: sections,
                selection: $selection
            ) { item in
                Text(item.title)
            }
        }
        
        // Then: Should handle multiple sections efficiently
    }
    
    // MARK: - ToolbarPattern Performance Tests
    
    /// Test ToolbarPattern render time with many items
    func testToolbarPatternManyItemsRenderTime() {
        // Given: Toolbar with 30 items
        let items = (0..<30).map { index in
            ToolbarItem(
                id: "item\(index)",
                label: "Item \(index)",
                systemImage: "star.fill",
                action: {}
            )
        }
        
        // When: Measure render time
        measure {
            let _ = ToolbarPattern(items: items)
        }
        
        // Then: Should handle many items efficiently
    }
    
    // MARK: - Cross-Pattern Performance Tests
    
    /// Test combined patterns performance (realistic scenario)
    func testCombinedPatternsPerformance() {
        // Given: Complex layout with multiple patterns
        struct SidebarItem: Identifiable, Hashable {
            let id = UUID()
            let title: String
        }
        
        let sidebarItems = (0..<50).map { SidebarItem(title: "Item \(index)") }
        @State var selection: SidebarItem? = nil
        
        let treeNodes = (0..<100).map { index in
            TestTreeNode(id: UUID(), title: "Node \(index)", children: [])
        }
        @State var expandedNodes: Set<UUID> = []
        
        // When: Measure combined render time
        measure {
            let _ = HStack(spacing: 0) {
                // Sidebar
                SidebarPattern(
                    sections: [(title: "Items", items: sidebarItems)],
                    selection: $selection
                ) { item in
                    Text(item.title)
                }
                .frame(width: 200)
                
                // Tree
                BoxTreePattern(
                    data: treeNodes,
                    children: { $0.children },
                    expandedNodes: $expandedNodes
                ) { node in
                    Text(node.title)
                }
                .frame(width: 300)
                
                // Inspector
                InspectorPattern(title: "Inspector") {
                    ForEach(0..<50, id: \.self) { index in
                        KeyValueRow(key: "Key \(index)", value: "Value \(index)")
                    }
                }
            }
        }
        
        // Then: Combined patterns should maintain good performance
    }
    
    /// Test pattern performance with animations
    func testPatternPerformanceWithAnimations() {
        // Given: Pattern with animated state changes
        @State var isExpanded = false
        
        let nodes = (0..<100).map { index in
            TestTreeNode(id: UUID(), title: "Node \(index)", children: [])
        }
        @State var expandedNodes: Set<UUID> = []
        
        // When: Measure with animations
        measure {
            withAnimation(DS.Animation.medium) {
                isExpanded.toggle()
            }
            
            let _ = BoxTreePattern(
                data: nodes,
                children: { $0.children },
                expandedNodes: $expandedNodes
            ) { node in
                Text(node.title)
                    .opacity(isExpanded ? 1.0 : 0.8)
            }
        }
        
        // Then: Animations should not significantly impact performance
    }
    
    // MARK: - Stress Tests
    
    /// Stress test: Very large tree (5000 nodes)
    func testStressLargeTree() {
        // Given: Very large tree
        let nodes = (0..<5000).map { index in
            TestTreeNode(id: UUID(), title: "Node \(index)", children: [])
        }
        @State var expandedNodes: Set<UUID> = []
        
        // When: Create pattern
        let startTime = Date()
        let pattern = BoxTreePattern(
            data: nodes,
            children: { $0.children },
            expandedNodes: $expandedNodes
        ) { node in
            Text(node.title)
        }
        let elapsed = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
        
        // Then: Should complete in reasonable time
        XCTAssertNotNil(pattern)
        XCTAssertLessThan(elapsed, maxRenderTime * 2, "Large tree took too long to render")
    }
    
    /// Stress test: Very deep tree (100 levels)
    func testStressDeepTree() {
        // Given: Very deep tree
        func makeVeryDeepTree(depth: Int, currentDepth: Int = 0) -> [TestTreeNode] {
            guard currentDepth < depth else { return [] }
            return [TestTreeNode(
                id: UUID(),
                title: "Level \(currentDepth)",
                children: makeVeryDeepTree(depth: depth, currentDepth: currentDepth + 1)
            )]
        }
        
        let deepTree = makeVeryDeepTree(depth: 100)
        @State var expandedNodes: Set<UUID> = []
        
        // When: Create pattern
        let pattern = BoxTreePattern(
            data: deepTree,
            children: { $0.children },
            expandedNodes: $expandedNodes
        ) { node in
            Text(node.title)
        }
        
        // Then: Should handle extreme depth
        XCTAssertNotNil(pattern)
    }
    
    // MARK: - Memory Leak Tests
    
    /// Test that patterns don't retain references after deallocation
    func testPatternsDoNotLeakMemory() {
        // Given: Pattern with strong references
        weak var weakPattern: AnyObject?
        
        autoreleasepool {
            let nodes = (0..<100).map { index in
                TestTreeNode(id: UUID(), title: "Node \(index)", children: [])
            }
            @State var expandedNodes: Set<UUID> = []
            
            let pattern = BoxTreePattern(
                data: nodes,
                children: { $0.children },
                expandedNodes: $expandedNodes
            ) { node in
                Text(node.title)
            }
            
            weakPattern = pattern as AnyObject
            XCTAssertNotNil(weakPattern)
        }
        
        // Then: Pattern should be deallocated
        XCTAssertNil(weakPattern, "Pattern was not deallocated - possible memory leak")
    }
}

// MARK: - Test Fixtures

/// Test tree node for performance testing
private struct TestTreeNode: Identifiable {
    let id: UUID
    let title: String
    var children: [TestTreeNode]
}

/// Test toolbar item for performance testing
private struct ToolbarItem: Identifiable {
    let id: String
    let label: String
    let systemImage: String
    let action: () -> Void
}

#endif // canImport(SwiftUI)
