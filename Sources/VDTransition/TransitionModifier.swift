import Foundation

public protocol TransitionModifier {
    
    associatedtype Root
    associatedtype Value
    
    func matches(other: Self) -> Bool
    func set(value: Value, to root: Root)
    func value(for root: Root) -> Value
}

public struct KeyPathModifier<Root, Value>: TransitionModifier {
    
    public var keyPath: ReferenceWritableKeyPath<Root, Value>
    
    public func matches(other: KeyPathModifier) -> Bool {
        other.keyPath == keyPath
    }
    
    public func set(value: Value, to root: Root) {
        root[keyPath: keyPath] = value
    }
    
    public func value(for root: Root) -> Value {
        root[keyPath: keyPath]
    }
}

public struct AnyTransitionModifier<Root>: TransitionModifier {
    
    private let isMatch: (AnyTransitionModifier) -> Bool
    private let setter: (Any, Root) -> Void
    private let getter: (Root) -> Any
    
    public init<T: TransitionModifier>(_ modifier: T) where T.Root == Root {
        isMatch = {
            ($0 as? T).map { modifier.matches(other: $0) } ?? false
        }
        setter = {
            guard let value = $0 as? T.Value else { return }
            modifier.set(value: value, to: $1)
        }
        getter = {
            modifier.value(for: $0)
        }
    }
    
    public func matches(other: AnyTransitionModifier) -> Bool {
        isMatch(other)
    }
    
    public func set(value: Any, to root: Root) {
        setter(value, root)
    }
    
    public func value(for root: Root) -> Any {
        getter(root)
    }
}
