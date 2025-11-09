//
//  AgentDescribablePreviews.swift
//  FoundationUI
//
//  Created by AI Assistant on 2025-11-08.
//  Copyright © 2025 ISO Inspector. All rights reserved.
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

/// SwiftUI Previews demonstrating the `AgentDescribable` protocol.
///
/// These previews showcase:
/// - How to conform existing components to `AgentDescribable`
/// - Protocol property usage
/// - JSON serialization for agent consumption
/// - Real-world integration examples

// MARK: - Preview 1: Basic Protocol Conformance

/// Demonstrates basic protocol conformance with a simple component.
@available(iOS 17.0, macOS 14.0, *)
#Preview("1. Basic Conformance") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("AgentDescribable Protocol Demo")
            .font(DS.Typography.headline)

        // Example: Badge component with AgentDescribable
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Badge Component")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            // Show the badge
            Badge(text: "Error", level: .error, showIcon: true)

            // Show its agent-describable properties
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Component Type:")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("Badge")
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Colors.accent)

                Text("Properties:")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("{ text: \"Error\", level: \"error\", showIcon: true }")
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Colors.accent)

                Text("Semantics:")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("Status indicator displaying error state: Error")
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Colors.accent)
            }
            .padding(DS.Spacing.m)
            .background(DS.Colors.tertiary)
            .cornerRadius(DS.Radius.medium)
        }
    }
    .padding(DS.Spacing.l)
}

// MARK: - Preview 2: Multiple Component Types

/// Demonstrates protocol conformance across different component types.
@available(iOS 17.0, macOS 14.0, *)
#Preview("2. Multiple Components") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            Text("Agent-Describable Components")
                .font(DS.Typography.headline)

            // Badge
            ComponentDescription(
                component: AgentDescribableDemo.badge,
                title: "Badge"
            )

            Divider()

            // Card
            ComponentDescription(
                component: AgentDescribableDemo.card,
                title: "Card"
            )

            Divider()

            // KeyValueRow
            ComponentDescription(
                component: AgentDescribableDemo.keyValueRow,
                title: "KeyValueRow"
            )
        }
        .padding(DS.Spacing.l)
    }
}

// MARK: - Preview 3: JSON Serialization

/// Demonstrates JSON serialization for agent consumption.
@available(iOS 17.0, macOS 14.0, *)
#Preview("3. JSON Serialization") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("Agent Communication Example")
            .font(DS.Typography.headline)

        Text("Components can be serialized to JSON for AI agent consumption:")
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.textSecondary)

        // Example Badge
        Badge(text: "Success", level: .success)

        // Show JSON representation
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("JSON Output:")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)

            Text(AgentDescribableDemo.badgeJSON)
                .font(DS.Typography.code)
                .foregroundStyle(DS.Colors.textPrimary)
                .padding(DS.Spacing.m)
                .background(DS.Colors.tertiary)
                .cornerRadius(DS.Radius.medium)
        }

        Text("Agents can parse this JSON to reconstruct or modify the component")
            .font(DS.Typography.caption)
            .foregroundStyle(DS.Colors.textSecondary)
            .italic()
    }
    .padding(DS.Spacing.l)
}

// MARK: - Preview 4: Agent Integration Workflow

/// Demonstrates a complete agent-driven UI generation workflow.
@available(iOS 17.0, macOS 14.0, *)
#Preview("4. Agent Workflow") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("Agent-Driven UI Generation")
            .font(DS.Typography.headline)

        // Step 1: Agent receives description
        WorkflowStep<EmptyView>(
            number: 1,
            title: "Agent Receives Description",
            content: """
            {
              "componentType": "Badge",
              "properties": {
                "text": "3 items",
                "level": "info",
                "showIcon": true
              }
            }
            """
        )

        // Step 2: Agent generates component
        WorkflowStep<EmptyView>(
            number: 2,
            title: "Agent Generates Component",
            content: "Badge(text: \"3 items\", level: .info, showIcon: true)"
        )

        // Step 3: Rendered result
        WorkflowStep(
            number: 3,
            title: "Rendered Result",
            content: nil,
            customContent: {
                Badge(text: "3 items", level: .info, showIcon: true)
            }
        )
    }
    .padding(DS.Spacing.l)
}

// MARK: - Preview 5: Pattern Integration

/// Demonstrates AgentDescribable with complex patterns.
@available(iOS 17.0, macOS 14.0, *)
#Preview("5. Pattern Integration") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("Complex Pattern Support")
            .font(DS.Typography.headline)

        Text("Patterns like InspectorPattern can also be agent-describable:")
            .font(DS.Typography.body)
            .foregroundStyle(DS.Colors.textSecondary)

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Example: InspectorPattern")
                .font(DS.Typography.title)

            Text("Component Type:")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            Text("InspectorPattern")
                .font(DS.Typography.code)

            Text("Properties:")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            Text("""
            {
              "title": "File Inspector",
              "sections": [
                { "header": "General", "items": 3 },
                { "header": "Properties", "items": 5 }
              ],
              "material": "regular"
            }
            """)
                .font(DS.Typography.code)
                .padding(DS.Spacing.m)
                .background(DS.Colors.tertiary)
                .cornerRadius(DS.Radius.medium)
        }
    }
    .padding(DS.Spacing.l)
}

// MARK: - Preview 6: Debug Utilities

/// Demonstrates built-in debug utilities from the protocol.
@available(iOS 17.0, macOS 14.0, *)
#Preview("6. Debug Utilities") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            Text("AgentDescribable Debug Tools")
                .font(DS.Typography.headline)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("agentDescription() Output:")
                    .font(DS.Typography.title)

                Text(AgentDescribableDemo.debugDescription)
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.tertiary)
                    .cornerRadius(DS.Radius.medium)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("isJSONSerializable() Check:")
                    .font(DS.Typography.title)

                HStack {
                    Text("Result:")
                        .font(DS.Typography.body)
                    Badge(
                        text: AgentDescribableDemo.isSerializable ? "Valid" : "Invalid",
                        level: AgentDescribableDemo.isSerializable ? .success : .error
                    )
                }
            }
        }
        .padding(DS.Spacing.l)
    }
}

// MARK: - Helper Views

/// Helper view for displaying component descriptions
@available(iOS 17.0, macOS 14.0, *)
private struct ComponentDescription: View {
    let component: any AgentDescribable
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(title)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                PropertyRow(label: "Type", value: component.componentType)
                PropertyRow(label: "Semantics", value: component.semantics)

                Text("Properties:")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.textSecondary)

                ForEach(component.properties.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text("  • \(key):")
                            .font(DS.Typography.code)
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text("\(String(describing: value))")
                            .font(DS.Typography.code)
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
            .padding(DS.Spacing.m)
            .background(DS.Colors.tertiary)
            .cornerRadius(DS.Radius.medium)
        }
    }
}

/// Helper view for property rows
@available(iOS 17.0, macOS 14.0, *)
private struct PropertyRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(label):")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(DS.Typography.code)
                .foregroundStyle(DS.Colors.accent)
        }
    }
}

/// Helper view for workflow steps
@available(iOS 17.0, macOS 14.0, *)
private struct WorkflowStep<Content: View>: View {
    let number: Int
    let title: String
    let content: String?
    let customContent: (() -> Content)?

    init(number: Int, title: String, content: String?, customContent: (() -> Content)? = nil) {
        self.number = number
        self.title = title
        self.content = content
        self.customContent = customContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack {
                Circle()
                    .fill(DS.Colors.accent)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text("\(number)")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.white)
                    }

                Text(title)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            if let content {
                Text(content)
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.tertiary)
                    .cornerRadius(DS.Radius.medium)
            }

            if let customContent {
                customContent()
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.tertiary)
                    .cornerRadius(DS.Radius.medium)
            }
        }
    }
}

// MARK: - Demo Data

/// Demo data for AgentDescribable previews.
///
/// This provides example implementations and JSON representations for demonstration purposes.
@available(iOS 17.0, macOS 14.0, *)
private enum AgentDescribableDemo {
    nonisolated(unsafe) static let badge: any AgentDescribable = DemoBadge(
        text: "Warning",
        level: "warning",
        showIcon: true
    )

    nonisolated(unsafe) static let card: any AgentDescribable = DemoCard(
        elevation: "medium",
        radius: "card"
    )

    nonisolated(unsafe) static let keyValueRow: any AgentDescribable = DemoKeyValueRow(
        key: "File Size",
        value: "2.4 MB",
        layout: "horizontal"
    )

    static let badgeJSON = """
    {
      "componentType": "Badge",
      "properties": {
        "text": "Success",
        "level": "success",
        "showIcon": true
      },
      "semantics": "Status indicator displaying success state: Success"
    }
    """

    static let debugDescription: String = {
        badge.agentDescription()
    }()

    static let isSerializable: Bool = {
        badge.isJSONSerializable()
    }()
}

// MARK: - Demo Types

@available(iOS 17.0, macOS 14.0, *)
private struct DemoBadge: AgentDescribable {
    let text: String
    let level: String
    let showIcon: Bool

    var componentType: String { "Badge" }
    var properties: [String: Any] {
        ["text": text, "level": level, "showIcon": showIcon]
    }
    var semantics: String {
        "Status indicator displaying \(level) state: \(text)"
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct DemoCard: AgentDescribable {
    let elevation: String
    let radius: String

    var componentType: String { "Card" }
    var properties: [String: Any] {
        ["elevation": elevation, "radius": radius]
    }
    var semantics: String {
        "Container with \(elevation) elevation and \(radius) corner radius"
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct DemoKeyValueRow: AgentDescribable {
    let key: String
    let value: String
    let layout: String

    var componentType: String { "KeyValueRow" }
    var properties: [String: Any] {
        ["key": key, "value": value, "layout": layout]
    }
    var semantics: String {
        "Key-value pair displaying '\(key): \(value)' in \(layout) layout"
    }
}

#endif
