import Foundation

public protocol TransitionModifier {
    
    associatedtype Root
    associatedtype Value
    
    func matches(other: Self) -> Bool
    func set(value: Value, to root: Root)
    func value(for root: Root) -> Value
    var any: AnyTransitionModifier<Root> { get }
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

extension TransitionModifier {
    
    public var any: AnyTransitionModifier<Root> {
        AnyTransitionModifier(self)
    }
    
    public func map<T>(_ transform: @escaping (T) -> Root) -> MapTransitionModifier<Self, T> {
        MapTransitionModifier(base: self, transform: transform)
    }
}

public struct AnyTransitionModifier<Root>: TransitionModifier {
    
    private let isMatch: (AnyTransitionModifier) -> Bool
    private let setter: (Any, Root) -> Void
    private let getter: (Root) -> Any
    private let base: Any
    
    public init<T: TransitionModifier>(_ modifier: T) where T.Root == Root {
        base = modifier
        isMatch = {
            ($0.base as? T).map(modifier.matches) ?? false
        }
        setter = {
            guard let value = $0 as? T.Value else { return }
            modifier.set(value: value, to: $1)
        }
        getter = {
            modifier.value(for: $0)
        }
    }
    
    public var any: AnyTransitionModifier<Root> { self }
    
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

public struct MapTransitionModifier<Base: TransitionModifier, Root>: TransitionModifier {
    
    public typealias Value = Base.Value
    
    private let base: Base
    private let map: (Root) -> Base.Root
    
    public init(base: Base, transform: @escaping (Root) -> Base.Root) {
        self.base = base
        self.map = transform
    }
    
    public func matches(other: MapTransitionModifier<Base, Root>) -> Bool {
        base.matches(other: other.base)
    }
    
    public func set(value: Base.Value, to root: Root) {
        base.set(value: value, to: map(root))
    }
    
    public func value(for root: Root) -> Base.Value {
        base.value(for: map(root))
    }
}
