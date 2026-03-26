import Foundation

/// UIKit transition
public struct UITransition<Base>: ExpressibleByArrayLiteral {

    private var transitions: [SingleTransition]

    struct SingleTransition {

        var transition: Transition
        var modifier: AnyTransitionModifier<Base>
        var initialState: Any?
    }

    public var isIdentity: Bool {
        transitions.isEmpty
    }
    
    public init<T: TransitionModifier>(
        _ modifier: T,
        initialState: T.Value? = nil,
        transition: @escaping (Progress, Base, T.Value) -> Void
    ) where T.Root == Base {
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, value in
                    let value = initialState ?? (value as? T.Value) ?? modifier.value(for: view)
                    return transition(progress, view, value)
                },
                modifier: AnyTransitionModifier(modifier),
                
                initialState: initialState
            )
        ]
    }
    
    public init<T>(
        _ keyPath: ReferenceWritableKeyPath<Base, T>,
        initialState: T? = nil,
        transition: @escaping (Progress, Base, T) -> T
    ) {
        transitions = [
            SingleTransition(
                transition: Transition { progress, view, value in
                    let value = initialState ?? (value as? T) ?? view[keyPath: keyPath]
                    return transition(progress, view, value)
                },
                modifier: AnyTransitionModifier(KeyPathModifier(keyPath: keyPath)),
                initialState: initialState
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

    public mutating func beforeTransition(view: Base) {
        for i in transitions.indices {
            transitions[i].initialState = transitions[i].modifier.value(for: view)
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
        !zip(other.transitions, transitions).contains {
            !$0.0.modifier.matches(other: $0.1.modifier)
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
                t.modifier.set(value: state, to: view)
            }
        }
    }

    public func update(progress: Progress, view: Base) {
        for t in transitions {
            let state = t.initialState ?? t.modifier.value(for: view)
            let value = t.transition.block(progress, view, state)
            t.modifier.set(value: value, to: view)
        }
    }

    public static func ~=(_ lhs: UITransition, _ rhs: UITransition) -> Bool {
        lhs.matches(rhs)
    }
}

extension UITransition {

    struct Transition {

        var block: (_ progress: Progress, _ view: Base, _ initialValue: Any) -> Any
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
            if let i = result.transitions.firstIndex(where: { single.transitions[0].modifier.matches(other: $0.modifier) }) {
                let current = result.transitions[i]
                result.transitions[i] = SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        let next = current.transition.block(progress, view, initialValue)
                        return single.transitions[0].transition.block(progress, view, next)
                    },
                    modifier: current.modifier,
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
                    transition: Transition { progress, view, initialValue in
                        if condition(progress) {
                            return single.transition.block(progress, view, initialValue)
                        } else {
                            return initialValue
                        }
                    },
                    modifier: single.modifier,
                    initialState: nil
                )
            } + falseTransition.transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        if !condition(progress) {
                            return single.transition.block(progress, view, initialValue)
                        } else {
                            return initialValue
                        }
                    },
                    modifier: single.modifier,
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
                    transition: Transition { progress, view, initialValue in
                        guard type(progress) else { return initialValue }
                        return single.transition.block(progress, view, initialValue)
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }

    public var inverted: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        single.transition.block(progress.inverted, view, initialValue)
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }

    public var reversed: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        single.transition.block(progress.reversed, view, initialValue)
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }
    
    public var insertion: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        switch progress {
                        case .insertion:
                            return single.transition.block(progress, view, initialValue)
                        case let .removal(value):
                            return single.transition.block(.insertion(1 - value), view, initialValue)
                        }
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }
    
    public var removal: UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { progress, view, initialValue in
                        switch progress {
                        case let .insertion(value):
                            return single.transition.block(.removal(1 - value), view, initialValue)
                        case .removal:
                            return single.transition.block(progress, view, initialValue)
                        }
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }
    
    
    public func constant(at progress: Progress) -> UITransition {
        UITransition(
            transitions: transitions.map { single in
                SingleTransition(
                    transition: Transition { _, view, initialValue in
                        single.transition.block(progress, view, initialValue)
                    },
                    modifier: single.modifier,
                    initialState: single.initialState
                )
            }
        )
    }
    
    public func map<T>(_ transform: @escaping (T) -> Base) -> UITransition<T> {
        UITransition<T>(
            transitions: transitions.map { single in
                UITransition<T>.SingleTransition(
                    transition: UITransition<T>.Transition { progress, view, initialValue in
                        single.transition.block(progress, transform(view), initialValue)
                    },
                    modifier: single.modifier.map(transform).any,
                    initialState: single.initialState
                )
            }
        )
    }
}
