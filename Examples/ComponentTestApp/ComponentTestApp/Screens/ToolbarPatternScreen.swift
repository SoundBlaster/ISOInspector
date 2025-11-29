/// ToolbarPatternScreen - Showcase for ToolbarPattern
///
/// Demonstrates the ToolbarPattern component with platform-adaptive toolbar items.
///
/// Features:
/// - Platform-adaptive toolbar items
/// - Icon + label buttons
/// - Keyboard shortcuts (⌘C, ⌘V, ⌘S, etc.)
/// - Action feedback with alerts
/// - Inspector-specific tools

import SwiftUI
import FoundationUI

struct ToolbarPatternScreen: View {
    /// Action feedback message
    @State private var feedbackMessage: String?
    
    /// Show feedback alert
    @State private var showAlert = false
    
    /// Sample content for demonstration
    @State private var content = "Sample ISO box data"
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarDemonstration
            
            toolbarExplanation
        }
        .toolbar {
            toolbar
        }
        .navigationTitle("ToolbarPattern")
        .alert("Action Performed", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                feedbackMessage = nil
            }
        } message: {
            if let message = feedbackMessage {
                Text(message)
            }
        }
    }
}



extension ToolbarPatternScreen {
    @ViewBuilder
    private var toolbarDemonstration: some View {
        Card(elevation: .low, cornerRadius: DS.Radius.card, material: .regular) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "Content Area", showDivider: false)
                
                Text(content)
                    .font(DS.Typography.body)
                    .padding(DS.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(DS.Radius.small)
                
                if let message = feedbackMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DS.Colors.successBG)
                        Text(message)
                            .font(DS.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.s)
                    .background(DS.Colors.successBG.opacity(0.2))
                    .cornerRadius(DS.Radius.small)
                }
            }
            .padding(DS.Spacing.l)
        }
        .padding(DS.Spacing.l)
    }
}

extension ToolbarPatternScreen {
    @ViewBuilder
    private var toolbarExplanation: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "Toolbar Actions", showDivider: true)
                
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    ToolbarActionRow(
                        icon: "doc.on.doc",
                        title: "Copy",
                        shortcut: "⌘C",
                        description: "Copy content to clipboard"
                    )
                    
                    ToolbarActionRow(
                        icon: "arrow.down.doc",
                        title: "Export",
                        shortcut: "⌘E",
                        description: "Export data to file"
                    )
                    
                    ToolbarActionRow(
                        icon: "arrow.clockwise",
                        title: "Refresh",
                        shortcut: "⌘R",
                        description: "Reload current data"
                    )
                    
                    ToolbarActionRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Inspect",
                        shortcut: "⌘I",
                        description: "Show detailed inspector"
                    )
                    
                    ToolbarActionRow(
                        icon: "square.and.arrow.up",
                        title: "Share",
                        shortcut: "⌘S",
                        description: "Share content"
                    )
                }
                .padding(.horizontal, DS.Spacing.l)
                
                SectionHeader(title: "Platform Adaptation", showDivider: true)
                
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Label {
                        Text("On macOS: All toolbar items visible with keyboard shortcuts")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "macwindow")
                            .foregroundStyle(DS.Colors.accent)
                    }
                    
                    Label {
                        Text("On iOS: Primary items visible, secondary in overflow menu")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "iphone")
                            .foregroundStyle(DS.Colors.accent)
                    }
                    
                    Label {
                        Text("On iPadOS: Adaptive based on size class")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "ipad")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                
                SectionHeader(title: "Accessibility", showDivider: true)
                
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Label {
                        Text("All toolbar items have VoiceOver labels")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "accessibility")
                            .foregroundStyle(DS.Colors.accent)
                    }
                    
                    Label {
                        Text("Keyboard shortcuts announced to VoiceOver")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "keyboard")
                            .foregroundStyle(DS.Colors.accent)
                    }
                    
                    Label {
                        Text("Touch targets ≥44×44 pt on iOS")
                            .font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "hand.tap")
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.xl)
            }
            .padding(DS.Spacing.l)
        }
    }
}

extension ToolbarPatternScreen {
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        
        ToolbarItemGroup(placement: .primaryAction) {
            // Copy Button
            Button {
                copyAction()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c", modifiers: .command)
            .accessibilityLabel("Copy content")
            .accessibilityHint("Copies the content to clipboard. Keyboard shortcut: Command C")
            
            // Export Button
            Button {
                exportAction()
            } label: {
                Label("Export", systemImage: "arrow.down.doc")
            }
            .keyboardShortcut("e", modifiers: .command)
            .accessibilityLabel("Export data")
            
            // Refresh Button
            Button {
                refreshAction()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .accessibilityLabel("Refresh")
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            // Inspect Button
            Button {
                inspectAction()
            } label: {
                Label("Inspect", systemImage: "doc.text.magnifyingglass")
            }
            .keyboardShortcut("i", modifiers: .command)
            
            // Share Button
            Button {
                shareAction()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}

extension ToolbarPatternScreen {
    
    // MARK: - Actions
    
    private func copyAction() {
        feedbackMessage = "Content copied to clipboard"
        showFeedback()
    }
    
    private func exportAction() {
        feedbackMessage = "Data exported successfully"
        showFeedback()
    }
    
    private func refreshAction() {
        feedbackMessage = "Data refreshed"
        showFeedback()
    }
    
    private func inspectAction() {
        feedbackMessage = "Inspector opened"
        showFeedback()
    }
    
    private func shareAction() {
        feedbackMessage = "Share sheet presented"
        showFeedback()
    }
    
    private func showFeedback() {
        withAnimation(DS.Animation.quick) {
            // Show inline feedback
        }
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(DS.Animation.quick) {
                feedbackMessage = nil
            }
        }
    }
}

// MARK: - Supporting Views

extension ToolbarPatternScreen {
    struct ToolbarActionRow: View {
        let icon: String
        let title: String
        let shortcut: String
        let description: String
        
        var body: some View {
            HStack(spacing: DS.Spacing.m) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 32)
                
                // Title and description
                VStack(alignment: .leading, spacing: DS.Spacing.s / 2) {
                    Text(title)
                        .font(DS.Typography.label)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Keyboard shortcut badge
                Text(shortcut)
                    .font(DS.Typography.caption)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.s / 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(DS.Radius.small)
            }
            .padding(.vertical, DS.Spacing.s)
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    NavigationStack {
        ToolbarPatternScreen()
            .preferredColorScheme(.light)
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        ToolbarPatternScreen()
            .preferredColorScheme(.dark)
    }
}

#Preview("With Feedback") {
    struct PreviewWrapper: View {
        @State private var message: String? = "Action completed successfully"
        
        var body: some View {
            NavigationStack {
                ToolbarPatternScreen()
            }
        }
    }
    
    return PreviewWrapper()
}
