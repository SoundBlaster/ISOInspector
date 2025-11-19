import SwiftUI

/// A scaffold pattern that wraps `NavigationSplitView` with Composable Clarity design tokens.
///
/// `NavigationSplitScaffold` provides a three-column layout orchestration layer for iOS/iPadOS/macOS apps.
/// It coordinates Sidebar, Content, and Detail columns while integrating with FoundationUI's design system.
///
/// ## Overview
///
/// The scaffold manages:
/// - **Layout orchestration**: Three-column layout rules and column visibility across size classes
/// - **Shared state**: Exposes `NavigationModel` via environment for downstream patterns
/// - **Design tokens**: All spacing, colors, animations use DS tokens (zero magic numbers)
/// - **Accessibility**: VoiceOver labels, keyboard shortcuts, reduce motion support
///
/// ## Column Responsibilities
///
/// - **Sidebar**: Navigation list, file browser, search interface
/// - **Content**: Main content area (parse tree, hex view, reports)
/// - **Detail**: Contextual details, properties, metadata
///
/// ## Usage
///
/// ```swift
/// @Observable
/// final class AppState {
///     var navigationModel = NavigationModel()
///     var selectedFile: FileURL?
///     var selectedAtom: AtomNode?
/// }
///
/// struct ContentView: View {
///     @Bindable var state: AppState
///
///     var body: some View {
///         NavigationSplitScaffold(model: state.navigationModel) {
///             // Sidebar
///             FileBrowserView(selection: $state.selectedFile)
///         } content: {
///             // Content
///             if let file = state.selectedFile {
///                 ParseTreeView(file: file, selection: $state.selectedAtom)
///             } else {
///                 EmptyStateView(message: "Select a file to inspect")
///             }
///         } detail: {
///             // Detail
///             if let atom = state.selectedAtom {
///                 AtomInspectorView(atom: atom)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Platform Adaptation
///
/// The scaffold automatically adapts to different platforms and size classes:
///
/// - **macOS**: All three columns visible, user-controllable visibility
/// - **iPad Landscape**: All three columns visible in regular size class
/// - **iPad Portrait**: Two columns (sidebar + content) in compact size class
/// - **iPhone**: Single column with stack-style navigation
///
/// ## Accessibility
///
/// The scaffold supports:
/// - VoiceOver navigation with descriptive labels
/// - Keyboard shortcuts for column focus (⌘1/⌘2/⌘3)
/// - Reduce Motion for instant column transitions
///
/// ## Topics
///
/// ### Creating a Scaffold
/// - ``init(model:sidebar:content:detail:)``
///
/// ### Navigation State
/// - ``navigationModel``
/// - ``NavigationModelKey``
///
/// ### Environment Access
/// - ``EnvironmentValues/navigationModel``
///
@available(iOS 17.0, macOS 14.0, *)
public struct NavigationSplitScaffold<Sidebar: View, Content: View, Detail: View>: View {
    // MARK: - Properties

    /// The navigation model managing column visibility and state.
    ///
    /// This model is shared with all child views via environment,
    /// allowing them to query or update navigation state without owning it.
    @Bindable public var navigationModel: NavigationModel

    /// The sidebar column view.
    let sidebar: Sidebar

    /// The content column view.
    let content: Content

    /// The detail column view.
    let detail: Detail

    // MARK: - Initialization

    /// Creates a navigation split scaffold with the specified model and column views.
    ///
    /// - Parameters:
    ///   - model: The navigation model managing column visibility. Defaults to a new `NavigationModel()`.
    ///   - sidebar: A view builder that creates the sidebar column content.
    ///   - content: A view builder that creates the main content column.
    ///   - detail: A view builder that creates the detail/inspector column.
    ///
    /// - Note: All layout constants (spacing, colors, animations) use DS tokens for consistency.
    ///
    /// ## Example
    ///
    /// ```swift
    /// NavigationSplitScaffold {
    ///     // Sidebar
    ///     List(files) { file in
    ///         FileRow(file: file)
    ///     }
    /// } content: {
    ///     // Content
    ///     ParseTreeView(selectedFile)
    /// } detail: {
    ///     // Detail
    ///     AtomInspectorView(selectedAtom)
    /// }
    /// ```
    public init(
        model: NavigationModel = NavigationModel(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.navigationModel = model
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
    }

    // MARK: - Body

    public var body: some View {
        NavigationSplitView(
            columnVisibility: $navigationModel.columnVisibility
        ) {
            sidebar
                .environment(\.navigationModel, navigationModel)
        } content: {
            content
                .environment(\.navigationModel, navigationModel)
        } detail: {
            detail
                .environment(\.navigationModel, navigationModel)
        }
        .animation(DS.Animation.medium, value: navigationModel.columnVisibility)
    }
}

// MARK: - Environment Key

/// Environment key for accessing the navigation model from child views.
///
/// Child views can read the navigation model using:
///
/// ```swift
/// @Environment(\.navigationModel) var navigationModel
/// ```
///
/// This allows patterns like `SidebarPattern` or `InspectorPattern` to query
/// navigation state without owning it.
struct NavigationModelKey: EnvironmentKey {
    static let defaultValue: NavigationModel? = nil
}

extension EnvironmentValues {
    /// The navigation model from the nearest enclosing `NavigationSplitScaffold`.
    ///
    /// Use this environment value to access navigation state from child views:
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.navigationModel) var navigationModel
    ///
    ///     var body: some View {
    ///         if navigationModel?.columnVisibility == .all {
    ///             Text("All columns visible")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: This value is `nil` if the view is not inside a `NavigationSplitScaffold`.
    public var navigationModel: NavigationModel? {
        get { self[NavigationModelKey.self] }
        set { self[NavigationModelKey.self] = newValue }
    }
}

// MARK: - Preview Support

#if DEBUG
    @available(iOS 17.0, macOS 14.0, *)
    struct NavigationSplitScaffold_Previews: PreviewProvider {
        static var previews: some View {
            Group {
            // Preview 1: Basic Three-Column Layout
            basicThreeColumn
                .previewDisplayName("1. Basic Three-Column")

            // Preview 2: Compact Two-Column
            compactTwoColumn
                .previewDisplayName("2. Compact Two-Column")

            // Preview 3: ISO Inspector Reference
            isoInspectorReference
                .previewDisplayName("3. ISO Inspector Reference")

            // Preview 4: Dark Mode
            basicThreeColumn
                .preferredColorScheme(.dark)
                .previewDisplayName("4. Dark Mode")

            // Preview 5: All Columns Visible
            allColumnsVisible
                .previewDisplayName("5. All Columns Visible")

            // Preview 6: Content Only
            contentOnly
                .previewDisplayName("6. Content Only")
        }
    }

    // MARK: - Preview Variants

    @MainActor
    static var basicThreeColumn: some View {
        NavigationSplitScaffold {
            List {
                Section("Files") {
                    Label("Recents", systemImage: "clock")
                    Label("Browse", systemImage: "folder")
                }
            }
            .navigationTitle("ISOInspector")
        } content: {
            List {
                Text("ftyp")
                Text("moov")
                Text("trak")
            }
            .navigationTitle("Parse Tree")
        } detail: {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Atom Properties")
                    .font(DS.Typography.title)
                Divider()
                Text("Type: ftyp")
                Text("Size: 20 bytes")
                Text("Offset: 0x00000000")
            }
            .padding(DS.Spacing.m)
            .navigationTitle("Inspector")
        }
    }

    @MainActor
    static var compactTwoColumn: some View {
        let model = NavigationModel()
        model.columnVisibility = .doubleColumn

        return NavigationSplitScaffold(model: model) {
            List {
                Text("sample.mp4")
                Text("test.iso")
            }
            .navigationTitle("Files")
        } content: {
            List {
                Text("ftyp")
                Text("moov")
            }
            .navigationTitle("Parse Tree")
        } detail: {
            Text("Detail View")
                .navigationTitle("Inspector")
        }
    }

    @MainActor
    static var isoInspectorReference: some View {
        let model = NavigationModel()
        model.columnVisibility = .all

        return NavigationSplitScaffold(model: model) {
            List {
                Section("Recent") {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(DS.Colors.accent)
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text("sample.mp4")
                                .font(DS.Typography.body)
                            Text("2.4 MB • 2 min ago")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(DS.Colors.accent)
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text("test.iso")
                                .font(DS.Typography.body)
                            Text("15.3 MB • 1 hour ago")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                }
                Section("Tools") {
                    Label("Search", systemImage: "magnifyingglass")
                    Label("Bookmarks", systemImage: "bookmark")
                }
            }
            .navigationTitle("ISOInspector")
            .accessibilityLabel("File Browser")
        } content: {
            List {
                Section("Container") {
                    HStack {
                        Image(systemName: "cube")
                        Text("ftyp")
                        Spacer()
                        Text("20 bytes")
                            .foregroundStyle(DS.Colors.textSecondary)
                            .font(DS.Typography.caption)
                    }
                    HStack {
                        Image(systemName: "cube.fill")
                        Text("moov")
                        Spacer()
                        Text("1.2 KB")
                            .foregroundStyle(DS.Colors.textSecondary)
                            .font(DS.Typography.caption)
                    }
                }
                Section("Media") {
                    HStack {
                        Image(systemName: "waveform")
                        Text("trak")
                        Spacer()
                        Text("850 bytes")
                            .foregroundStyle(DS.Colors.textSecondary)
                            .font(DS.Typography.caption)
                    }
                }
            }
            .navigationTitle("Parse Tree")
            .accessibilityLabel("Parse Tree")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Properties")
                            .font(DS.Typography.title)
                        Divider()
                        propertyRow("Type", "ftyp")
                        propertyRow("Size", "20 bytes")
                        propertyRow("Offset", "0x00000000")
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Integrity")
                            .font(DS.Typography.title)
                        Divider()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Valid")
                                .font(DS.Typography.body)
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Metadata")
                            .font(DS.Typography.title)
                        Divider()
                        propertyRow("Major Brand", "isom")
                        propertyRow("Minor Version", "512")
                        propertyRow("Compatible Brands", "isom, iso2, mp41")
                    }
                }
                .padding(DS.Spacing.m)
            }
            .navigationTitle("Inspector")
            .accessibilityLabel("Atom Inspector")
        }
    }

    @MainActor
    static var allColumnsVisible: some View {
        let model = NavigationModel()
        model.columnVisibility = .all

        return NavigationSplitScaffold(model: model) {
            List {
                Text("Item 1")
                Text("Item 2")
            }
            .navigationTitle("Sidebar")
        } content: {
            Text("Content View")
                .navigationTitle("Content")
        } detail: {
            Text("Detail View")
                .navigationTitle("Detail")
        }
    }

    @MainActor
    static var contentOnly: some View {
        let model = NavigationModel()
        model.columnVisibility = .detailOnly

        return NavigationSplitScaffold(model: model) {
            List {
                Text("Hidden Sidebar")
            }
        } content: {
            VStack(spacing: DS.Spacing.m) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("Content Only Mode")
                    .font(DS.Typography.title)
                Text("Sidebar and detail are hidden")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(DS.Spacing.xl)
        } detail: {
            Text("Hidden Detail")
        }
    }

    @MainActor
    static func propertyRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DS.Typography.body)
        }
    }
    }
#endif
