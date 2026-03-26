import Foundation

/// A composable, keyPath-driven view transition.
///
/// `UITransition` animates one or more properties of a view (`Base`) between an identity state
/// and a transformed state. Transitions are pure functions: they receive the current progress,
/// the view, and captured initial values, and return the new property values.
///
/// **KeyPath matching and conflict detection.**
/// Transitions that share a keyPath are detected as conflicting and composed sequentially
/// via ``combined(_:)-1tcyc``. Matching relies on `PartialKeyPath` identity, which means:
/// - Computed properties and protocol-defined aliases (e.g. `Transformable.affineTransform`
///   vs `UIView.transform`) produce **different** keyPaths even if they access the same storage.
/// - For `Transformable` properties (`affineTransform`, `anchorPoint`), prefer the library-provided
///   factory methods (`.scale()`, `.rotate()`, `.offset()`, `.anchor()`) which use consistent keyPaths.
///   Passing `\.transform` directly via the generic init will **not** match `.scale()` for conflict detection.
///
/// ```swift
/// // Single property:
/// let fade = UITransition<UIView>(\.alpha) { progress, view, alpha in
///     progress.value(identity: alpha, transformed: 0)
/// }
///
/// // Combine non-conflicting:
/// let combined: UIViewTransition = [.opacity, .scale(0.5)]
///
/// // Apply:
/// view.set(hidden: true, transition: .opacity, animation: .spring())
/// ```
public struct UITransition<Base>: ExpressibleByArrayLiteral {

    private var transitions: [SingleTransition]

    struct SingleTransition {

        var transition: Transition
        var accessors: [PropertyAccessor<Base>]
        var initialState: [PartialKeyPath<Base>: Any]?
    }

    /// Whether the transition has no effect (contains no property animations).
    public var isIdentity: Bool {
        transitions.isEmpty
    }

    // MARK: - Single keyPath init

    /// Creates a transition that animates a single property.
    ///
    /// - Parameters:
    ///   - keyPath: Stored property to animate. Avoid computed or aliased keyPaths — use
    ///     library factory methods for `Transformable` properties instead.
    ///   - initialState: Optional fixed identity value. When `nil`, the value is captured
    ///     from the view at ``beforeTransition(view:)`` time.
    ///   - transition: Pure function returning the new property value for the given progress.
    ///     - `progress`: Current animation progress (insertion or removal, 0…1).
    ///     - `Base`: The view being animated (read-only context, do not mutate directly).
    ///     - `T`: The captured initial value of the property.
    ///     - Returns: The new value to write to the property.
    public init<T>(
        _ keyPath: ReferenceWritableKeyPath<Base, T>,
        initialState: T? = nil,
        transition: @escaping (Progress, Base, T) -> T
    ) {
        let accessor = PropertyAccessor(keyPath)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let value = initialState ?? (state[keyPath] as? T) ?? view[keyPath: keyPath]
                    return [keyPath: transition(progress, view, value)]
                },
                accessors: [accessor],
                initialState: initialState.map { [keyPath: $0 as Any] }
            )
        ]
    }

    // MARK: - Two keyPath init

    /// Creates a transition that animates two properties atomically.
    ///
    /// All multi-keyPath inits (2–12) work the same way: properties are captured together,
    /// passed as a tuple to the transition closure, and the returned tuple is applied back
    /// in declaration order. The order matters for properties with dependencies
    /// (e.g. `anchorPoint` before `affineTransform`).
    ///
    /// - Parameters:
    ///   - kp1: First property keyPath.
    ///   - kp2: Second property keyPath.
    ///   - initialState: Optional fixed identity values as a tuple. When `nil`, values are
    ///     captured from the view.
    ///   - transition: Pure function `(Progress, Base, (T1, T2)) -> (T1, T2)`.
    public init<T1, T2>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        initialState: (T1, T2)? = nil,
        transition: @escaping (Progress, Base, (T1, T2)) -> (T1, T2)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2 {
                        v = (v1, v2)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any]
                },
                accessors: [a1, a2],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any] }
            )
        ]
    }

    // MARK: - Three keyPath init

    public init<T1, T2, T3>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        initialState: (T1, T2, T3)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3)) -> (T1, T2, T3)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3 {
                        v = (v1, v2, v3)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any]
                },
                accessors: [a1, a2, a3],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any] }
            )
        ]
    }

    // MARK: - Four keyPath init

    public init<T1, T2, T3, T4>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        initialState: (T1, T2, T3, T4)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4)) -> (T1, T2, T3, T4)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4 {
                        v = (v1, v2, v3, v4)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any]
                },
                accessors: [a1, a2, a3, a4],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any] }
            )
        ]
    }

    // MARK: - Five keyPath init

    public init<T1, T2, T3, T4, T5>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        initialState: (T1, T2, T3, T4, T5)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5)) -> (T1, T2, T3, T4, T5)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5 {
                        v = (v1, v2, v3, v4, v5)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any]
                },
                accessors: [a1, a2, a3, a4, a5],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any] }
            )
        ]
    }

    // MARK: - Six keyPath init

    public init<T1, T2, T3, T4, T5, T6>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        initialState: (T1, T2, T3, T4, T5, T6)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6)) -> (T1, T2, T3, T4, T5, T6)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6 {
                        v = (v1, v2, v3, v4, v5, v6)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any] }
            )
        ]
    }

    // MARK: - Seven keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        initialState: (T1, T2, T3, T4, T5, T6, T7)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7)) -> (T1, T2, T3, T4, T5, T6, T7)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7 {
                        v = (v1, v2, v3, v4, v5, v6, v7)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any] }
            )
        ]
    }

    // MARK: - Eight keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7, T8>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        _ kp8: ReferenceWritableKeyPath<Base, T8>,
        initialState: (T1, T2, T3, T4, T5, T6, T7, T8)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7, T8)) -> (T1, T2, T3, T4, T5, T6, T7, T8)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        let a8 = PropertyAccessor(kp8)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7, T8)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7, let v8 = state[kp8] as? T8 {
                        v = (v1, v2, v3, v4, v5, v6, v7, v8)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7], view[keyPath: kp8])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any, kp8: result.7 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7, a8],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any, kp8: $0.7 as Any] }
            )
        ]
    }

    // MARK: - Nine keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        _ kp8: ReferenceWritableKeyPath<Base, T8>,
        _ kp9: ReferenceWritableKeyPath<Base, T9>,
        initialState: (T1, T2, T3, T4, T5, T6, T7, T8, T9)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7, T8, T9)) -> (T1, T2, T3, T4, T5, T6, T7, T8, T9)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        let a8 = PropertyAccessor(kp8)
        let a9 = PropertyAccessor(kp9)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7, T8, T9)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7, let v8 = state[kp8] as? T8, let v9 = state[kp9] as? T9 {
                        v = (v1, v2, v3, v4, v5, v6, v7, v8, v9)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7], view[keyPath: kp8], view[keyPath: kp9])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any, kp8: result.7 as Any, kp9: result.8 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7, a8, a9],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any, kp8: $0.7 as Any, kp9: $0.8 as Any] }
            )
        ]
    }

    // MARK: - Ten keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        _ kp8: ReferenceWritableKeyPath<Base, T8>,
        _ kp9: ReferenceWritableKeyPath<Base, T9>,
        _ kp10: ReferenceWritableKeyPath<Base, T10>,
        initialState: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)) -> (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        let a8 = PropertyAccessor(kp8)
        let a9 = PropertyAccessor(kp9)
        let a10 = PropertyAccessor(kp10)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7, let v8 = state[kp8] as? T8, let v9 = state[kp9] as? T9, let v10 = state[kp10] as? T10 {
                        v = (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7], view[keyPath: kp8], view[keyPath: kp9], view[keyPath: kp10])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any, kp8: result.7 as Any, kp9: result.8 as Any, kp10: result.9 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any, kp8: $0.7 as Any, kp9: $0.8 as Any, kp10: $0.9 as Any] }
            )
        ]
    }

    // MARK: - Eleven keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        _ kp8: ReferenceWritableKeyPath<Base, T8>,
        _ kp9: ReferenceWritableKeyPath<Base, T9>,
        _ kp10: ReferenceWritableKeyPath<Base, T10>,
        _ kp11: ReferenceWritableKeyPath<Base, T11>,
        initialState: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)) -> (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        let a8 = PropertyAccessor(kp8)
        let a9 = PropertyAccessor(kp9)
        let a10 = PropertyAccessor(kp10)
        let a11 = PropertyAccessor(kp11)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7, let v8 = state[kp8] as? T8, let v9 = state[kp9] as? T9, let v10 = state[kp10] as? T10, let v11 = state[kp11] as? T11 {
                        v = (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7], view[keyPath: kp8], view[keyPath: kp9], view[keyPath: kp10], view[keyPath: kp11])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any, kp8: result.7 as Any, kp9: result.8 as Any, kp10: result.9 as Any, kp11: result.10 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any, kp8: $0.7 as Any, kp9: $0.8 as Any, kp10: $0.9 as Any, kp11: $0.10 as Any] }
            )
        ]
    }

    // MARK: - Twelve keyPath init

    public init<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(
        _ kp1: ReferenceWritableKeyPath<Base, T1>,
        _ kp2: ReferenceWritableKeyPath<Base, T2>,
        _ kp3: ReferenceWritableKeyPath<Base, T3>,
        _ kp4: ReferenceWritableKeyPath<Base, T4>,
        _ kp5: ReferenceWritableKeyPath<Base, T5>,
        _ kp6: ReferenceWritableKeyPath<Base, T6>,
        _ kp7: ReferenceWritableKeyPath<Base, T7>,
        _ kp8: ReferenceWritableKeyPath<Base, T8>,
        _ kp9: ReferenceWritableKeyPath<Base, T9>,
        _ kp10: ReferenceWritableKeyPath<Base, T10>,
        _ kp11: ReferenceWritableKeyPath<Base, T11>,
        _ kp12: ReferenceWritableKeyPath<Base, T12>,
        initialState: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)? = nil,
        transition: @escaping (Progress, Base, (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)) -> (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)
    ) {
        let a1 = PropertyAccessor(kp1)
        let a2 = PropertyAccessor(kp2)
        let a3 = PropertyAccessor(kp3)
        let a4 = PropertyAccessor(kp4)
        let a5 = PropertyAccessor(kp5)
        let a6 = PropertyAccessor(kp6)
        let a7 = PropertyAccessor(kp7)
        let a8 = PropertyAccessor(kp8)
        let a9 = PropertyAccessor(kp9)
        let a10 = PropertyAccessor(kp10)
        let a11 = PropertyAccessor(kp11)
        let a12 = PropertyAccessor(kp12)
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, state in
                    let v: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12)
                    if let initial = initialState {
                        v = initial
                    } else if let v1 = state[kp1] as? T1, let v2 = state[kp2] as? T2, let v3 = state[kp3] as? T3, let v4 = state[kp4] as? T4, let v5 = state[kp5] as? T5, let v6 = state[kp6] as? T6, let v7 = state[kp7] as? T7, let v8 = state[kp8] as? T8, let v9 = state[kp9] as? T9, let v10 = state[kp10] as? T10, let v11 = state[kp11] as? T11, let v12 = state[kp12] as? T12 {
                        v = (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12)
                    } else {
                        v = (view[keyPath: kp1], view[keyPath: kp2], view[keyPath: kp3], view[keyPath: kp4], view[keyPath: kp5], view[keyPath: kp6], view[keyPath: kp7], view[keyPath: kp8], view[keyPath: kp9], view[keyPath: kp10], view[keyPath: kp11], view[keyPath: kp12])
                    }
                    let result = transition(progress, view, v)
                    return [kp1: result.0 as Any, kp2: result.1 as Any, kp3: result.2 as Any, kp4: result.3 as Any, kp5: result.4 as Any, kp6: result.5 as Any, kp7: result.6 as Any, kp8: result.7 as Any, kp9: result.8 as Any, kp10: result.9 as Any, kp11: result.10 as Any, kp12: result.11 as Any]
                },
                accessors: [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12],
                initialState: initialState.map { [kp1: $0.0 as Any, kp2: $0.1 as Any, kp3: $0.2 as Any, kp4: $0.3 as Any, kp5: $0.4 as Any, kp6: $0.5 as Any, kp7: $0.6 as Any, kp8: $0.7 as Any, kp9: $0.8 as Any, kp10: $0.9 as Any, kp11: $0.10 as Any, kp12: $0.11 as Any] }
            )
        ]
    }

    // MARK: - TransitionModifier init (backward compat)

    /// Creates a transition from a ``TransitionModifier`` (legacy side-effecting API).
    ///
    /// Unlike keyPath-based inits, the transition closure here is side-effecting (`-> Void`)
    /// and writes to the view directly. This init exists for backward compatibility with
    /// `TransitionModifier`-based transitions like `transform(to:)`.
    ///
    /// - Parameters:
    ///   - modifier: The transition modifier providing get/set for the animated value.
    ///   - initialState: Optional fixed identity value.
    ///   - transition: Side-effecting closure that mutates the view.
    public init<T: TransitionModifier>(
        _ modifier: T,
        initialState: T.Value? = nil,
        transition: @escaping (Progress, Base, T.Value) -> Void
    ) where T.Root == Base {
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, _ in
                    let value = initialState ?? modifier.value(for: view)
                    transition(progress, view, value)
                    // Side-effecting: no state to return
                    return [:]
                },
                accessors: [],
                initialState: nil
            )
        ]
    }

    init(
        transitions: [SingleTransition]
    ) {
        self.transitions = transitions
    }

    public init(arrayLiteral elements: UITransition...) {
        self = .combined(elements)
    }

    // MARK: - State management

    /// Captures the current property values from the view as the identity (initial) state.
    ///
    /// Call this once before the animation begins. Subsequent calls to ``update(progress:view:)``
    /// will interpolate between this captured state and the transformed state.
    ///
    /// - Parameter view: The view whose property values will be captured.
    public mutating func beforeTransition(view: Base) {
        for i in transitions.indices {
            transitions[i].initialState = transitions[i].captureState(from: view)
        }
    }

    /// Captures initial state only if not already captured, optionally reusing state from a matching transition.
    ///
    /// When replacing one transition with another mid-animation, pass the old transition as `current`
    /// to preserve its captured state (avoiding a visual jump). If `current` doesn't match or has
    /// no captured state, falls back to capturing fresh values from the view.
    ///
    /// - Parameters:
    ///   - view: The view to capture from if needed.
    ///   - current: An existing transition whose captured state should be reused if it matches.
    public mutating func beforeTransitionIfNeeded(view: Base, current: UITransition? = nil) {
        guard transitions.contains(where: { $0.initialState == nil }) else { return }
        if let current, matches(current), current.transitions.contains(where: { $0.initialState != nil }) {
            for i in transitions.indices {
                transitions[i].initialState = current.transitions[i].initialState
            }
        } else {
            beforeTransition(view: view)
        }
    }

    /// Returns `true` if both transitions animate the same set of properties (by keyPath identity).
    ///
    /// Used to determine whether one transition can replace another without visual discontinuity.
    /// Note: matching relies on `PartialKeyPath` identity — see the type-level doc comment
    /// for caveats about computed/aliased keyPaths.
    ///
    /// - Parameter other: The transition to compare against.
    /// - Returns: `true` if both transitions have the same accessor keys in the same order.
    public func matches(_ other: UITransition) -> Bool {
        other.transitions.count == transitions.count &&
        zip(other.transitions, transitions).allSatisfy { a, b in
            a.accessorKeys == b.accessorKeys
        }
    }

    /// Clears captured initial state, forcing a fresh capture on the next ``beforeTransition(view:)``.
    public mutating func reset() {
        for i in transitions.indices {
            transitions[i].initialState = nil
        }
    }

    /// Restores the view's properties to the captured initial state.
    ///
    /// Typically called in the animation completion handler to clean up after the transition.
    ///
    /// - Parameter view: The view to restore.
    public func setInitialState(view: Base) {
        for t in transitions {
            if let state = t.initialState {
                t.applyState(state, to: view)
            }
        }
    }

    /// Applies the transition at the given progress, writing computed values to the view.
    ///
    /// - Parameters:
    ///   - progress: The current animation progress (e.g. `.insertion(0.5)`).
    ///   - view: The view to update.
    public func update(progress: Progress, view: Base) {
        for t in transitions {
            let state = t.initialState ?? t.captureState(from: view)
            let result = t.transition.block(progress, view, state)
            t.applyState(result, to: view)
        }
    }

    /// Pattern matching operator. Equivalent to ``matches(_:)``.
    public static func ~=(_ lhs: UITransition, _ rhs: UITransition) -> Bool {
        lhs.matches(rhs)
    }
}

// MARK: - SingleTransition helpers

extension UITransition.SingleTransition {

    /// Reads current values for all accessors from the view.
    func captureState(from view: Base) -> [PartialKeyPath<Base>: Any] {
        Dictionary(uniqueKeysWithValues: accessors.map { ($0.key, view[keyPath: $0.key]) })
    }

    /// Writes state values back to the view via accessors.
    func applyState(_ state: [PartialKeyPath<Base>: Any], to view: Base) {
        for accessor in accessors {
            if let value = state[accessor.key] {
                accessor.set(view, value)
            }
        }
    }

    /// Set of accessor keys for matching.
    var accessorKeys: Set<PartialKeyPath<Base>> {
        Set(accessors.map(\.key))
    }
}

extension UITransition {

    struct Transition {

        let block: (_ progress: Progress, _ view: Base, _ state: [PartialKeyPath<Base>: Any]) -> [PartialKeyPath<Base>: Any]
    }
}

extension UITransition {

    /// Combines all transition, returning a new transition that is the result of all transitions being applied.
    ///
    /// - Parameter transitions: Transitions to be combined.
    /// - Returns: New transition.
    public static func combined(_ transitions: [UITransition]) -> UITransition {
        guard !transitions.isEmpty else { return .identity }

        var result = UITransition.identity

        for single in transitions.flatMap({ $0.flat }) {
            let singleT = single.transitions[0]
            let singleKeys = singleT.accessorKeys
            if let i = result.transitions.firstIndex(where: { !$0.accessorKeys.isDisjoint(with: singleKeys) }) {
                let current = result.transitions[i]
                result.transitions[i] = SingleTransition(
                    transition: Transition { progress, view, state in
                        var next = current.transition.block(progress, view, state)
                        let singleResult = singleT.transition.block(progress, view, next)
                        next.merge(singleResult) { _, new in new }
                        return next
                    },
                    accessors: current.accessors + singleT.accessors.filter { sAcc in
                        !current.accessors.contains { $0.key == sAcc.key }
                    },
                    initialState: current.initialState
                )
            } else {
                result.transitions += single.transitions
            }
        }
        return result
    }

    /// Combines this transition with another, returning a new transition that is the result of both transitions being applied.
    public func combined(with transition: UITransition) -> UITransition {
        .combined(self, transition)
    }

    /// Creates a transition that applies one of two branches depending on a condition evaluated at each progress update.
    ///
    /// - Parameters:
    ///   - condition: Predicate evaluated on each progress value.
    ///   - trueTransition: Applied when `condition` returns `true`.
    ///   - falseTransition: Applied when `condition` returns `false`.
    /// - Returns: A transition that delegates to the matching branch.
    public static func conditional(
        _ condition: @escaping (Progress) -> Bool,
        true trueTransition: UITransition,
        false falseTransition: UITransition
    ) -> UITransition {
        UITransition(
            transitions: trueTransition.transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        if condition(progress) {
                            return single.transition.block(progress, view, state)
                        } else {
                            return state
                        }
                    },
                    accessors: single.accessors,
                    initialState: nil
                )
            } + falseTransition.transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        if !condition(progress) {
                            return single.transition.block(progress, view, state)
                        } else {
                            return state
                        }
                    },
                    accessors: single.accessors,
                    initialState: nil
                )
            }
        )
    }

    private var flat: [UITransition] {
        transitions.map {
            UITransition(transitions: [$0])
        }
    }

    /// Returns a transition that only applies when the predicate is `true`; otherwise preserves identity state.
    ///
    /// - Parameter type: Predicate on progress. When `false`, the transition is a no-op for that update.
    /// - Returns: A filtered transition.
    public func filter(_ type: @escaping (Progress) -> Bool) -> UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        guard type(progress) else { return state }
                        return single.transition.block(progress, view, state)
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }

    /// Returns a transition with insertion and removal swapped and progress flipped.
    ///
    /// `insertion(v)` becomes `removal(1-v)` and vice versa.
    public var inverted: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        single.transition.block(progress.inverted, view, state)
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }

    /// Returns a transition with progress reversed within the same direction.
    ///
    /// `insertion(v)` becomes `insertion(1-v)`, `removal(v)` becomes `removal(1-v)`.
    public var reversed: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        single.transition.block(progress.reversed, view, state)
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }

    /// Returns a transition that treats both directions as insertion.
    ///
    /// Removal progress is converted to insertion: `removal(v)` becomes `insertion(1-v)`.
    public var insertion: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        switch progress {
                        case .insertion:
                            return single.transition.block(progress, view, state)
                        case let .removal(value):
                            return single.transition.block(.insertion(1 - value), view, state)
                        }
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }

    /// Returns a transition that treats both directions as removal.
    ///
    /// Insertion progress is converted to removal: `insertion(v)` becomes `removal(1-v)`.
    public var removal: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, state in
                        switch progress {
                        case let .insertion(value):
                            return single.transition.block(.removal(1 - value), view, state)
                        case .removal:
                            return single.transition.block(progress, view, state)
                        }
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }

    /// Returns a transition frozen at a specific progress value, ignoring the actual progress passed to `update`.
    ///
    /// - Parameter progress: The fixed progress value to use.
    /// - Returns: A constant transition.
    public func constant(at progress: Progress) -> UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { _, view, state in
                        single.transition.block(progress, view, state)
                    },
                    accessors: single.accessors,
                    initialState: single.initialState
                )
            }
        )
    }
}
