//
//  AgentDescribableTests.swift
//  FoundationUI
//
//  Created by AI Assistant on 2025-11-08.
//  Copyright © 2025 ISO Inspector. All rights reserved.
//

#if canImport(SwiftUI)
import XCTest
@testable import FoundationUI

/// Unit tests for the `AgentDescribable` protocol.
///
/// These tests verify that:
/// - The protocol defines required properties (`componentType`, `properties`, `semantics`)
/// - Type safety is maintained for protocol conformance
/// - Components can correctly implement the protocol
/// - Properties can be serialized for agent consumption
@MainActor
final class AgentDescribableTests: XCTestCase {

    // MARK: - Protocol Conformance Tests

    /// Test that AgentDescribable protocol defines componentType property
    func testProtocolDefinesComponentType() {
        // Given: A type conforming to AgentDescribable
        let describable = MockDescribableComponent()

        // When: Accessing componentType
        let componentType = describable.componentType

        // Then: componentType should be a non-empty String (type is guaranteed by protocol)
        XCTAssertFalse(componentType.isEmpty, "componentType should not be empty")
    }

    /// Test that AgentDescribable protocol defines properties dictionary
    func testProtocolDefinesProperties() {
        // Given: A type conforming to AgentDescribable
        let describable = MockDescribableComponent()

        // When: Accessing properties
        let properties = describable.properties

        // Then: properties should not be nil (type [String: Any] is guaranteed by protocol)
        XCTAssertNotNil(properties, "properties should not be nil")
    }

    /// Test that AgentDescribable protocol defines semantics property
    func testProtocolDefinesSemantics() {
        // Given: A type conforming to AgentDescribable
        let describable = MockDescribableComponent()

        // When: Accessing semantics
        let semantics = describable.semantics

        // Then: semantics should be a non-empty String (type is guaranteed by protocol)
        XCTAssertFalse(semantics.isEmpty, "semantics should not be empty")
    }

    // MARK: - Type Safety Tests

    /// Test that componentType returns correct component identifier
    func testComponentTypeReturnsCorrectIdentifier() {
        // Given: A mock component with known type
        let describable = MockDescribableComponent()

        // When: Getting component type
        let componentType = describable.componentType

        // Then: Should match expected identifier
        XCTAssertEqual(componentType, "MockComponent", "componentType should match component name")
    }

    /// Test that properties dictionary contains expected keys and values
    func testPropertiesDictionaryContainsExpectedValues() {
        // Given: A mock component with known properties
        let describable = MockDescribableComponent()

        // When: Getting properties
        let properties = describable.properties

        // Then: Should contain expected keys
        XCTAssertNotNil(properties["title"], "properties should contain 'title' key")
        XCTAssertNotNil(properties["isEnabled"], "properties should contain 'isEnabled' key")

        // And: Values should have correct types
        XCTAssertTrue(properties["title"] is String, "title should be a String")
        XCTAssertTrue(properties["isEnabled"] is Bool, "isEnabled should be a Bool")
    }

    /// Test that semantics provides meaningful description
    func testSemanticsProvidesMeaningfulDescription() {
        // Given: A mock component
        let describable = MockDescribableComponent()

        // When: Getting semantics
        let semantics = describable.semantics

        // Then: Should contain meaningful description
        XCTAssertTrue(semantics.count > 10, "semantics should be a meaningful description (>10 chars)")
        XCTAssertTrue(semantics.contains("test"), "semantics should describe component purpose")
    }

    // MARK: - Component Integration Tests

    /// Test that properties can be serialized to JSON
    func testPropertiesCanBeSerializedToJSON() throws {
        // Given: A mock component with properties
        let describable = MockDescribableComponent()
        let properties = describable.properties

        // When: Attempting to serialize to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: properties, options: [])

        // Then: Should successfully serialize
        XCTAssertFalse(jsonData.isEmpty, "properties should be serializable to JSON")

        // And: Should be deserializable
        let deserialized = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(deserialized, "JSON should be deserializable")
        XCTAssertEqual(deserialized?["title"] as? String, properties["title"] as? String)
    }

    /// Test that multiple components can conform to AgentDescribable
    func testMultipleComponentsCanConformToProtocol() {
        // Given: Multiple components conforming to AgentDescribable
        let component1 = MockDescribableComponent()
        let component2 = AnotherMockDescribableComponent()

        // When: Storing them in array of AgentDescribable
        let describables: [AgentDescribable] = [component1, component2]

        // Then: Should maintain protocol conformance
        XCTAssertEqual(describables.count, 2, "should store multiple conforming types")
        XCTAssertEqual(describables[0].componentType, "MockComponent")
        XCTAssertEqual(describables[1].componentType, "AnotherMockComponent")
    }

    /// Test that AgentDescribable works with value types (structs)
    func testAgentDescribableWorksWithStructs() {
        // Given: A struct conforming to AgentDescribable
        let describable = MockDescribableStruct(text: "Test", level: "info")

        // When: Accessing protocol properties
        let componentType = describable.componentType
        let properties = describable.properties
        let semantics = describable.semantics

        // Then: All properties should be accessible
        XCTAssertEqual(componentType, "MockStruct")
        XCTAssertEqual(properties["text"] as? String, "Test")
        XCTAssertEqual(properties["level"] as? String, "info")
        XCTAssertFalse(semantics.isEmpty)
    }

    // MARK: - Edge Cases

    /// Test that empty properties dictionary is valid
    func testEmptyPropertiesDictionaryIsValid() {
        // Given: A component with no configurable properties
        let describable = MockEmptyDescribableComponent()

        // When: Getting properties
        let properties = describable.properties

        // Then: Should return empty dictionary (not nil)
        XCTAssertTrue(properties.isEmpty, "empty properties should be valid")
        XCTAssertNotNil(properties, "properties should not be nil")
    }

    /// Test that complex property values are supported
    func testComplexPropertyValuesAreSupported() {
        // Given: A component with complex properties
        let describable = MockComplexDescribableComponent()

        // When: Getting properties with nested values
        let properties = describable.properties

        // Then: Should support arrays and dictionaries
        XCTAssertNotNil(properties["items"] as? [String])
        XCTAssertNotNil(properties["config"] as? [String: Any])
    }
}

// MARK: - Mock Types for Testing

/// Mock component conforming to AgentDescribable for testing
private struct MockDescribableComponent: AgentDescribable {
    var componentType: String { "MockComponent" }
    var properties: [String: Any] {
        ["title": "Test Title", "isEnabled": true]
    }
    var semantics: String {
        "A test component for verifying AgentDescribable protocol"
    }
}

/// Another mock component for testing multiple conformances
private struct AnotherMockDescribableComponent: AgentDescribable {
    var componentType: String { "AnotherMockComponent" }
    var properties: [String: Any] {
        ["value": 42, "color": "blue"]
    }
    var semantics: String {
        "Another test component"
    }
}

/// Mock struct with parameters for testing value types
private struct MockDescribableStruct: AgentDescribable {
    let text: String
    let level: String

    var componentType: String { "MockStruct" }
    var properties: [String: Any] {
        ["text": text, "level": level]
    }
    var semantics: String {
        "A struct-based test component"
    }
}

/// Mock component with empty properties
private struct MockEmptyDescribableComponent: AgentDescribable {
    var componentType: String { "EmptyComponent" }
    var properties: [String: Any] { [:] }
    var semantics: String { "Component with no properties" }
}

/// Mock component with complex properties
private struct MockComplexDescribableComponent: AgentDescribable {
    var componentType: String { "ComplexComponent" }
    var properties: [String: Any] {
        [
            "items": ["item1", "item2", "item3"],
            "config": ["key1": "value1", "key2": 123] as [String: Any]
        ]
    }
    var semantics: String { "Component with nested properties" }
}
#endif
