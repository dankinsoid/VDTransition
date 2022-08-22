#if canImport(UIKit)
import UIKit

/// UIKit animation parameters
public struct UIKitAnimation: ExpressibleByArrayLiteral {
    
    public typealias Options = UIView.AnimationOptions

    public static var defaultDuration: Double = 0.25
    public static var defaultDamping: CGFloat = 0.825

    public var duration: Double
    public var delay: Double
    public var spring: Spring?
    public var options: Options

    public init(
        duration: Double = UIKitAnimation.defaultDuration,
        delay: Double = 0,
        spring: Spring? = nil,
        options: Options = []
    ) {
        self.duration = duration
        self.delay = delay
        self.spring = spring
        self.options = options
    }

    public init(arrayLiteral elements: Options...) {
        self.init(options: Options(elements))
    }

    /// Default animation
    public static var `default`: UIKitAnimation {
        .default()
    }

    /// Default animation
    ///
    /// - Parameters:
    ///   - duration: Animation duration in seconds.
    ///   - delay: Animation delay in seconds.
    ///   - options: Animation options mask.
    /// - Returns: `UIKitAnimation`
    public static func `default`(
        _ duration: Double = UIKitAnimation.defaultDuration,
        delay: Double = 0,
        options: Options = [.curveEaseInOut]
    ) -> UIKitAnimation {
        UIKitAnimation(duration: duration, delay: delay, options: options)
    }

    /// Spring animation
    ///
    /// - Parameters:
    ///   - duration: Animation duration in seconds.
    ///   - delay: Animation delay in seconds.
    ///   - damping: The damping ratio for the spring animation as it approaches its quiescent state.
    ///   - initialVelocity: The initial spring velocity.
    ///   - options: Animation options mask.
    /// - Returns: `UIKitAnimation`
    public static func spring(
        _ duration: Double = UIKitAnimation.defaultDuration,
        delay: Double = 0,
        damping: CGFloat = UIKitAnimation.defaultDamping,
        initialVelocity: CGFloat = 0,
        options: Options = []
    ) -> UIKitAnimation {
        UIKitAnimation(
            duration: duration,
            delay: delay,
            spring: Spring(damping: damping, initialVelocity: initialVelocity),
            options: options
        )
    }

    ///Spring animation parameters
    public struct Spring {

        /// The damping ratio for the spring animation as it approaches its quiescent state.
        /// To smoothly decelerate the animation without oscillation, use a value of 1.
        /// Employ a damping ratio closer to zero to increase oscillation.
        public var damping: CGFloat

        /// The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment
        /// A value of 1 corresponds to the total animation distance traversed in one second.
        /// For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
        public var initialVelocity: CGFloat

        public init(damping: CGFloat = UIKitAnimation.defaultDamping, initialVelocity: CGFloat = 0) {
            self.damping = damping
            self.initialVelocity = initialVelocity
        }
    }

    public func delay(_ delay: Double) -> UIKitAnimation {
        var result = self
        result.delay = delay
        return result
    }

    public func options(_ options: Options...) -> UIKitAnimation {
        var result = self
        options.forEach { result.options.insert($0) }
        return result
    }
}

extension UIView {

    /// Animate changes to one or more views using the specified duration, delay, options, and completion handle.
    ///
    /// - Parameters:
    ///   - animation: Animation options.
    ///   - animations: A block object containing the changes to commit to the views. This is where you programmatically change any animatable properties of the views in your view hierarchy. This block takes no parameters and has no return value.
    ///   - completion: A block object to be executed when the animation sequence ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished before the completion handler was called. If the duration of the animation is 0, this block is performed at the beginning of the next run loop cycle.
    public static func animate(
        with animation: UIKitAnimation,
        _ animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if let spring = animation.spring {
            animate(
                withDuration: animation.duration,
                delay: animation.delay,
                usingSpringWithDamping: spring.damping,
                initialSpringVelocity: spring.initialVelocity,
                options: animation.options,
                animations: animations,
                completion: completion
            )
        } else {
            animate(
                withDuration: animation.duration,
                delay: animation.delay,
                options: animation.options,
                animations: animations,
                completion: completion
            )
        }
    }
}
#endif
