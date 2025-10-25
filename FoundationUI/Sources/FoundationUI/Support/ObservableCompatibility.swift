// swift-tools-version: 6.0
#if canImport(Combine)
import Combine

/// Typealias bridging Combine's ``ObservableObject`` into FoundationUI sources.
public typealias FoundationUIObservableObject = ObservableObject

/// Typealias bridging Combine's ``Published`` property wrapper into FoundationUI sources.
public typealias FoundationUIPublished<Value> = Published<Value>
#else
/// Lightweight protocol matching Combine's ``ObservableObject`` to preserve
/// cross-platform compatibility when Combine is unavailable (e.g. on Linux).
public protocol FoundationUIObservableObject { }

/// Property wrapper mirroring Combine's ``Published`` for Linux toolchains.
@propertyWrapper
public struct FoundationUIPublished<Value> {
    /// Stored value managed by the wrapper.
    public var wrappedValue: Value

    /// Creates a published value wrapper mirroring Combine behaviour on Apple platforms.
    /// - Parameter wrappedValue: The initial value for the published property.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif
