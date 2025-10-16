import Foundation

/// Represents a URL with an active security scope that must be explicitly released.
public struct SecurityScopedURL: Sendable, Equatable {
    public let url: URL
    private let handle: Handle

    init(url: URL, manager: any SecurityScopedAccessManaging) {
        self.url = url
        self.handle = Handle(url: url, manager: manager)
    }

    /// Releases the underlying security scope. The operation is idempotent.
    public func revoke() {
        handle.revoke()
    }

    /// Executes work while access to the underlying resource remains active.
    @discardableResult
    public func withAccess<T>(_ work: (URL) throws -> T) rethrows -> T {
        try work(url)
    }
}

extension SecurityScopedURL {
    public static func == (lhs: SecurityScopedURL, rhs: SecurityScopedURL) -> Bool {
        lhs.url == rhs.url
    }
}

private extension SecurityScopedURL {
    final class Handle: @unchecked Sendable {
        private let url: URL
        private let manager: any SecurityScopedAccessManaging
        private let lock = NSLock()
        private var isActive = true

        init(url: URL, manager: any SecurityScopedAccessManaging) {
            self.url = url
            self.manager = manager
        }

        func revoke() {
            lock.lock()
            defer { lock.unlock() }
            guard isActive else { return }
            isActive = false
            manager.stopAccessing(url)
        }

        deinit {
            revoke()
        }
    }
}
