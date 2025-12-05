import Foundation

/// Errors thrown by `FilesystemAccess` operations.
public enum FilesystemAccessError: Error, Sendable {
    case authorizationDenied(url: URL)
    case dialogUnavailable(dialog: Dialog)
    case bookmarkCreationFailed(underlying: Error)
    case bookmarkResolutionFailed(underlying: Error)
    case staleBookmark(url: URL)

    public enum Dialog: Sendable {
        case open
        case save
    }
}
