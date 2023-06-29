import Foundation

/// UIKit transition
public struct UITransition<Base>: ExpressibleByArrayLiteral {

    private var transitions: [Transition]
    private var modifiers: [AnyTransitionModifier<Base>]
    private var initialStates: [Any]

    public var isIdentity: Bool {
        transitions.isEmpty
    }
    
    public init<T: TransitionModifier>(
        _ modifier: T,
        initialState: T.Value? = nil,
        transition: @escaping (Progress, Base, T.Value) -> Void
    ) where T.Root == Base {
        transitions = [
            Transition { progress, view, value in
                let value = initialState ?? (value as? T.Value) ?? modifier.value(for: view)
                transition(progress, view, value)
            }
        ]
        modifiers = [
            AnyTransitionModifier(modifier)
        ]
        initialStates = initialState.map { [$0] } ?? []
    }
    
    public init<T>(
        _ keyPath: ReferenceWritableKeyPath<Base, T>,
        initialState: T? = nil,
        transition: @escaping (Progress, Base, T) -> Void
    ) {
        transitions = [
            Transition { progress, view, value in
                let value = initialState ?? (value as? T) ?? view[keyPath: keyPath]
                transition(progress, view, value)
            }
        ]
        modifiers = [
            AnyTransitionModifier(KeyPathModifier(keyPath: keyPath))
        ]
        initialStates = initialState.map { [$0] } ?? []
    }

    init(
        transitions: [Transition],
        modifiers: [AnyTransitionModifier<Base>],
        initialStates: [Any]
    ) {
        self.transitions = transitions
        self.modifiers = modifiers
        self.initialStates = initialStates
    }

    public init(arrayLiteral elements: UITransition...) {
        self = .combined(elements)
    }

    public mutating func beforeTransition(view: Base, current: UITransition? = nil) {
        if let current, matches(current), !current.initialStates.isEmpty {
            initialStates = current.initialStates
        } else {
            initialStates = modifiers.map { $0.value(for: view) }
        }
    }

    public mutating func beforeTransitionIfNeeded(view: Base, current: UITransition? = nil) {
        guard initialStates.isEmpty else { return }
        beforeTransition(view: view, current: current)
    }
    
    public func matches(_ other: UITransition) -> Bool {
        other.modifiers.count == modifiers.count &&
        !zip(other.modifiers, modifiers).contains {
            !$0.0.matches(other: $0.1)
        }
    }

    public mutating func reset() {
        initialStates = []
    }

    public func setInitialState(view: Base) {
        zip(initialStates, modifiers).forEach {
            $0.1.set(value: $0.0, to: view)
        }
    }

    public func update(progress: Progress, view: Base) {
        var initialStates = initialStates
        if initialStates.isEmpty {
            initialStates = modifiers.map { $0.value(for: view) }
        }
        zip(transitions, initialStates).forEach {
            $0.0.block(progress, view, $0.1)
        }
    }
    
    public static func ~=(_ lhs: UITransition, _ rhs: UITransition) -> Bool {
        lhs.matches(rhs)
    }
}

extension UITransition {
    
    struct Transition {
        
        var block: (_ progress: Progress, _ view: Base, _ initialValue: Any?) -> Void
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

        for transition in transitions.flatMap({ $0.flat }) {
            if let i = result.modifiers.firstIndex(where: { transition.modifiers[0].matches(other: $0) }) {
                let current = result.transitions[i]
                result.transitions[i] = Transition {
                    current.block($0, $1, $2)
                    transition.transitions[0].block($0, $1, $2)
                }
            } else {
                result.transitions += transition.transitions
                result.modifiers += transition.modifiers
                result.initialStates += result.initialStates
            }
        }
        if result.initialStates.count != result.transitions.count {
            result.initialStates = []
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
            transitions: trueTransition.transitions.map { transition in
                Transition {
                    if condition($0) {
                        transition.block($0, $1, $2)
                    }
                }
            } + falseTransition.transitions.map { transition in
                Transition {
                    if !condition($0) {
                        transition.block($0, $1, $2)
                    }
                }
            },
            modifiers: trueTransition.modifiers + falseTransition.modifiers,
            initialStates: []
        )
    }
    
    private var flat: [UITransition] {
        if initialStates.isEmpty {
            return zip(transitions, modifiers).map {
                UITransition(transitions: [$0.0], modifiers: [$0.1], initialStates: [])
            }
        } else {
            return zip(zip(transitions, modifiers), initialStates).map {
                UITransition(transitions: [$0.0.0], modifiers: [$0.0.1], initialStates: [$0.1])
            }
        }
    }

    public func filter(_ type: @escaping (Progress) -> Bool) -> UITransition {
        UITransition(
            transitions: transitions.map { transition in
                Transition {
                    guard type($0) else { return }
                    transition.block($0, $1, $2)
                }
            },
            modifiers: modifiers,
            initialStates: initialStates
        )
    }

    public var inverted: UITransition {
        UITransition(
            transitions: transitions.map { transition in
                Transition {
                    transition.block($0.inverted, $1, $2)
                }
            },
            modifiers: modifiers,
            initialStates: initialStates
        )
    }

    public var reversed: UITransition {
        UITransition(
            transitions: transitions.map { transition in
                Transition {
                    transition.block($0.reversed, $1, $2)
                }
            },
            modifiers: modifiers,
            initialStates: initialStates
        )
    }
    
    public func map<T>(_ transform: @escaping (T) -> Base) -> UITransition<T> {
        UITransition<T>(
            transitions: transitions.map { transition in
                UITransition<T>.Transition {
                    transition.block($0, transform($1), $2)
                }
            },
            modifiers: modifiers.map {
                $0.map(transform).any
            },
            initialStates: initialStates
        )
    }
}
