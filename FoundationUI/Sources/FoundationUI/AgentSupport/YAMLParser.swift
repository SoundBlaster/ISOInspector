import Foundation
import Yams

/// Parses YAML component definitions into structured ComponentDescription objects.
///
/// The YAMLParser reads YAML files or strings containing FoundationUI component definitions
/// and converts them into structured `ComponentDescription` objects that can be validated
/// and used to generate SwiftUI views.
///
/// ## Overview
///
/// YAML Parser supports:
/// - Single and multi-document YAML files
/// - Nested component hierarchies
/// - All FoundationUI component types (Badge, Card, KeyValueRow, etc.)
/// - Rich property types (String, Bool, Int, Double, Arrays, Dictionaries)
///
/// ## Usage
///
/// Parse a YAML string:
/// ```swift
/// let yaml = """
/// - componentType: Badge
///   properties:
///     text: "Success"
///     level: success
///     showIcon: true
/// """
/// let descriptions = try YAMLParser.parse(yaml)
/// ```
///
/// Parse a YAML file:
/// ```swift
/// let url = URL(fileURLWithPath: "/path/to/components.yaml")
/// let descriptions = try YAMLParser.parse(fileAt: url)
/// ```
///
/// ## Topics
///
/// ### Parsing Methods
/// - ``parse(_:)``
/// - ``parse(fileAt:)``
///
/// ### Data Structures
/// - ``ComponentDescription``
/// - ``ParseError``
///
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLParser {

    // MARK: - Data Structures

    /// A parsed component description from YAML.
    ///
    /// ComponentDescription represents a single FoundationUI component parsed from YAML,
    /// including its type, properties, optional semantics annotation, and nested content.
    ///
    /// ## Example
    ///
    /// ```yaml
    /// - componentType: Badge
    ///   properties:
    ///     text: "Warning"
    ///     level: warning
    ///   semantics: "Status indicator for validation warnings"
    /// ```
    ///
    /// This YAML produces a ComponentDescription with:
    /// - `componentType`: "Badge"
    /// - `properties`: ["text": "Warning", "level": "warning"]
    /// - `semantics`: "Status indicator for validation warnings"
    /// - `content`: nil
    ///
    public struct ComponentDescription {
        /// The type of component (e.g., "Badge", "Card", "InspectorPattern")
        public let componentType: String

        /// Dictionary of component properties (e.g., text, level, elevation)
        public let properties: [String: Any]

        /// Optional semantic description for AI agents
        public let semantics: String?

        /// Optional nested child components
        public let content: [ComponentDescription]?

        /// Creates a new component description.
        ///
        /// - Parameters:
        ///   - componentType: The type of component
        ///   - properties: Component properties dictionary
        ///   - semantics: Optional semantic description
        ///   - content: Optional nested components
        public init(
            componentType: String,
            properties: [String: Any] = [:],
            semantics: String? = nil,
            content: [ComponentDescription]? = nil
        ) {
            self.componentType = componentType
            self.properties = properties
            self.semantics = semantics
            self.content = content
        }
    }

    // MARK: - Error Types

    /// Errors that can occur during YAML parsing.
    public enum ParseError: Error, LocalizedError {
        /// The YAML syntax is invalid or malformed
        case invalidYAML(String)

        /// A component definition is missing the required componentType field
        case missingComponentType(line: Int?)

        /// The YAML structure is invalid (not an array or dictionary)
        case invalidStructure(String)

        /// An error occurred reading the file
        case fileReadError(URL, Error)

        public var errorDescription: String? {
            switch self {
            case .invalidYAML(let details):
                return "Invalid YAML syntax: \(details)"
            case .missingComponentType(let line):
                if let line = line {
                    return "Missing required 'componentType' field at line \(line)"
                } else {
                    return "Missing required 'componentType' field"
                }
            case .invalidStructure(let details):
                return
                    "Invalid YAML structure: \(details). Expected array of component definitions or single component."
            case .fileReadError(let url, let error):
                return "Failed to read file at \(url.path): \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Public Parsing Methods

    /// Parses a YAML string into an array of component descriptions.
    ///
    /// Supports both single-document and multi-document YAML (separated by `---`).
    /// Each document should contain either:
    /// - An array of component definitions
    /// - A single component definition (object)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let yaml = """
    /// - componentType: Badge
    ///   properties:
    ///     text: "Info"
    ///     level: info
    /// - componentType: Badge
    ///   properties:
    ///     text: "Warning"
    ///     level: warning
    /// """
    /// let descriptions = try YAMLParser.parse(yaml)
    /// // Returns array of 2 ComponentDescription objects
    /// ```
    ///
    /// - Parameter yamlString: The YAML string to parse
    /// - Returns: Array of parsed component descriptions
    /// - Throws: ``ParseError`` if YAML is invalid or structure is incorrect
    public static func parse(_ yamlString: String) throws -> [ComponentDescription] {
        // Check for empty input
        guard !yamlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParseError.invalidYAML("Empty YAML string")
        }

        // Parse YAML using Yams
        let yamlDocuments: [Any]
        do {
            yamlDocuments = try Array(Yams.load_all(yaml: yamlString))
        } catch {
            throw ParseError.invalidYAML(error.localizedDescription)
        }

        var allDescriptions: [ComponentDescription] = []

        // Process each YAML document
        for (docIndex, document) in yamlDocuments.enumerated() {
            // Handle array of components
            if let componentsArray = document as? [[String: Any]] {
                for (itemIndex, componentDict) in componentsArray.enumerated() {
                    let description = try parseComponentDict(
                        componentDict,
                        documentIndex: docIndex,
                        itemIndex: itemIndex
                    )
                    allDescriptions.append(description)
                }
            }
            // Handle single component
            else if let componentDict = document as? [String: Any] {
                let description = try parseComponentDict(
                    componentDict,
                    documentIndex: docIndex,
                    itemIndex: 0
                )
                allDescriptions.append(description)
            }
            // Invalid structure
            else {
                throw ParseError.invalidStructure(
                    "Document \(docIndex) is neither an array nor an object. Got: \(type(of: document))"
                )
            }
        }

        return allDescriptions
    }

    /// Parses a YAML file into an array of component descriptions.
    ///
    /// Reads the file at the given URL and parses its contents as YAML component definitions.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let url = URL(fileURLWithPath: "/path/to/badge_examples.yaml")
    /// let descriptions = try YAMLParser.parse(fileAt: url)
    /// ```
    ///
    /// - Parameter url: URL of the YAML file to parse
    /// - Returns: Array of parsed component descriptions
    /// - Throws: ``ParseError`` if file cannot be read or YAML is invalid
    public static func parse(fileAt url: URL) throws -> [ComponentDescription] {
        let yamlString: String
        do {
            yamlString = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ParseError.fileReadError(url, error)
        }

        return try parse(yamlString)
    }

    // MARK: - Private Parsing Helpers

    /// Parses a single component dictionary into a ComponentDescription.
    private static func parseComponentDict(
        _ dict: [String: Any],
        documentIndex: Int,
        itemIndex: Int
    ) throws -> ComponentDescription {
        // Extract componentType (required)
        guard let componentType = dict["componentType"] as? String else {
            throw ParseError.missingComponentType(line: nil)
        }

        // Extract properties (optional, defaults to empty)
        let properties = dict["properties"] as? [String: Any] ?? [:]

        // Extract semantics (optional)
        let semantics = dict["semantics"] as? String

        // Extract and parse nested content (optional)
        let content: [ComponentDescription]?
        if let contentArray = dict["content"] as? [[String: Any]] {
            content = try contentArray.enumerated().map { (index, contentDict) in
                try parseComponentDict(
                    contentDict,
                    documentIndex: documentIndex,
                    itemIndex: index
                )
            }
        } else {
            content = nil
        }

        return ComponentDescription(
            componentType: componentType,
            properties: properties,
            semantics: semantics,
            content: content
        )
    }
}
