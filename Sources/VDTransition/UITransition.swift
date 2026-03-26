import Foundation

/// @ai-generated(guided)
/// UIKit transition
public struct UITransition<Base>: ExpressibleByArrayLiteral {

    private var transitions: [SingleTransition]

    struct SingleTransition {

        var transition: Transition
        var accessors: [PropertyAccessor<Base>]
        var initialState: [PartialKeyPath<Base>: Any]?
    }

    public var isIdentity: Bool {
        transitions.isEmpty
    }

    // MARK: - Single keyPath init

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

    // MARK: - TransitionModifier init (backward compat)

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

    public mutating func beforeTransition(view: Base) {
        for i in transitions.indices {
            transitions[i].initialState = transitions[i].captureState(from: view)
        }
    }

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

    public func matches(_ other: UITransition) -> Bool {
        other.transitions.count == transitions.count &&
        zip(other.transitions, transitions).allSatisfy { a, b in
            a.accessorKeys == b.accessorKeys
        }
    }

    public mutating func reset() {
        for i in transitions.indices {
            transitions[i].initialState = nil
        }
    }

    public func setInitialState(view: Base) {
        for t in transitions {
            if let state = t.initialState {
                t.applyState(state, to: view)
            }
        }
    }

    public func update(progress: Progress, view: Base) {
        for t in transitions {
            let state = t.initialState ?? t.captureState(from: view)
            let result = t.transition.block(progress, view, state)
            t.applyState(result, to: view)
        }
    }

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
