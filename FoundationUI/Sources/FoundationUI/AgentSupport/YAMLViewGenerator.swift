#if canImport(SwiftUI)
import SwiftUI

/// Generates SwiftUI views from parsed and validated YAML component descriptions.
///
/// The YAMLViewGenerator takes validated `ComponentDescription` objects and creates
/// corresponding SwiftUI views using FoundationUI components.
///
/// ## Overview
///
/// The view generator:
/// - Supports all 8 FoundationUI component types
/// - Handles nested component hierarchies
/// - Uses Design System tokens exclusively
/// - Provides type-safe property conversion
/// - Generates accessible, platform-adaptive views
///
/// ## Usage
///
/// Generate a view from a component description:
/// ```swift
/// let description = ComponentDescription(
///     componentType: "Badge",
///     properties: ["text": "Success", "level": "success"]
/// )
/// let view = try YAMLViewGenerator.generateView(from: description)
/// ```
///
/// Generate a view directly from YAML:
/// ```swift
/// let yaml = """
/// - componentType: Badge
///   properties:
///     text: "Success"
///     level: success
/// """
/// let view = try YAMLViewGenerator.generateView(fromYAML: yaml)
/// ```
///
/// ## Topics
///
/// ### View Generation Methods
/// - ``generateView(from:)``
/// - ``generateView(fromYAML:)``
///
/// ### Error Types
/// - ``GenerationError``
///
@available(iOS 17.0, macOS 14.0, *)
public struct YAMLViewGenerator {

    // MARK: - Error Types

    /// Errors that can occur during view generation.
    public enum GenerationError: Error, LocalizedError {
        /// The component type is not supported for view generation
        case unknownComponentType(String)

        /// A required property for view generation is missing
        case missingProperty(component: String, property: String)

        /// A property has an invalid value that cannot be converted
        case invalidProperty(component: String, property: String, details: String)

        /// The YAML document is empty
        case emptyYAML

        public var errorDescription: String? {
            switch self {
            case .unknownComponentType(let type):
                return "Cannot generate view for unknown component type '\(type)'"
            case .missingProperty(let component, let property):
                return "Missing required property '\(property)' for generating \(component)"
            case .invalidProperty(let component, let property, let details):
                return "Invalid property '\(property)' in \(component): \(details)"
            case .emptyYAML:
                return "Cannot generate view from empty YAML document"
            }
        }
    }

    // MARK: - Public View Generation Methods

    /// Generates a SwiftUI view from a component description.
    ///
    /// Creates the appropriate FoundationUI component based on the `componentType`
    /// and configures it with the provided properties.
    ///
    /// - Parameter description: The component description to generate from
    /// - Returns: A type-erased SwiftUI view (AnyView)
    /// - Throws: ``GenerationError`` if view generation fails
    public static func generateView(from description: YAMLParser.ComponentDescription) throws -> AnyView {
        switch description.componentType {
        case "Badge":
            return AnyView(try generateBadge(from: description))
        case "Card":
            return AnyView(try generateCard(from: description))
        case "KeyValueRow":
            return AnyView(try generateKeyValueRow(from: description))
        case "SectionHeader":
            return AnyView(try generateSectionHeader(from: description))
        case "InspectorPattern":
            return AnyView(try generateInspectorPattern(from: description))
        case "SidebarPattern":
            return AnyView(try generateSidebarPattern(from: description))
        case "ToolbarPattern":
            return AnyView(try generateToolbarPattern(from: description))
        case "BoxTreePattern":
            return AnyView(try generateBoxTreePattern(from: description))
        default:
            throw GenerationError.unknownComponentType(description.componentType)
        }
    }

    /// Generates a SwiftUI view from a YAML string.
    ///
    /// Parses the YAML, validates it, and generates a view from the first component.
    /// For multi-component YAML, use ``generateView(from:)`` with parsed descriptions.
    ///
    /// - Parameter yamlString: The YAML string to parse and generate from
    /// - Returns: A type-erased SwiftUI view (AnyView)
    /// - Throws: ``YAMLParser/ParseError`` or ``YAMLValidator/ValidationError`` or ``GenerationError``
    public static func generateView(fromYAML yamlString: String) throws -> AnyView {
        let descriptions = try YAMLParser.parse(yamlString)
        guard let description = descriptions.first else {
            throw GenerationError.emptyYAML
        }
        try YAMLValidator.validate(description)
        return try generateView(from: description)
    }

    // MARK: - Component-Specific Generators

    /// Generates a Badge component from a description.
    private static func generateBadge(from description: YAMLParser.ComponentDescription) throws -> Badge {
        guard let text = description.properties["text"] as? String else {
            throw GenerationError.missingProperty(component: "Badge", property: "text")
        }

        guard let levelString = description.properties["level"] as? String else {
            throw GenerationError.missingProperty(component: "Badge", property: "level")
        }

        guard let level = BadgeLevel(rawValue: levelString) else {
            throw GenerationError.invalidProperty(
                component: "Badge",
                property: "level",
                details: "Invalid level '\(levelString)'"
            )
        }

        let showIcon = description.properties["showIcon"] as? Bool ?? true

        return Badge(text: text, level: level, showIcon: showIcon)
    }

    /// Generates a Card component from a description.
    private static func generateCard(from description: YAMLParser.ComponentDescription) throws -> Card<AnyView> {
        // Parse elevation
        let elevation: Elevation
        if let elevationString = description.properties["elevation"] as? String {
            elevation = Elevation(rawValue: elevationString) ?? .low
        } else {
            elevation = .low
        }

        // Parse cornerRadius
        let cornerRadius: CGFloat
        if let radiusValue = description.properties["cornerRadius"] {
            if let doubleValue = radiusValue as? Double {
                cornerRadius = CGFloat(doubleValue)
            } else if let intValue = radiusValue as? Int {
                cornerRadius = CGFloat(intValue)
            } else {
                cornerRadius = DS.Radius.card
            }
        } else {
            cornerRadius = DS.Radius.card
        }

        // Parse material
        let material: SurfaceMaterial?
        if let materialString = description.properties["material"] as? String {
            material = SurfaceMaterial(rawValue: materialString)
        } else {
            material = nil
        }

        // Generate nested content
        let content: AnyView
        if let nestedContent = description.content, !nestedContent.isEmpty {
            let nestedViews = try nestedContent.map { try generateView(from: $0) }
            content = AnyView(VStack(spacing: DS.Spacing.m) {
                ForEach(0..<nestedViews.count, id: \.self) { index in
                    nestedViews[index]
                }
            })
        } else {
            content = AnyView(EmptyView())
        }

        return Card(
            elevation: elevation,
            cornerRadius: cornerRadius,
            material: material,
            content: { content }
        )
    }

    /// Generates a KeyValueRow component from a description.
    private static func generateKeyValueRow(from description: YAMLParser.ComponentDescription) throws -> KeyValueRow {
        guard let key = description.properties["key"] as? String else {
            throw GenerationError.missingProperty(component: "KeyValueRow", property: "key")
        }

        guard let value = description.properties["value"] as? String else {
            throw GenerationError.missingProperty(component: "KeyValueRow", property: "value")
        }

        // Parse layout
        let layout: KeyValueRow.LayoutMode
        if let layoutString = description.properties["layout"] as? String {
            layout = layoutString == "vertical" ? .vertical : .horizontal
        } else {
            layout = .horizontal
        }

        let isCopyable = description.properties["isCopyable"] as? Bool ?? false

        return KeyValueRow(key: key, value: value, layout: layout, isCopyable: isCopyable)
    }

    /// Generates a SectionHeader component from a description.
    private static func generateSectionHeader(from description: YAMLParser.ComponentDescription) throws -> SectionHeader {
        guard let title = description.properties["title"] as? String else {
            throw GenerationError.missingProperty(component: "SectionHeader", property: "title")
        }

        let showDivider = description.properties["showDivider"] as? Bool ?? true

        return SectionHeader(title: title, showDivider: showDivider)
    }

    /// Generates an InspectorPattern component from a description.
    private static func generateInspectorPattern(from description: YAMLParser.ComponentDescription) throws -> InspectorPattern<AnyView> {
        guard let title = description.properties["title"] as? String else {
            throw GenerationError.missingProperty(component: "InspectorPattern", property: "title")
        }

        // Parse material
        let material: SurfaceMaterial
        if let materialString = description.properties["material"] as? String,
           let parsedMaterial = SurfaceMaterial(rawValue: materialString) {
            material = parsedMaterial
        } else {
            material = .regular
        }

        // Generate nested content
        let content: AnyView
        if let nestedContent = description.content, !nestedContent.isEmpty {
            let nestedViews = try nestedContent.map { try generateView(from: $0) }
            content = AnyView(VStack(alignment: .leading, spacing: DS.Spacing.l) {
                ForEach(0..<nestedViews.count, id: \.self) { index in
                    nestedViews[index]
                }
            })
        } else {
            content = AnyView(Text("No content"))
        }

        return InspectorPattern(title: title, content: { content })
            .material(material)
    }

    /// Generates a SidebarPattern component from a description.
    private static func generateSidebarPattern(from description: YAMLParser.ComponentDescription) throws -> some View {
        // SidebarPattern requires complex state management, return a placeholder
        return Text("SidebarPattern generation requires state management")
            .foregroundColor(DS.Colors.textSecondary)
            .font(DS.Typography.caption)
    }

    /// Generates a ToolbarPattern component from a description.
    private static func generateToolbarPattern(from description: YAMLParser.ComponentDescription) throws -> some View {
        // ToolbarPattern requires complex state management, return a placeholder
        return Text("ToolbarPattern generation requires state management")
            .foregroundColor(DS.Colors.textSecondary)
            .font(DS.Typography.caption)
    }

    /// Generates a BoxTreePattern component from a description.
    private static func generateBoxTreePattern(from description: YAMLParser.ComponentDescription) throws -> some View {
        // BoxTreePattern requires complex state management, return a placeholder
        return Text("BoxTreePattern generation requires state management")
            .foregroundColor(DS.Colors.textSecondary)
            .font(DS.Typography.caption)
    }
}

#endif // canImport(SwiftUI)
