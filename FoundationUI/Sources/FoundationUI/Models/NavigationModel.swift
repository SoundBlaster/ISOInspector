import SwiftUI

/// Observable model managing navigation state for `NavigationSplitScaffold`.
///
/// `NavigationModel` encapsulates the mutable state for a three-column navigation layout,
/// including column visibility and preferred compact column selection. Use this model
/// to programmatically control navigation behavior across size classes.
///
/// ## Usage
///
/// ```swift
/// @Observable
/// final class AppState {
///     var navigationModel = NavigationModel()
/// }
///
/// struct ContentView: View {
///     @Bindable var state: AppState
///
///     var body: some View {
///         NavigationSplitScaffold(model: state.navigationModel) {
///             SidebarView()
///         } content: {
///             ContentView()
///         } detail: {
///             DetailView()
///         }
///     }
/// }
/// ```
///
/// ## Column Visibility
///
/// The `columnVisibility` property controls which columns are visible:
/// - `.all`: All three columns visible (sidebar, content, detail)
/// - `.contentDetail`: Only content and detail visible (sidebar hidden)
/// - `.automatic`: System decides based on size class and context
/// - `.detailOnly`: Only detail column visible
///
/// ## Compact Column Preference
///
/// On compact size classes (iPhone), only one column can be shown at a time.
/// The `preferredCompactColumn` property indicates which column to prioritize:
/// - `.sidebar`: Show sidebar in compact mode
/// - `.content`: Show content in compact mode
/// - `.detail`: Show detail in compact mode
///
/// ## Platform Behavior
///
/// - **macOS**: Typically shows all three columns by default
/// - **iPadOS**: Shows all columns in regular width, adapts in Split View
/// - **iOS**: Shows one column at a time, navigates between them
@available(iOS 17.0, macOS 14.0, *)
@Observable
public final class NavigationModel {
    /// Controls which columns are currently visible in the navigation split view.
    ///
    /// Modify this property to programmatically show/hide columns:
    ///
    /// ```swift
    /// // Show all columns
    /// navigationModel.columnVisibility = .all
    ///
    /// // Hide sidebar, show content + detail
    /// navigationModel.columnVisibility = .contentDetail
    ///
    /// // Let system decide
    /// navigationModel.columnVisibility = .automatic
    /// ```
    public var columnVisibility: NavigationSplitViewVisibility

    /// The preferred column to display when in compact size class (iPhone).
    ///
    /// On compact devices where only one column fits, this determines which
    /// column to prioritize:
    ///
    /// ```swift
    /// // Prefer showing sidebar on iPhone
    /// navigationModel.preferredCompactColumn = .sidebar
    ///
    /// // Prefer showing detail on iPhone
    /// navigationModel.preferredCompactColumn = .detail
    /// ```
    public var preferredCompactColumn: NavigationSplitViewColumn

    /// Creates a new navigation model with default visibility settings.
    ///
    /// - Parameters:
    ///   - columnVisibility: Initial column visibility state. Defaults to `.automatic`.
    ///   - preferredCompactColumn: Preferred column for compact size classes. Defaults to `.content`.
    public init(
        columnVisibility: NavigationSplitViewVisibility = .automatic,
        preferredCompactColumn: NavigationSplitViewColumn = .content
    ) {
        self.columnVisibility = columnVisibility
        self.preferredCompactColumn = preferredCompactColumn
    }
}

// MARK: - Convenience Methods

@available(iOS 17.0, macOS 14.0, *)
public extension NavigationModel {
    /// Shows all three columns (sidebar, content, detail).
    func showAllColumns() {
        columnVisibility = .all
    }

    /// Hides the sidebar, showing only content and detail.
    func hideSidebar() {
        columnVisibility = .contentDetail
    }

    /// Shows only the detail column.
    func showDetailOnly() {
        columnVisibility = .detailOnly
    }

    /// Lets the system automatically determine column visibility.
    func useAutomaticVisibility() {
        columnVisibility = .automatic
    }

    /// Returns true if all columns are currently visible.
    var areAllColumnsVisible: Bool {
        columnVisibility == .all
    }

    /// Returns true if the sidebar is currently hidden.
    var isSidebarHidden: Bool {
        columnVisibility == .contentDetail || columnVisibility == .detailOnly
    }
}
