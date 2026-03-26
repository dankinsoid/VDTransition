import Foundation

/// @ai-generated(guided)
/// Type-erased property accessor keyed by `PartialKeyPath` for conflict detection.
///
/// Reading uses the keyPath directly. Writing uses a type-erased closure
/// created at init from a `ReferenceWritableKeyPath`.
///
/// ```swift
/// let accessor = PropertyAccessor<UIView>(\.alpha)
/// let value = view[keyPath: accessor.key]   // reads as Any
/// accessor.set(view, 0.5)                   // writes view.alpha = 0.5
/// ```
public struct PropertyAccessor<Base> {

    /// The partial key path — used for reading and for matching conflicts.
    public let key: PartialKeyPath<Base>

    /// Writes a type-erased value to the base object.
    public let set: (Base, Any) -> Void

    /// Creates an accessor from a `ReferenceWritableKeyPath`.
    ///
    /// - Parameter keyPath: Key path to a stored property on `Base`.
    public init<Value>(_ keyPath: ReferenceWritableKeyPath<Base, Value>) {
        self.key = keyPath
        self.set = { base, value in
            guard let typed = value as? Value else { return }
            base[keyPath: keyPath] = typed
        }
    }
}
