#if canImport(UIKit)
import UIKit

extension UIStackView {

    /// Animated add an arranged subview with given transition.
    ///
    /// - Parameters:
    ///   - subview: Subview to be added.
    ///   - index: Index of the subview to be added, add to end if nil.
    ///   - transition: Transition.
    ///   - animation: Animation parameters.
    ///   - completion: Block to be executed when transition finishes.
    public func addArranged(
        subview: UIView,
        at index: Int? = nil,
        transition: UIViewTransition,
        animation: UIKitAnimation = .default,
        completion: (() -> Void)? = nil
    ) {
        let i = index ?? arrangedSubviews.count
        guard !subview.isHidden else {
            insertArrangedSubview(subview, at: i)
            completion?()
            return
        }
        subview.isHidden = true
        insertArrangedSubview(subview, at: i)
        subview.set(hidden: false, transition: transition, animation: animation, completion: completion)
    }

    /// Animated remove an arranged subview with given transition.
    ///
    /// - Parameters:
    ///   - subview: arranged subview to be removed.
    ///   - transition: Transition.
    ///   - animation: Animation parameters.
    ///   - completion: Block to be executed when transition finishes.
    public func removeArranged(
        subview: UIView,
        transition: UIViewTransition,
        animation: UIKitAnimation = .default,
        completion: (() -> Void)? = nil
    ) {
        guard !subview.isHidden else {
            removeArrangedSubview(subview)
            completion?()
            return
        }
        subview.set(hidden: true, transition: transition, animation: animation) {
            self.removeArrangedSubview(subview)
            subview.isHidden = false
            completion?()
        }
    }
}
#endif
