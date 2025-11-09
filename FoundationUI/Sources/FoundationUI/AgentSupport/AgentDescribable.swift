//
//  AgentDescribable.swift
//  FoundationUI
//
//  Created by AI Assistant on 2025-11-08.
//  Copyright © 2025 ISO Inspector. All rights reserved.
//

import Foundation

/// A protocol that enables AI agents to programmatically generate and manipulate FoundationUI components.
///
/// The `AgentDescribable` protocol provides a standard interface for describing SwiftUI components
/// in a structured, machine-readable format. This allows AI agents (such as Claude Code or 0AL agents)
/// to:
/// - Generate UI components from YAML/JSON descriptions
/// - Introspect existing component configurations
/// - Modify component properties programmatically
/// - Build dynamic user interfaces based on runtime data
///
/// ## Protocol Requirements
///
/// Conforming types must provide three key pieces of information:
///
/// 1. **Component Type**: A unique string identifier for the component type
/// 2. **Properties**: A dictionary of all configurable properties and their current values
/// 3. **Semantics**: A human-readable description of the component's purpose and usage
///
/// ## Usage Example
///
/// ```swift
/// import FoundationUI
///
/// extension Badge: AgentDescribable {
///     public var componentType: String {
///         "Badge"
///     }
///
///     public var properties: [String: Any] {
///         [
///             "text": text,
///             "level": level.rawValue,
///             "showIcon": showIcon
///         ]
///     }
///
///     public var semantics: String {
///         "Status indicator displaying \(level.rawValue) state: \(text)"
///     }
/// }
///
/// // Agent can now introspect the badge:
/// let badge = Badge(text: "Error", level: .error, showIcon: true)
/// print(badge.componentType)  // "Badge"
/// print(badge.properties)     // ["text": "Error", "level": "error", "showIcon": true]
/// print(badge.semantics)      // "Status indicator displaying error state: Error"
/// ```
///
/// ## Serialization for Agents
///
/// The `properties` dictionary is designed to be JSON-serializable, enabling agents to
/// persist and reconstruct component configurations:
///
/// ```swift
/// let badge = Badge(text: "Warning", level: .warning)
/// let jsonData = try JSONSerialization.data(withJSONObject: badge.properties)
///
/// // Agent can send this JSON to external systems or store it for later use
/// ```
///
/// ## Type Safety Considerations
///
/// While `properties` uses `[String: Any]` for maximum flexibility, conforming types should:
/// - Use primitive types (String, Int, Bool, Double) when possible
/// - Ensure all values are JSON-serializable
/// - Document expected property types in the component's documentation
/// - Use enums with `rawValue` for type-safe options (e.g., `level.rawValue`)
///
/// ## YAML Schema Integration
///
/// Components conforming to `AgentDescribable` can be defined in YAML schemas for
/// agent-driven UI generation. See ``ComponentSchema`` for YAML schema definitions.
///
/// ```yaml
/// # Example YAML definition for agent consumption
/// - componentType: Badge
///   properties:
///     text: "Success"
///     level: "success"
///     showIcon: true
///   semantics: "Success indicator for completed operations"
/// ```
///
/// ## Platform Support
///
/// This protocol is available on all FoundationUI-supported platforms:
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
///
/// - ``Badge``
/// - ``Card``
/// - ``KeyValueRow``
/// - ``InspectorPattern``
/// - ``SidebarPattern``
///
/// ## Topics
///
/// ### Required Properties
///
/// - ``componentType``
/// - ``properties``
/// - ``semantics``
///
/// ### Related Protocols
///
/// - `Codable` (for full JSON encoding/decoding)
/// - `Identifiable` (for managing component instances)
///
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public protocol AgentDescribable {

    /// A unique string identifier for the component type.
    ///
    /// This identifier allows agents to distinguish between different component types
    /// and instantiate the correct SwiftUI view. The identifier should be:
    /// - Unique across all FoundationUI components
    /// - Stable across versions (don't change existing identifiers)
    /// - Human-readable (e.g., "Badge", "Card", "InspectorPattern")
    /// - Match the Swift type name by convention
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension Badge: AgentDescribable {
    ///     var componentType: String { "Badge" }
    /// }
    ///
    /// extension Card: AgentDescribable {
    ///     var componentType: String { "Card" }
    /// }
    /// ```
    ///
    /// ## Agent Usage
    ///
    /// Agents use this identifier to map YAML/JSON definitions to Swift types:
    ///
    /// ```swift
    /// func createComponent(from description: AgentDescribable) -> AnyView {
    ///     switch description.componentType {
    ///     case "Badge":
    ///         return AnyView(Badge(from: description.properties))
    ///     case "Card":
    ///         return AnyView(Card(from: description.properties))
    ///     default:
    ///         fatalError("Unknown component type: \(description.componentType)")
    ///     }
    /// }
    /// ```
    var componentType: String { get }

    /// A dictionary of all configurable properties and their current values.
    ///
    /// This dictionary provides a complete snapshot of the component's configuration
    /// in a format that agents can easily read, modify, and serialize. Properties should:
    /// - Include all user-configurable options (e.g., text, colors, sizes)
    /// - Use JSON-serializable types (String, Int, Bool, Double, Array, Dictionary)
    /// - Use enum `rawValue` for type-safe options
    /// - Exclude computed properties derived from DS tokens (agents should use tokens directly)
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension Badge: AgentDescribable {
    ///     var properties: [String: Any] {
    ///         [
    ///             "text": text,
    ///             "level": level.rawValue,  // "info", "warning", "error", "success"
    ///             "showIcon": showIcon
    ///         ]
    ///     }
    /// }
    /// ```
    ///
    /// ## Nested Properties
    ///
    /// Complex components can use nested dictionaries for structured data:
    ///
    /// ```swift
    /// extension InspectorPattern: AgentDescribable {
    ///     var properties: [String: Any] {
    ///         [
    ///             "title": title,
    ///             "sections": sections.map { section in
    ///                 [
    ///                     "header": section.header,
    ///                     "items": section.items
    ///                 ]
    ///             },
    ///             "material": material.rawValue
    ///         ]
    ///     }
    /// }
    /// ```
    ///
    /// ## Serialization
    ///
    /// Properties must be JSON-serializable for agent consumption:
    ///
    /// ```swift
    /// let badge = Badge(text: "Error", level: .error)
    /// let jsonData = try JSONSerialization.data(
    ///     withJSONObject: badge.properties,
    ///     options: .prettyPrinted
    /// )
    /// // {"text":"Error","level":"error","showIcon":true}
    /// ```
    var properties: [String: Any] { get }

    /// A human-readable description of the component's purpose and current state.
    ///
    /// This semantic description helps agents understand the component's role in the UI
    /// and make intelligent decisions about composition and layout. The description should:
    /// - Explain what the component does (not how it's implemented)
    /// - Include current state information when relevant
    /// - Be concise but informative (1-2 sentences)
    /// - Use natural language that AI models can easily interpret
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension Badge: AgentDescribable {
    ///     var semantics: String {
    ///         "Status indicator displaying \(level.rawValue) state: \(text)"
    ///     }
    /// }
    ///
    /// extension Card: AgentDescribable {
    ///     var semantics: String {
    ///         "Container with \(elevation.rawValue) elevation providing visual hierarchy"
    ///     }
    /// }
    ///
    /// extension InspectorPattern: AgentDescribable {
    ///     var semantics: String {
    ///         "Inspector panel displaying '\(title)' with \(sections.count) sections"
    ///     }
    /// }
    /// ```
    ///
    /// ## Agent Usage
    ///
    /// Agents can use semantics for:
    /// - Generating accessible UI (VoiceOver descriptions)
    /// - Understanding component relationships
    /// - Making layout decisions based on content
    /// - Providing context in agent-to-agent communication
    ///
    /// ```swift
    /// // Agent can use semantics to generate VoiceOver label:
    /// let badge = Badge(text: "3 errors", level: .error)
    /// Text(badge.semantics)
    ///     .accessibilityLabel(badge.semantics)
    /// ```
    var semantics: String { get }
}

// MARK: - Default Implementations

@available(iOS 17.0, macOS 14.0, *)
public extension AgentDescribable {

    /// Default implementation for debugging and development.
    ///
    /// Returns a formatted string representation of the component's agent-describable state.
    /// Useful for debugging agent-driven UI generation.
    ///
    /// - Returns: A multi-line string with component type, properties, and semantics.
    func agentDescription() -> String {
        var description = """
        Component Type: \(componentType)
        Semantics: \(semantics)
        Properties:
        """

        for (key, value) in properties.sorted(by: { $0.key < $1.key }) {
            description += "\n  - \(key): \(value)"
        }

        return description
    }

    /// Validates that all properties are JSON-serializable.
    ///
    /// This method checks if the component's properties can be serialized to JSON,
    /// which is required for agent communication and persistence.
    ///
    /// - Returns: `true` if properties can be serialized to JSON, `false` otherwise.
    func isJSONSerializable() -> Bool {
        JSONSerialization.isValidJSONObject(properties)
    }
}
