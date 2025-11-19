import Observation
import SwiftUI

/// A model that manages navigation state for NavigationSplitView.
///
/// `NavigationModel` provides a centralized state container for three-column navigation layouts,
/// managing column visibility and preferred compact column settings. It uses Swift's `@Observable`
/// macro for automatic view updates.
///
/// ## Overview
///
/// Use `NavigationModel` with `NavigationSplitScaffold` to coordinate navigation across
/// sidebar, content, and detail columns:
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
///             // Sidebar, content, detail columns...
///         }
///     }
/// }
/// ```
///
/// ## Column Visibility States
///
/// The `columnVisibility` property controls which columns are visible:
///
/// - `.automatic`: System determines visibility based on size class
/// - `.all`: All columns visible (sidebar + content + detail)
/// - `.doubleColumn`: Two columns visible (typically sidebar + content or content + detail)
/// - `.detailOnly`: Only detail column visible
///
/// ## Platform Adaptation
///
/// - **macOS**: All columns typically visible, user-controllable
/// - **iPad Landscape**: Three columns in regular size class
/// - **iPad Portrait**: Two columns in compact size class
/// - **iPhone**: Single column with stack navigation
///
/// ## Topics
///
/// ### Creating a Model
/// - ``init()``
///
/// ### Navigation State
/// - ``columnVisibility``
/// - ``preferredCompactColumn``
///
@available(iOS 17.0, macOS 14.0, *)
@Observable
public final class NavigationModel: @unchecked Sendable {
    // MARK: - Properties

    /// The visibility state of navigation columns.
    ///
    /// Controls which columns are visible in the navigation split view.
    /// The system may override this based on size class and available space.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let model = NavigationModel()
    /// model.columnVisibility = .all  // Show all three columns
    /// ```
    public var columnVisibility: NavigationSplitViewVisibility

    /// The preferred column to show when in compact size class.
    ///
    /// When the navigation view is in a compact size class (e.g., iPhone),
    /// this determines which column should be displayed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let model = NavigationModel()
    /// model.preferredCompactColumn = .content  // Show content in compact mode
    /// ```
    public var preferredCompactColumn: NavigationSplitViewColumn

    // MARK: - Initialization

    /// Creates a new navigation model with default settings.
    ///
    /// The model is initialized with:
    /// - `columnVisibility` set to `.automatic`
    /// - `preferredCompactColumn` set to `.content`
    ///
    /// ## Example
    ///
    /// ```swift
    /// let model = NavigationModel()
    /// ```
    public init() {
        self.columnVisibility = .automatic
        self.preferredCompactColumn = .content
    }
}

// MARK: - Equatable

@available(iOS 17.0, macOS 14.0, *)
extension NavigationModel: Equatable {
    public static func == (lhs: NavigationModel, rhs: NavigationModel) -> Bool {
        lhs.columnVisibility == rhs.columnVisibility &&
        lhs.preferredCompactColumn == rhs.preferredCompactColumn
    }
}
