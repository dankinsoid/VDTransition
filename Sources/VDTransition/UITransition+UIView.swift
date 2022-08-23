#if canImport(UIKit)
import UIKit

public typealias UIViewTransition = UITransition<UIView>

extension UIView {

    /// Animate view with given transition.
    ///
    /// - Parameters:
    ///   - transition: Transition.
    ///   - direction: Transition direction.
    ///   - animation: Animation parameters.
    ///   - restoreState: Restore view state on animation completion
    ///   - completion: Block to be executed when animation finishes.
    public func animate(
        transition: UIViewTransition,
        direction: TransitionDirection = .removal,
        animation: UIKitAnimation = .default,
        restoreState: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        var transition = transition
        UIView.performWithoutAnimation {
            transition.beforeTransition(view: self)
            transition.update(progress: direction.at(.start), view: self)
        }
        UIView.animate(with: animation) { [self] in
            transition.update(progress: direction.at(.end), view: self)
        } completion: { [self] _ in
            completion?()
            if restoreState {
                transition.setInitialState(view: self)
            }
        }
    }

    /// Animated change `isHidden` property with given transition.
    ///
    /// - Parameters:
    ///   - hidden: `isHidden` value to be set.
    ///   - transition: Transition.
    ///   - animation: Animation parameters.
    ///   - completion: Block to be executed when transition finishes.
    public func set(hidden: Bool, transition: UIViewTransition, animation: UIKitAnimation = .default, completion: (() -> Void)? = nil) {
        set(
            hidden: hidden,
            insideAnimation: (superview as? UIStackView) != nil,
            set: { $0.isHidden = $1 },
            transition: transition,
            animation: animation,
            completion: completion
        )
    }

    /// Animated remove from superview with given transition.
    ///
    /// - Parameters:
    ///   - transition: Transition.
    ///   - animation: Animation parameters.
    ///   - completion: Block to be executed when transition finishes.
    public func removeFromSuperview(transition: UIViewTransition, animation: UIKitAnimation = .default, completion: (() -> Void)? = nil) {
        addOrRemove(to: superview, add: false, transition: transition, animation: animation, completion: completion)
    }

    /// Animated add a subview with given transition.
    ///
    /// - Parameters:
    ///   - subview: Subview to be added.
    ///   - transition: Transition.
    ///   - animation: Animation parameters.
    ///   - completion: Block to be executed when transition finishes.
    public func add(subview: UIView, transition: UIViewTransition, animation: UIKitAnimation = .default, completion: (() -> Void)? = nil) {
        subview.addOrRemove(to: self, add: true, transition: transition, animation: animation, completion: completion)
    }

    /// Animated add or remove a subview with given transition.
    public func addOrRemove(
        to superview: UIView?,
        add: Bool,
        transition: UIViewTransition,
        animation: UIKitAnimation = .default,
        completion: (() -> Void)? = nil
    ) {
        set(
            hidden: !add,
            insideAnimation: false,
            set: { if $1 { $0.removeFromSuperview() } else { superview?.addSubview(self) } },
            transition: transition,
            animation: animation,
            completion: completion
        )
    }

    private func set(
        hidden: Bool,
        insideAnimation: Bool,
        set: @escaping (UIView, Bool) -> Void,
        transition: UIViewTransition,
        animation: UIKitAnimation = .default,
        completion: (() -> Void)? = nil
    ) {
        guard !transition.isIdentity else {
            set(self, hidden)
            completion?()
            return
        }
        let direction: TransitionDirection = hidden ? .removal : .insertion
        var transition = transition
        UIView.performWithoutAnimation {
            transition.beforeTransition(view: self)
            transition.update(progress: direction.at(.start), view: self)
            if !hidden, !insideAnimation {
                set(self, false)
            }
        }
        UIView.animate(with: animation) {
            if insideAnimation {
                set(self, hidden)
                self.superview?.layoutIfNeeded()
            }
            transition.update(progress: direction.at(.end), view: self)
        } completion: { _ in
            if hidden, !insideAnimation {
                set(self, true)
            }
            transition.setInitialState(view: self)
            completion?()
        }
    }
}

extension UIWindow {

    public func set(root: UIViewController, transition: UIViewTransition, animation: UIKitAnimation = .default, completion: (() -> Void)? = nil) {
        guard rootViewController != nil else {
            rootViewController = root
            completion?()
            return
        }
        var transition = transition
        UIView.performWithoutAnimation {
            addSubview(root.view)
            root.view.frame = bounds
            transition.beforeTransition(view: root.view)
            transition.update(progress: TransitionDirection.insertion.at(.start), view: root.view)
        }
        UIView.animate(with: animation) {
            transition.update(progress: TransitionDirection.insertion.at(.end), view: self)
        } completion: { _ in
            transition.setInitialState(view: root.view)
            self.rootViewController = root
            completion?()
        }
    }
}
#endif
