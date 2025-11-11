#if canImport(SwiftUI)
    import XCTest
    import SwiftUI
    @testable import FoundationUI

    /// Unit tests for YAMLViewGenerator component.
    ///
    /// Tests SwiftUI view generation from YAML including:
    /// - Badge generation
    /// - Card generation
    /// - KeyValueRow generation
    /// - SectionHeader generation
    /// - InspectorPattern generation
    /// - Error handling
    /// - Performance benchmarks
    ///
    /// NOTE: These tests require SwiftUI and will only run on macOS/iOS/iPadOS platforms.
    ///
    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    final class YAMLViewGeneratorTests: XCTestCase {

        // MARK: - Badge Generation Tests

        func testGenerateBadgeFromYAML() throws {
            let yaml = """
                - componentType: Badge
                  properties:
                    text: "Success"
                    level: success
                    showIcon: true
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateBadgeWithAllLevels() throws {
            let levels = ["info", "warning", "error", "success"]

            for level in levels {
                let yaml = """
                    - componentType: Badge
                      properties:
                        text: "Test"
                        level: \(level)
                    """

                XCTAssertNoThrow(try YAMLViewGenerator.generateView(fromYAML: yaml))
            }
        }

        func testGenerateBadgeWithoutOptionalIcon() throws {
            let yaml = """
                - componentType: Badge
                  properties:
                    text: "Test"
                    level: info
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - Card Generation Tests

        func testGenerateCardFromYAML() throws {
            let yaml = """
                - componentType: Card
                  properties:
                    elevation: medium
                    cornerRadius: 12
                    material: regular
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateCardWithAllElevations() throws {
            let elevations = ["none", "low", "medium", "high"]

            for elevation in elevations {
                let yaml = """
                    - componentType: Card
                      properties:
                        elevation: \(elevation)
                    """

                XCTAssertNoThrow(try YAMLViewGenerator.generateView(fromYAML: yaml))
            }
        }

        func testGenerateCardWithNestedBadge() throws {
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

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - KeyValueRow Generation Tests

        func testGenerateKeyValueRow() throws {
            let yaml = """
                - componentType: KeyValueRow
                  properties:
                    key: "Size"
                    value: "1024 bytes"
                    layout: horizontal
                    isCopyable: true
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateKeyValueRowWithVerticalLayout() throws {
            let yaml = """
                - componentType: KeyValueRow
                  properties:
                    key: "Description"
                    value: "Long value"
                    layout: vertical
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - SectionHeader Generation Tests

        func testGenerateSectionHeader() throws {
            let yaml = """
                - componentType: SectionHeader
                  properties:
                    title: "Metadata"
                    showDivider: true
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateSectionHeaderWithoutDivider() throws {
            let yaml = """
                - componentType: SectionHeader
                  properties:
                    title: "Header"
                    showDivider: false
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - InspectorPattern Generation Tests

        func testGenerateInspectorPattern() throws {
            let yaml = """
                - componentType: InspectorPattern
                  properties:
                    title: "File Inspector"
                    material: regular
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateInspectorPatternWithContent() throws {
            let yaml = """
                - componentType: InspectorPattern
                  properties:
                    title: "Inspector"
                  content:
                    - componentType: SectionHeader
                      properties:
                        title: "Properties"
                    - componentType: KeyValueRow
                      properties:
                        key: "Size"
                        value: "1024"
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - Error Handling Tests

        func testGenerateWithUnknownComponentType() {
            let yaml = """
                - componentType: UnknownComponent
                  properties: {}
                """

            XCTAssertThrowsError(try YAMLViewGenerator.generateView(fromYAML: yaml)) { error in
                // Validation happens before generation, so we expect ValidationError
                guard case YAMLValidator.ValidationError.unknownComponentType(let type) = error
                else {
                    XCTFail("Expected unknownComponentType error, got \(error)")
                    return
                }
                XCTAssertEqual(type, "UnknownComponent")
            }
        }

        func testGenerateBadgeWithMissingText() {
            let description = YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["level": "info"]
            )

            XCTAssertThrowsError(try YAMLViewGenerator.generateView(from: description)) { error in
                guard
                    case YAMLViewGenerator.GenerationError.missingProperty(
                        let component, let property) = error
                else {
                    XCTFail("Expected missingProperty error, got \(error)")
                    return
                }
                XCTAssertEqual(component, "Badge")
                XCTAssertEqual(property, "text")
            }
        }

        func testGenerateBadgeWithInvalidLevel() {
            let description = YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: [
                    "text": "Test",
                    "level": "invalid-level",
                ]
            )

            XCTAssertThrowsError(try YAMLViewGenerator.generateView(from: description)) { error in
                guard case YAMLViewGenerator.GenerationError.invalidProperty = error else {
                    XCTFail("Expected invalidProperty error, got \(error)")
                    return
                }
            }
        }

        func testGenerateFromEmptyYAML() {
            let yaml = ""

            XCTAssertThrowsError(try YAMLViewGenerator.generateView(fromYAML: yaml))
        }

        // MARK: - Complex Composition Tests

        func testGenerateComplexCardComposition() throws {
            let yaml = """
                - componentType: Card
                  properties:
                    elevation: medium
                  content:
                    - componentType: SectionHeader
                      properties:
                        title: "Metadata"
                    - componentType: KeyValueRow
                      properties:
                        key: "Size"
                        value: "1024"
                    - componentType: KeyValueRow
                      properties:
                        key: "Type"
                        value: "MP4"
                    - componentType: Badge
                      properties:
                        text: "Valid"
                        level: success
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        func testGenerateNestedCardStructure() throws {
            let yaml = """
                - componentType: Card
                  properties:
                    elevation: high
                  content:
                    - componentType: Card
                      properties:
                        elevation: low
                      content:
                        - componentType: Badge
                          properties:
                            text: "Deep"
                            level: info
                """

            let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
            XCTAssertNotNil(view)
        }

        // MARK: - Performance Tests

        func testGenerate50BadgeViews() throws {
            var descriptions: [YAMLParser.ComponentDescription] = []

            for i in 0..<50 {
                let description = YAMLParser.ComponentDescription(
                    componentType: "Badge",
                    properties: [
                        "text": "Badge \(i)",
                        "level": ["info", "warning", "error", "success"][i % 4],
                    ]
                )
                descriptions.append(description)
            }

            let start = Date()
            for description in descriptions {
                _ = try YAMLViewGenerator.generateView(from: description)
            }
            let elapsed = Date().timeIntervalSince(start)

            XCTAssertLessThan(elapsed, 0.2, "Generating 50 views should take less than 200ms")
        }

        func testGeneratePerformance() {
            let yaml = """
                - componentType: Badge
                  properties:
                    text: "Test"
                    level: info
                """

            measure {
                _ = try? YAMLViewGenerator.generateView(fromYAML: yaml)
            }
        }

        // MARK: - Integration Tests

        func testFullPipelineParseValidateGenerate() throws {
            let yaml = """
                - componentType: Badge
                  properties:
                    text: "Pipeline Test"
                    level: success
                    showIcon: true
                """

            // Parse
            let descriptions = try YAMLParser.parse(yaml)
            XCTAssertEqual(descriptions.count, 1)

            // Validate
            try YAMLValidator.validate(descriptions[0])

            // Generate
            let view = try YAMLViewGenerator.generateView(from: descriptions[0])
            XCTAssertNotNil(view)
        }

        func testGenerateAllComponentTypes() throws {
            let yaml = """
                - componentType: Badge
                  properties:
                    text: "Badge"
                    level: info
                ---
                - componentType: Card
                  properties:
                    elevation: low
                ---
                - componentType: KeyValueRow
                  properties:
                    key: "Key"
                    value: "Value"
                ---
                - componentType: SectionHeader
                  properties:
                    title: "Section"
                ---
                - componentType: InspectorPattern
                  properties:
                    title: "Inspector"
                """

            let descriptions = try YAMLParser.parse(yaml)
            XCTAssertEqual(descriptions.count, 5)

            for description in descriptions {
                try YAMLValidator.validate(description)
                let view = try YAMLViewGenerator.generateView(from: description)
                XCTAssertNotNil(view)
            }
        }
    }

#else
    // Placeholder test for Linux where SwiftUI is not available
    import XCTest

    @available(iOS 17.0, macOS 14.0, *)
    final class YAMLViewGeneratorTests: XCTestCase {
        func testSwiftUINotAvailable() {
            // This test exists to ensure the test target compiles on Linux
            XCTAssertTrue(true, "SwiftUI view generation tests require macOS/iOS")
        }
    }
#endif
