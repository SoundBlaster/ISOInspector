import XCTest
@testable import FoundationUI

/// Integration tests for YAML Agent Support pipeline.
///
/// Tests the complete workflow:
/// 1. Parse YAML component definitions
/// 2. Validate against schema
/// 3. Generate SwiftUI views (when available)
///
/// Uses real example YAML files from AgentSupport/Examples/
///
@available(iOS 17.0, macOS 14.0, *)
final class YAMLIntegrationTests: XCTestCase {

    // MARK: - Badge Examples Integration Tests

    func testParseBadgeExamples() throws {
        let yaml = """
        # Info Badge
        - componentType: Badge
          properties:
            text: "Info"
            level: info
            showIcon: true
          semantics: "Information status badge"

        # Warning Badge
        - componentType: Badge
          properties:
            text: "Warning"
            level: warning
            showIcon: true
          semantics: "Warning status badge"

        # Error Badge
        - componentType: Badge
          properties:
            text: "Error"
            level: error
            showIcon: true
          semantics: "Error status badge"

        # Success Badge
        - componentType: Badge
          properties:
            text: "Success"
            level: success
            showIcon: true
          semantics: "Success status badge"

        # Badge without icon
        - componentType: Badge
          properties:
            text: "No Icon"
            level: info
            showIcon: false
          semantics: "Badge without icon"

        # Badge with long text
        - componentType: Badge
          properties:
            text: "Very Long Badge Text"
            level: warning
            showIcon: false
          semantics: "Badge with long text content"
        """

        // Parse
        let descriptions = try YAMLParser.parse(yaml)
        XCTAssertEqual(descriptions.count, 6, "Should parse 6 badge examples")

        // Validate all
        try YAMLValidator.validate(descriptions)

        // Verify properties
        XCTAssertEqual(descriptions[0].properties["level"] as? String, "info")
        XCTAssertEqual(descriptions[1].properties["level"] as? String, "warning")
        XCTAssertEqual(descriptions[2].properties["level"] as? String, "error")
        XCTAssertEqual(descriptions[3].properties["level"] as? String, "success")
        XCTAssertEqual(descriptions[4].properties["showIcon"] as? Bool, false)

        #if canImport(SwiftUI)
        // Generate views (only on platforms with SwiftUI)
        for description in descriptions {
            let view = try YAMLViewGenerator.generateView(from: description)
            XCTAssertNotNil(view)
        }
        #endif
    }

    // MARK: - Inspector Pattern Examples Integration Tests

    func testParseInspectorPatternExamples() throws {
        let yaml = """
        # Simple Inspector Pattern
        - componentType: InspectorPattern
          properties:
            title: "File Inspector"
            material: regular
          content:
            - componentType: SectionHeader
              properties:
                title: "Basic Information"
            - componentType: KeyValueRow
              properties:
                key: "Name"
                value: "movie.mp4"
            - componentType: KeyValueRow
              properties:
                key: "Size"
                value: "1.5 GB"

        # Inspector with Status Badge
        - componentType: InspectorPattern
          properties:
            title: "Box Inspector"
          content:
            - componentType: SectionHeader
              properties:
                title: "Box Status"
            - componentType: Badge
              properties:
                text: "Valid"
                level: success

        # Inspector with Multiple Sections
        - componentType: InspectorPattern
          properties:
            title: "Detailed Inspector"
            material: thick
          content:
            - componentType: SectionHeader
              properties:
                title: "Properties"
            - componentType: KeyValueRow
              properties:
                key: "Type"
                value: "ftyp"
            - componentType: SectionHeader
              properties:
                title: "Metadata"
            - componentType: KeyValueRow
              properties:
                key: "Created"
                value: "2024-11-10"
        """

        // Parse
        let descriptions = try YAMLParser.parse(yaml)
        XCTAssertEqual(descriptions.count, 3, "Should parse 3 inspector examples")

        // Validate all
        try YAMLValidator.validate(descriptions)

        // Verify content structure
        XCTAssertNotNil(descriptions[0].content)
        XCTAssertEqual(descriptions[0].content?.count, 3)
        XCTAssertEqual(descriptions[0].content?[0].componentType, "SectionHeader")
        XCTAssertEqual(descriptions[0].content?[1].componentType, "KeyValueRow")

        #if canImport(SwiftUI)
        // Generate views
        for description in descriptions {
            let view = try YAMLViewGenerator.generateView(from: description)
            XCTAssertNotNil(view)
        }
        #endif
    }

    // MARK: - Complete UI Example Integration Tests

    func testParseCompleteUIExample() throws {
        let yaml = """
        # ISO Inspector Complete UI Example
        - componentType: InspectorPattern
          properties:
            title: "ISO Box Inspector"
            material: regular
          semantics: "Main inspector for ISO box structure"
          content:
            # Header Section
            - componentType: SectionHeader
              properties:
                title: "Box Information"
                showDivider: true

            # Basic Info
            - componentType: KeyValueRow
              properties:
                key: "Type"
                value: "ftyp"
                layout: horizontal
                isCopyable: true

            - componentType: KeyValueRow
              properties:
                key: "Size"
                value: "32 bytes"
                layout: horizontal
                isCopyable: false

            # Status Badge
            - componentType: Badge
              properties:
                text: "Valid Structure"
                level: success
                showIcon: true

            # Metadata Section
            - componentType: SectionHeader
              properties:
                title: "Metadata"
                showDivider: true

            - componentType: KeyValueRow
              properties:
                key: "Major Brand"
                value: "isom"
                layout: horizontal
                isCopyable: true

            - componentType: KeyValueRow
              properties:
                key: "Minor Version"
                value: "0"
                layout: horizontal
                isCopyable: false

            # Nested Card with Details
            - componentType: Card
              properties:
                elevation: low
                cornerRadius: 8
                material: thin
              content:
                - componentType: SectionHeader
                  properties:
                    title: "Advanced Details"
                - componentType: KeyValueRow
                  properties:
                    key: "Offset"
                    value: "0x0000"
                    isCopyable: true
                - componentType: Badge
                  properties:
                    text: "Root Box"
                    level: info
        """

        // Parse
        let descriptions = try YAMLParser.parse(yaml)
        XCTAssertEqual(descriptions.count, 1, "Should parse 1 complete UI example")

        // Validate
        try YAMLValidator.validate(descriptions)

        // Verify complex structure
        let inspector = descriptions[0]
        XCTAssertEqual(inspector.componentType, "InspectorPattern")
        XCTAssertNotNil(inspector.content)
        XCTAssertEqual(inspector.content?.count, 10)

        // Verify nested content
        let nestedCard = try XCTUnwrap(inspector.content?.last)
        XCTAssertEqual(nestedCard.componentType, "Card")
        XCTAssertEqual(nestedCard.content?.count, 4)

        #if canImport(SwiftUI)
        // Generate complete UI
        let view = try YAMLViewGenerator.generateView(from: inspector)
        XCTAssertNotNil(view)
        #endif
    }

    // MARK: - Error Handling Integration Tests

    func testParseInvalidYAMLGracefully() {
        let yaml = """
        - componentType: Badge
          properties:
            text: "Invalid"
            level: invalid-level
        """

        do {
            let descriptions = try YAMLParser.parse(yaml)
            XCTAssertThrowsError(try YAMLValidator.validate(descriptions))
        } catch {
            XCTFail("Parsing should succeed even if validation fails: \(error)")
        }
    }

    func testFullPipelineWithValidation() throws {
        let yaml = """
        - componentType: Badge
          properties:
            text: "Test"
            level: info
        """

        // Step 1: Parse
        let descriptions = try YAMLParser.parse(yaml)
        XCTAssertEqual(descriptions.count, 1)

        // Step 2: Validate
        XCTAssertNoThrow(try YAMLValidator.validate(descriptions[0]))

        // Step 3: Generate (if SwiftUI available)
        #if canImport(SwiftUI)
        let view = try YAMLViewGenerator.generateView(from: descriptions[0])
        XCTAssertNotNil(view)
        #endif
    }

    // MARK: - Round-Trip Tests

    func testAgentDescribableToYAMLToView() throws {
        // This test simulates the full agent workflow:
        // 1. Agent creates component description (via AgentDescribable)
        // 2. Description is serialized to YAML
        // 3. YAML is parsed back
        // 4. Parsed description is validated
        // 5. View is generated

        // Step 1: Create description (simulating AgentDescribable)
        let originalDescription = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Agent Generated",
                "level": "success",
                "showIcon": true
            ],
            semantics: "This badge was generated by an AI agent"
        )

        // Step 2: Simulate YAML serialization (manually for this test)
        let yaml = """
        - componentType: Badge
          properties:
            text: "Agent Generated"
            level: success
            showIcon: true
          semantics: "This badge was generated by an AI agent"
        """

        // Step 3: Parse YAML
        let parsedDescriptions = try YAMLParser.parse(yaml)
        XCTAssertEqual(parsedDescriptions.count, 1)

        let parsedDescription = parsedDescriptions[0]

        // Step 4: Validate
        try YAMLValidator.validate(parsedDescription)

        // Step 5: Verify round-trip consistency
        XCTAssertEqual(parsedDescription.componentType, originalDescription.componentType)
        XCTAssertEqual(parsedDescription.properties["text"] as? String, originalDescription.properties["text"] as? String)
        XCTAssertEqual(parsedDescription.properties["level"] as? String, originalDescription.properties["level"] as? String)
        XCTAssertEqual(parsedDescription.semantics, originalDescription.semantics)

        // Step 6: Generate view (if SwiftUI available)
        #if canImport(SwiftUI)
        let view = try YAMLViewGenerator.generateView(from: parsedDescription)
        XCTAssertNotNil(view)
        #endif
    }

    // MARK: - Performance Integration Tests

    func testLargeYAMLFilePerformance() throws {
        // Generate a large YAML file with 100 components
        var yaml = ""
        for i in 0..<100 {
            yaml += """
            - componentType: Badge
              properties:
                text: "Badge \(i)"
                level: \(["info", "warning", "error", "success"][i % 4])
                showIcon: \(i % 2 == 0)

            """
        }

        // Measure complete pipeline
        let start = Date()

        // Parse
        let descriptions = try YAMLParser.parse(yaml)
        let parseTime = Date().timeIntervalSince(start)

        // Validate
        let validateStart = Date()
        try YAMLValidator.validate(descriptions)
        let validateTime = Date().timeIntervalSince(validateStart)

        // Generate (sample - don't generate all 100)
        #if canImport(SwiftUI)
        let generateStart = Date()
        for i in 0..<10 {
            _ = try YAMLViewGenerator.generateView(from: descriptions[i])
        }
        let generateTime = Date().timeIntervalSince(generateStart)
        #else
        let generateTime: TimeInterval = 0
        #endif

        // Verify performance targets
        XCTAssertLessThan(parseTime, 0.1, "Parsing 100 components should take <100ms")
        XCTAssertLessThan(validateTime, 0.05, "Validating 100 components should take <50ms")
        #if canImport(SwiftUI)
        XCTAssertLessThan(generateTime, 0.2, "Generating 10 views should take <200ms")
        #endif

        print("Performance results:")
        print("  Parse: \(parseTime * 1000)ms")
        print("  Validate: \(validateTime * 1000)ms")
        print("  Generate: \(generateTime * 1000)ms")
    }

    // MARK: - Real-World Usage Scenario Tests

    func testISOInspectorUseCase() throws {
        let yaml = """
        # ISO Box Hierarchy Inspector
        - componentType: InspectorPattern
          properties:
            title: "ftyp Box"
          content:
            - componentType: Badge
              properties:
                text: "File Type Box"
                level: info

            - componentType: SectionHeader
              properties:
                title: "Properties"

            - componentType: KeyValueRow
              properties:
                key: "Major Brand"
                value: "isom"
                isCopyable: true

            - componentType: KeyValueRow
              properties:
                key: "Minor Version"
                value: "512"
                isCopyable: true

            - componentType: KeyValueRow
              properties:
                key: "Compatible Brands"
                value: "isom, iso2, avc1, mp41"
                layout: vertical
                isCopyable: true

            - componentType: Card
              properties:
                elevation: low
              content:
                - componentType: SectionHeader
                  properties:
                    title: "Validation"
                - componentType: Badge
                  properties:
                    text: "Structure Valid"
                    level: success
                - componentType: Badge
                  properties:
                    text: "Brands Compatible"
                    level: success
        """

        // Full pipeline test
        let descriptions = try YAMLParser.parse(yaml)
        try YAMLValidator.validate(descriptions)

        let inspector = descriptions[0]
        XCTAssertEqual(inspector.componentType, "InspectorPattern")
        XCTAssertEqual(inspector.properties["title"] as? String, "ftyp Box")
        XCTAssertEqual(inspector.content?.count, 7)

        #if canImport(SwiftUI)
        let view = try YAMLViewGenerator.generateView(from: inspector)
        XCTAssertNotNil(view)
        #endif
    }
}
