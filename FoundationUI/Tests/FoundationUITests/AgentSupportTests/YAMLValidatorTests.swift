import XCTest
@testable import FoundationUI

/// Unit tests for YAMLValidator component.
///
/// Tests schema validation functionality including:
/// - Component type validation
/// - Required property validation
/// - Property type validation
/// - Enum value validation
/// - Numeric bounds validation
/// - Composition validation
/// - Error message quality
///
@available(iOS 17.0, macOS 14.0, *)
final class YAMLValidatorTests: XCTestCase {

    // MARK: - Valid Component Tests

    func testValidateBadge() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "info",
                "showIcon": true
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    func testValidateCard() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "elevation": "medium",
                "cornerRadius": 12,
                "material": "regular"
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    func testValidateKeyValueRow() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "KeyValueRow",
            properties: [
                "key": "Size",
                "value": "1024 bytes",
                "layout": "horizontal",
                "isCopyable": true
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    func testValidateSectionHeader() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "SectionHeader",
            properties: [
                "title": "Metadata",
                "showDivider": true
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    func testValidateInspectorPattern() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "InspectorPattern",
            properties: [
                "title": "Inspector",
                "material": "thick"
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    // MARK: - Component Type Validation

    func testRejectUnknownComponentType() {
        let description = YAMLParser.ComponentDescription(
            componentType: "UnknownComponent",
            properties: [:]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.unknownComponentType(let type) = error else {
                XCTFail("Expected unknownComponentType error, got \(error)")
                return
            }
            XCTAssertEqual(type, "UnknownComponent")
        }
    }

    // MARK: - Required Property Validation

    func testRejectBadgeMissingText() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "level": "info"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.missingRequiredProperty(let component, let property) = error else {
                XCTFail("Expected missingRequiredProperty error, got \(error)")
                return
            }
            XCTAssertEqual(component, "Badge")
            XCTAssertEqual(property, "text")
        }
    }

    func testRejectBadgeMissingLevel() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.missingRequiredProperty(let component, let property) = error else {
                XCTFail("Expected missingRequiredProperty error, got \(error)")
                return
            }
            XCTAssertEqual(component, "Badge")
            XCTAssertEqual(property, "level")
        }
    }

    func testRejectKeyValueRowMissingKey() {
        let description = YAMLParser.ComponentDescription(
            componentType: "KeyValueRow",
            properties: [
                "value": "1024"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.missingRequiredProperty = error else {
                XCTFail("Expected missingRequiredProperty error, got \(error)")
                return
            }
        }
    }

    // MARK: - Property Type Validation

    func testRejectInvalidPropertyType() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": 123,  // Should be String
                "level": "info"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.invalidPropertyType = error else {
                XCTFail("Expected invalidPropertyType error, got \(error)")
                return
            }
        }
    }

    func testRejectInvalidBoolType() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "info",
                "showIcon": "true"  // Should be Bool
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.invalidPropertyType = error else {
                XCTFail("Expected invalidPropertyType error, got \(error)")
                return
            }
        }
    }

    // MARK: - Enum Value Validation

    func testRejectInvalidBadgeLevel() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "invalid"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.invalidEnumValue(let component, let property, let value, let validValues) = error else {
                XCTFail("Expected invalidEnumValue error, got \(error)")
                return
            }
            XCTAssertEqual(component, "Badge")
            XCTAssertEqual(property, "level")
            XCTAssertEqual(value, "invalid")
            XCTAssertEqual(validValues, ["info", "warning", "error", "success"])
        }
    }

    func testRejectInvalidElevation() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "elevation": "super-high"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.invalidEnumValue = error else {
                XCTFail("Expected invalidEnumValue error, got \(error)")
                return
            }
        }
    }

    func testRejectInvalidMaterial() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "material": "plastic"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.invalidEnumValue(_, let property, let value, let validValues) = error else {
                XCTFail("Expected invalidEnumValue error, got \(error)")
                return
            }
            XCTAssertEqual(property, "material")
            XCTAssertEqual(value, "plastic")
            XCTAssertTrue(validValues.contains("thin"))
            XCTAssertTrue(validValues.contains("regular"))
            XCTAssertTrue(validValues.contains("thick"))
        }
    }

    // MARK: - Numeric Bounds Validation

    func testRejectCornerRadiusTooHigh() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "cornerRadius": 100
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.valueOutOfBounds(let component, let property, let value, let min, let max) = error else {
                XCTFail("Expected valueOutOfBounds error, got \(error)")
                return
            }
            XCTAssertEqual(component, "Card")
            XCTAssertEqual(property, "cornerRadius")
            XCTAssertEqual(value as? Int, 100)
            XCTAssertEqual(min as? Int, 0)
            XCTAssertEqual(max as? Int, 50)
        }
    }

    func testRejectNegativeCornerRadius() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "cornerRadius": -5
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            guard case YAMLValidator.ValidationError.valueOutOfBounds = error else {
                XCTFail("Expected valueOutOfBounds error, got \(error)")
                return
            }
        }
    }

    func testAcceptValidCornerRadius() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "cornerRadius": 12
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    // MARK: - Typo Suggestion Tests

    func testSuggestTypoCorrection() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "erro"  // Should be "error"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            if case YAMLValidator.ValidationError.invalidEnumValue = error {
                let errorMessage = error.localizedDescription
                XCTAssertTrue(errorMessage.contains("Did you mean 'error'?"))
            } else {
                XCTFail("Expected invalidEnumValue error with suggestion")
            }
        }
    }

    func testSuggestWarningTypo() {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "waring"  // Should be "warning"
            ]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(description)) { error in
            if case YAMLValidator.ValidationError.invalidEnumValue = error {
                let errorMessage = error.localizedDescription
                XCTAssertTrue(errorMessage.contains("Did you mean 'warning'?"))
            } else {
                XCTFail("Expected invalidEnumValue error with suggestion")
            }
        }
    }

    // MARK: - Nested Component Validation

    func testValidateNestedComponents() throws {
        let nestedBadge = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Nested",
                "level": "success"
            ]
        )

        let card = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [
                "elevation": "low"
            ],
            content: [nestedBadge]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(card))
    }

    func testRejectInvalidNestedComponent() {
        let invalidBadge = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Invalid"
                // Missing required "level" property
            ]
        )

        let card = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [:],
            content: [invalidBadge]
        )

        XCTAssertThrowsError(try YAMLValidator.validate(card)) { error in
            guard case YAMLValidator.ValidationError.missingRequiredProperty = error else {
                XCTFail("Expected missingRequiredProperty error, got \(error)")
                return
            }
        }
    }

    // MARK: - Composition Validation

    func testRejectExcessiveNesting() {
        // Create deeply nested structure (21 levels)
        var current = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: ["text": "Deep", "level": "info"]
        )

        for _ in 0..<20 {
            current = YAMLParser.ComponentDescription(
                componentType: "Card",
                properties: [:],
                content: [current]
            )
        }

        XCTAssertThrowsError(try YAMLValidator.validate(current)) { error in
            guard case YAMLValidator.ValidationError.invalidComposition(let details) = error else {
                XCTFail("Expected invalidComposition error, got \(error)")
                return
            }
            XCTAssertTrue(details.contains("Maximum nesting depth"))
        }
    }

    func testAcceptReasonableNesting() throws {
        // Create moderately nested structure (10 levels)
        var current = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: ["text": "Moderate", "level": "info"]
        )

        for _ in 0..<10 {
            current = YAMLParser.ComponentDescription(
                componentType: "Card",
                properties: [:],
                content: [current]
            )
        }

        XCTAssertNoThrow(try YAMLValidator.validate(current))
    }

    // MARK: - Multiple Components Validation

    func testValidateMultipleComponents() throws {
        let descriptions = [
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Test1", "level": "info"]
            ),
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Test2", "level": "warning"]
            ),
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Test3", "level": "error"]
            )
        ]

        XCTAssertNoThrow(try YAMLValidator.validate(descriptions))
    }

    func testRejectMultipleComponentsWithInvalid() {
        let descriptions = [
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Valid", "level": "info"]
            ),
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Invalid", "level": "invalid-level"]
            ),
            YAMLParser.ComponentDescription(
                componentType: "Badge",
                properties: ["text": "Valid2", "level": "success"]
            )
        ]

        XCTAssertThrowsError(try YAMLValidator.validate(descriptions))
    }

    // MARK: - Optional Properties

    func testAcceptMissingOptionalProperties() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "Badge",
            properties: [
                "text": "Test",
                "level": "info"
                // showIcon is optional, not provided
            ]
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }

    func testAcceptCardWithoutOptionalProperties() throws {
        let description = YAMLParser.ComponentDescription(
            componentType: "Card",
            properties: [:]  // All Card properties are optional
        )

        XCTAssertNoThrow(try YAMLValidator.validate(description))
    }
}
