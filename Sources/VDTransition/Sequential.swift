import Foundation

struct SequentialModifier<Root>: TransitionModifier {
    
    var modifiers: [[AnyTransitionModifier<Root>]]
    
    func matches(other: SequentialModifier<Root>) -> Bool {
        false
    }
    
    func set(value: [[Any]], to root: Root) {
        zip(value, modifiers).forEach {
            zip($0.1, $0.0).forEach {
                $0.0.set(value: $0.1, to: root)
            }
        }
    }
    
    func value(for root: Root) -> [[Any]] {
        modifiers.map { $0.map { $0.value(for: root) } }
    }
}
