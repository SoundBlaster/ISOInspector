#if canImport(Combine)
import Combine

public typealias FoundationUIObservableObject = ObservableObject
public typealias FoundationUIPublished<Value> = Published<Value>
#else
public protocol FoundationUIObservableObject { }

@propertyWrapper
public struct FoundationUIPublished<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif
