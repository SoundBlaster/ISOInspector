import Foundation

/// Validates parsed YAML component descriptions against the FoundationUI ComponentSchema.
///
/// The YAMLValidator ensures that component definitions are well-formed and contain
/// valid property values before attempting to generate SwiftUI views.
///
/// ## Overview
///
/// Validation includes:
/// - Component type verification (must match known types)
/// - Required property presence
/// - Property type checking (String, Bool, Int, Double)
/// - Enum value validation
/// - Numeric bounds checking
/// - Composition rules (no circular references)
///
/// ## Usage
///
/// Validate a single component:
/// ```swift
/// let description = ComponentDescription(
///     componentType: "Badge",
///     properties: ["text": "Success", "level": "success"]
/// )
/// try YAMLValidator.validate(description)
/// ```
///
/// Validate multiple components:
/// ```swift
/// let descriptions = try YAMLParser.parse(yamlString)
/// try YAMLValidator.validate(descriptions)
/// ```
///
/// ## Topics
///
/// ### Validation Methods
/// - ``validate(_:)-4v8zb``
/// - ``validate(_:)-8c9zt``
///
/// ### Error Types
/// - ``ValidationError``
///
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLValidator {

    // MARK: - Error Types

    /// Errors that can occur during component validation.
    public enum ValidationError: Error, LocalizedError {
        /// The component type is not recognized
        case unknownComponentType(String)

        /// A required property is missing
        case missingRequiredProperty(component: String, property: String)

        /// A property has an invalid type
        case invalidPropertyType(component: String, property: String, expected: String, actual: String)

        /// An enum property has an invalid value
        case invalidEnumValue(component: String, property: String, value: String, validValues: [String])

        /// A numeric property is out of bounds
        case valueOutOfBounds(component: String, property: String, value: Any, min: Any?, max: Any?)

        /// Invalid component composition (e.g., circular reference)
        case invalidComposition(String)

        public var errorDescription: String? {
            switch self {
            case .unknownComponentType(let type):
                return "Unknown component type '\(type)'. Valid types: \(Schema.allComponentTypes.joined(separator: ", "))"

            case .missingRequiredProperty(let component, let property):
                return "Missing required property '\(property)' in \(component) component"

            case .invalidPropertyType(let component, let property, let expected, let actual):
                return "Invalid type for property '\(property)' in \(component): expected \(expected), got \(actual)"

            case .invalidEnumValue(let component, let property, let value, let validValues):
                let suggestion = Schema.suggestCorrection(for: value, in: validValues)
                let suggestionText = suggestion.map { ". Did you mean '\($0)'?" } ?? ""
                return "Invalid value '\(value)' for property '\(property)' in \(component). Valid values: [\(validValues.joined(separator: ", "))]\(suggestionText)"

            case .valueOutOfBounds(let component, let property, let value, let min, let max):
                var boundsText = ""
                if let min = min, let max = max {
                    boundsText = " (must be between \(min) and \(max))"
                } else if let min = min {
                    boundsText = " (must be >= \(min))"
                } else if let max = max {
                    boundsText = " (must be <= \(max))"
                }
                return "Value '\(value)' for property '\(property)' in \(component) is out of bounds\(boundsText)"

            case .invalidComposition(let details):
                return "Invalid component composition: \(details)"
            }
        }
    }

    // MARK: - Public Validation Methods

    /// Validates a single component description against the schema.
    ///
    /// Checks that the component type is valid, all required properties are present,
    /// property types are correct, enum values are valid, and numeric values are within bounds.
    ///
    /// - Parameter description: The component description to validate
    /// - Throws: ``ValidationError`` if validation fails
    public static func validate(_ description: YAMLParser.ComponentDescription) throws {
        // Validate component type
        guard Schema.allComponentTypes.contains(description.componentType) else {
            throw ValidationError.unknownComponentType(description.componentType)
        }

        // Get schema for this component type
        let schema = Schema.schema(for: description.componentType)

        // Validate required properties
        for requiredProperty in schema.requiredProperties {
            guard description.properties[requiredProperty] != nil else {
                throw ValidationError.missingRequiredProperty(
                    component: description.componentType,
                    property: requiredProperty
                )
            }
        }

        // Validate each property
        for (propertyName, propertyValue) in description.properties {
            try validateProperty(
                name: propertyName,
                value: propertyValue,
                componentType: description.componentType,
                schema: schema
            )
        }

        // Validate nested content recursively
        if let content = description.content {
            for nestedComponent in content {
                try validate(nestedComponent)
            }
        }
    }

    /// Validates an array of component descriptions.
    ///
    /// Validates each component individually and checks for invalid composition patterns.
    ///
    /// - Parameter descriptions: Array of component descriptions to validate
    /// - Throws: ``ValidationError`` if any validation fails
    public static func validate(_ descriptions: [YAMLParser.ComponentDescription]) throws {
        for description in descriptions {
            try validate(description)
        }

        // Check for composition issues (circular references)
        try validateComposition(descriptions)
    }

    // MARK: - Private Validation Helpers

    /// Validates a single property value.
    private static func validateProperty(
        name: String,
        value: Any,
        componentType: String,
        schema: ComponentSchema
    ) throws {
        // Check if property is known (either required or optional)
        let allProperties = schema.requiredProperties + schema.optionalProperties.keys
        guard allProperties.contains(name) else {
            // Unknown property - we'll allow it but could warn
            return
        }

        // Get expected type
        let expectedType = schema.optionalProperties[name] ?? schema.propertyType(for: name)

        // Validate based on expected type
        switch expectedType {
        case "String":
            guard value is String else {
                throw ValidationError.invalidPropertyType(
                    component: componentType,
                    property: name,
                    expected: "String",
                    actual: "\(type(of: value))"
                )
            }

        case "Bool":
            guard value is Bool else {
                throw ValidationError.invalidPropertyType(
                    component: componentType,
                    property: name,
                    expected: "Bool",
                    actual: "\(type(of: value))"
                )
            }

        case "Int":
            guard value is Int else {
                throw ValidationError.invalidPropertyType(
                    component: componentType,
                    property: name,
                    expected: "Int",
                    actual: "\(type(of: value))"
                )
            }

        case "Double":
            guard value is Double || value is Int else {
                throw ValidationError.invalidPropertyType(
                    component: componentType,
                    property: name,
                    expected: "Double",
                    actual: "\(type(of: value))"
                )
            }

        default:
            // Check if it's an enum type
            if let validValues = schema.enumValues(for: name) {
                guard let stringValue = value as? String else {
                    throw ValidationError.invalidPropertyType(
                        component: componentType,
                        property: name,
                        expected: "String (enum)",
                        actual: "\(type(of: value))"
                    )
                }
                guard validValues.contains(stringValue) else {
                    throw ValidationError.invalidEnumValue(
                        component: componentType,
                        property: name,
                        value: stringValue,
                        validValues: validValues
                    )
                }
            }
        }

        // Validate numeric bounds if applicable
        if let bounds = schema.numericBounds(for: name) {
            if let intValue = value as? Int {
                if let min = bounds.min, intValue < min {
                    throw ValidationError.valueOutOfBounds(
                        component: componentType,
                        property: name,
                        value: intValue,
                        min: min,
                        max: bounds.max
                    )
                }
                if let max = bounds.max, intValue > max {
                    throw ValidationError.valueOutOfBounds(
                        component: componentType,
                        property: name,
                        value: intValue,
                        min: bounds.min,
                        max: max
                    )
                }
            } else if let doubleValue = value as? Double {
                if let min = bounds.min, doubleValue < Double(min) {
                    throw ValidationError.valueOutOfBounds(
                        component: componentType,
                        property: name,
                        value: doubleValue,
                        min: min,
                        max: bounds.max
                    )
                }
                if let max = bounds.max, doubleValue > Double(max) {
                    throw ValidationError.valueOutOfBounds(
                        component: componentType,
                        property: name,
                        value: doubleValue,
                        min: bounds.min,
                        max: max
                    )
                }
            }
        }
    }

    /// Validates component composition (no circular references, valid nesting).
    private static func validateComposition(_ descriptions: [YAMLParser.ComponentDescription]) throws {
        // Check for circular references by tracking visited component IDs
        // For now, we'll just check nesting depth
        for description in descriptions {
            try validateNestingDepth(description, currentDepth: 0, maxDepth: 20)
        }
    }

    /// Validates that nesting depth doesn't exceed maximum (prevents circular references).
    private static func validateNestingDepth(
        _ description: YAMLParser.ComponentDescription,
        currentDepth: Int,
        maxDepth: Int
    ) throws {
        guard currentDepth < maxDepth else {
            throw ValidationError.invalidComposition(
                "Maximum nesting depth (\(maxDepth)) exceeded. Possible circular reference in \(description.componentType)"
            )
        }

        if let content = description.content {
            for nestedComponent in content {
                try validateNestingDepth(nestedComponent, currentDepth: currentDepth + 1, maxDepth: maxDepth)
            }
        }
    }

    // MARK: - Schema Definition

    /// Internal schema definition for component validation.
    private struct ComponentSchema {
        let componentType: String
        let requiredProperties: [String]
        let optionalProperties: [String: String]
        let enums: [String: [String]]
        let bounds: [String: (min: Int?, max: Int?)]

        func propertyType(for property: String) -> String {
            return optionalProperties[property] ?? "String"
        }

        func enumValues(for property: String) -> [String]? {
            return enums[property]
        }

        func numericBounds(for property: String) -> (min: Int?, max: Int?)? {
            return bounds[property]
        }
    }

    /// Schema definitions for all component types.
    private struct Schema {
        static let allComponentTypes: [String] = [
            "Badge", "Card", "KeyValueRow", "SectionHeader",
            "InspectorPattern", "SidebarPattern", "ToolbarPattern", "BoxTreePattern"
        ]

        static func schema(for componentType: String) -> ComponentSchema {
            switch componentType {
            case "Badge":
                return ComponentSchema(
                    componentType: "Badge",
                    requiredProperties: ["text", "level"],
                    optionalProperties: ["showIcon": "Bool"],
                    enums: ["level": ["info", "warning", "error", "success"]],
                    bounds: [:]
                )

            case "Card":
                return ComponentSchema(
                    componentType: "Card",
                    requiredProperties: [],
                    optionalProperties: [
                        "elevation": "String",
                        "cornerRadius": "Double",
                        "material": "String"
                    ],
                    enums: [
                        "elevation": ["none", "low", "medium", "high"],
                        "material": ["thin", "regular", "thick", "ultraThin", "ultraThick"]
                    ],
                    bounds: ["cornerRadius": (min: 0, max: 50)]
                )

            case "KeyValueRow":
                return ComponentSchema(
                    componentType: "KeyValueRow",
                    requiredProperties: ["key", "value"],
                    optionalProperties: [
                        "layout": "String",
                        "isCopyable": "Bool"
                    ],
                    enums: ["layout": ["horizontal", "vertical"]],
                    bounds: [:]
                )

            case "SectionHeader":
                return ComponentSchema(
                    componentType: "SectionHeader",
                    requiredProperties: ["title"],
                    optionalProperties: ["showDivider": "Bool"],
                    enums: [:],
                    bounds: [:]
                )

            case "InspectorPattern":
                return ComponentSchema(
                    componentType: "InspectorPattern",
                    requiredProperties: ["title"],
                    optionalProperties: ["material": "String"],
                    enums: ["material": ["thin", "regular", "thick", "ultraThin", "ultraThick"]],
                    bounds: [:]
                )

            case "SidebarPattern":
                return ComponentSchema(
                    componentType: "SidebarPattern",
                    requiredProperties: ["sections"],
                    optionalProperties: ["selection": "String"],
                    enums: [:],
                    bounds: [:]
                )

            case "ToolbarPattern":
                return ComponentSchema(
                    componentType: "ToolbarPattern",
                    requiredProperties: ["items"],
                    optionalProperties: [:],
                    enums: [:],
                    bounds: [:]
                )

            case "BoxTreePattern":
                return ComponentSchema(
                    componentType: "BoxTreePattern",
                    requiredProperties: ["nodeCount"],
                    optionalProperties: ["level": "Int"],
                    enums: [:],
                    bounds: ["level": (min: 0, max: nil), "nodeCount": (min: 0, max: nil)]
                )

            default:
                return ComponentSchema(
                    componentType: componentType,
                    requiredProperties: [],
                    optionalProperties: [:],
                    enums: [:],
                    bounds: [:]
                )
            }
        }

        /// Suggests a correction for a misspelled enum value using Levenshtein distance.
        static func suggestCorrection(for value: String, in validValues: [String]) -> String? {
            let suggestions = validValues.map { (candidate: $0, distance: levenshteinDistance($0, value)) }
            let closest = suggestions.min { $0.distance < $1.distance }
            // Only suggest if distance is reasonable (< 3 edits)
            if let closest = closest, closest.distance < 3 {
                return closest.candidate
            }
            return nil
        }

        /// Calculates Levenshtein distance between two strings.
        private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
            let s1 = Array(s1.lowercased())
            let s2 = Array(s2.lowercased())
            var dist = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

            for i in 0...s1.count {
                dist[i][0] = i
            }
            for j in 0...s2.count {
                dist[0][j] = j
            }

            for i in 1...s1.count {
                for j in 1...s2.count {
                    if s1[i - 1] == s2[j - 1] {
                        dist[i][j] = dist[i - 1][j - 1]
                    } else {
                        dist[i][j] = min(
                            dist[i - 1][j] + 1,    // deletion
                            dist[i][j - 1] + 1,    // insertion
                            dist[i - 1][j - 1] + 1 // substitution
                        )
                    }
                }
            }

            return dist[s1.count][s2.count]
        }
    }
}
