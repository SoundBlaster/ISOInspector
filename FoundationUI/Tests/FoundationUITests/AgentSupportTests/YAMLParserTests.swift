import XCTest

@testable import FoundationUI

/// Unit tests for YAMLParser component.
///
/// Tests YAML parsing functionality including:
/// - Simple component parsing
/// - Nested component hierarchies
/// - Multi-document YAML
/// - Error handling for invalid YAML
/// - File parsing
///
@available(iOS 17.0, macOS 14.0, *)
final class YAMLParserTests: XCTestCase {
  // MARK: - Simple Parsing Tests

  func testParseSimpleBadge() throws {
    let yaml = """
      - componentType: Badge
        properties:
          text: "Test"
          level: info
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].componentType, "Badge")
    XCTAssertEqual(descriptions[0].properties["text"] as? String, "Test")
    XCTAssertEqual(descriptions[0].properties["level"] as? String, "info")
    XCTAssertNil(descriptions[0].semantics)
    XCTAssertNil(descriptions[0].content)
  }

  func testParseCardWithElevation() throws {
    let yaml = """
      - componentType: Card
        properties:
          elevation: medium
          cornerRadius: 12
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].componentType, "Card")
    XCTAssertEqual(descriptions[0].properties["elevation"] as? String, "medium")
    XCTAssertEqual(descriptions[0].properties["cornerRadius"] as? Int, 12)
  }

  func testParseWithSemantics() throws {
    let yaml = """
      - componentType: Badge
        properties:
          text: "Warning"
          level: warning
        semantics: "Indicates a validation warning"
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].semantics, "Indicates a validation warning")
  }

  // MARK: - Nested Component Tests

  func testParseNestedCardWithBadge() throws {
    let yaml = """
      - componentType: Card
        properties:
          elevation: low
        content:
          - componentType: Badge
            properties:
              text: "Nested"
              level: success
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].componentType, "Card")

    let content = try XCTUnwrap(descriptions[0].content)
    XCTAssertEqual(content.count, 1)
    XCTAssertEqual(content[0].componentType, "Badge")
    XCTAssertEqual(content[0].properties["text"] as? String, "Nested")
  }

  func testParseMultipleNestedComponents() throws {
    let yaml = """
      - componentType: Card
        content:
          - componentType: SectionHeader
            properties:
              title: "Metadata"
          - componentType: KeyValueRow
            properties:
              key: "Size"
              value: "1024"
          - componentType: Badge
            properties:
              text: "Valid"
              level: success
      """

    let descriptions = try YAMLParser.parse(yaml)

    let content = try XCTUnwrap(descriptions[0].content)
    XCTAssertEqual(content.count, 3)
    XCTAssertEqual(content[0].componentType, "SectionHeader")
    XCTAssertEqual(content[1].componentType, "KeyValueRow")
    XCTAssertEqual(content[2].componentType, "Badge")
  }

  // MARK: - Multi-Document YAML Tests

  func testParseMultipleComponents() throws {
    let yaml = """
      - componentType: Badge
        properties:
          text: "Info"
          level: info
      - componentType: Badge
        properties:
          text: "Warning"
          level: warning
      - componentType: Badge
        properties:
          text: "Error"
          level: error
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 3)
    XCTAssertEqual(descriptions[0].properties["level"] as? String, "info")
    XCTAssertEqual(descriptions[1].properties["level"] as? String, "warning")
    XCTAssertEqual(descriptions[2].properties["level"] as? String, "error")
  }

  func testParseMultiDocumentYAML() throws {
    let yaml = """
      - componentType: Badge
        properties:
          text: "First"
          level: info
      ---
      - componentType: Badge
        properties:
          text: "Second"
          level: warning
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 2)
    XCTAssertEqual(descriptions[0].properties["text"] as? String, "First")
    XCTAssertEqual(descriptions[1].properties["text"] as? String, "Second")
  }

  func testParseSingleComponentObject() throws {
    let yaml = """
      componentType: Badge
      properties:
        text: "Single"
        level: success
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].componentType, "Badge")
    XCTAssertEqual(descriptions[0].properties["text"] as? String, "Single")
  }

  // MARK: - Component Type Tests

  func testParseAllComponentTypes() throws {
    let componentTypes = [
      "Badge", "Card", "KeyValueRow", "SectionHeader",
      "InspectorPattern", "SidebarPattern", "ToolbarPattern", "BoxTreePattern",
    ]

    for componentType in componentTypes {
      let yaml = """
        - componentType: \(componentType)
          properties:
            test: "value"
        """

      let descriptions = try YAMLParser.parse(yaml)
      XCTAssertEqual(descriptions.count, 1)
      XCTAssertEqual(descriptions[0].componentType, componentType)
    }
  }

  // MARK: - Property Type Tests

  func testParseVariousPropertyTypes() throws {
    let yaml = """
      - componentType: Card
        properties:
          stringProp: "text"
          intProp: 42
          doubleProp: 3.14
          boolProp: true
      """

    let descriptions = try YAMLParser.parse(yaml)
    let props = descriptions[0].properties

    XCTAssertEqual(props["stringProp"] as? String, "text")
    XCTAssertEqual(props["intProp"] as? Int, 42)
    if let doubleValue = props["doubleProp"] as? Double {
      XCTAssertEqual(doubleValue, 3.14, accuracy: 0.001)
    } else {
      XCTFail("doubleProp should be a Double")
    }
    XCTAssertEqual(props["boolProp"] as? Bool, true)
  }

  // MARK: - Error Handling Tests

  func testParseInvalidYAMLSyntax() {
    // Use YAML with unclosed quote which Yams will reject
    let yaml = """
      - componentType: "Badge
        properties: {}
      """

    XCTAssertThrowsError(try YAMLParser.parse(yaml)) { error in
      guard case YAMLParser.ParseError.invalidYAML = error else {
        XCTFail("Expected invalidYAML error, got \(error)")
        return
      }
    }
  }

  func testParseMissingComponentType() {
    let yaml = """
      - properties:
          text: "Test"
      """

    XCTAssertThrowsError(try YAMLParser.parse(yaml)) { error in
      guard case YAMLParser.ParseError.missingComponentType = error else {
        XCTFail("Expected missingComponentType error, got \(error)")
        return
      }
    }
  }

  func testParseInvalidStructure() {
    let yaml = """
      just a string
      """

    XCTAssertThrowsError(try YAMLParser.parse(yaml)) { error in
      guard case YAMLParser.ParseError.invalidStructure = error else {
        XCTFail("Expected invalidStructure error, got \(error)")
        return
      }
    }
  }

  // MARK: - Performance Tests

  func testParsePerformance() throws {
    // Generate YAML for 100 Badge components
    var yaml = ""
    for i in 0..<100 {
      yaml += """
        - componentType: Badge
          properties:
            text: "Badge \(i)"
            level: info

        """
    }

    measure {
      _ = try? YAMLParser.parse(yaml)
    }
  }

  func testParse100BadgeComponents() throws {
    // Generate YAML for 100 Badge components
    var yaml = ""
    for i in 0..<100 {
      yaml += """
        - componentType: Badge
          properties:
            text: "Badge \(i)"
            level: \(["info", "warning", "error", "success"][i % 4])

        """
    }

    let start = Date()
    let descriptions = try YAMLParser.parse(yaml)
    let elapsed = Date().timeIntervalSince(start)

    XCTAssertEqual(descriptions.count, 100)
    XCTAssertLessThan(elapsed, 0.1, "Parsing 100 components should take less than 100ms")
  }

  // MARK: - Edge Case Tests

  func testParseEmptyProperties() throws {
    let yaml = """
      - componentType: Card
        properties: {}
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertTrue(descriptions[0].properties.isEmpty)
  }

  func testParseEmptyYAML() throws {
    let yaml = ""

    XCTAssertThrowsError(try YAMLParser.parse(yaml))
  }

  func testParseComponentWithoutProperties() throws {
    let yaml = """
      - componentType: Card
      """

    let descriptions = try YAMLParser.parse(yaml)

    XCTAssertEqual(descriptions.count, 1)
    XCTAssertEqual(descriptions[0].componentType, "Card")
    XCTAssertTrue(descriptions[0].properties.isEmpty)
  }
}
