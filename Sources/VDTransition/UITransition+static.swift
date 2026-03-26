import SwiftUI

extension UITransition {

    /// A transition that don't modify the view.
    public static var identity: UITransition {
        UITransition(transitions: [])
    }

    /// Combines all transition, returning a new transition that is the result of all transitions being applied.
    ///
    /// - Parameter transitions: Transitions to be combined.
    /// - Returns: New transition.
    public static func combined(_ transitions: UITransition...) -> UITransition {
        .combined(transitions)
    }

    /// Provides a composite transition that uses a different transition for insertion versus removal.
    public static func asymmetric(insertion: UITransition, removal: UITransition) -> UITransition {
        insertion.filter(\.isInsertion)
            .combined(with: removal.filter { !$0.isInsertion })
    }
    
    /// Creates a transition that interpolates a `VectorArithmetic` property between its identity value and `transformed`.
    ///
    /// - Parameters:
    ///   - keyPath: The property to animate.
    ///   - transformed: The target value at full transformation (progress = 0 for insertion).
    ///   - defaultValue: Optional override for the identity value. When `nil`, uses the captured value.
    /// - Returns: A transition.
    public static func value<T: VectorArithmetic>(_ keyPath: ReferenceWritableKeyPath<Base, T>, _ transformed: T, default defaultValue: T? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            progress.value(identity: defaultValue ?? value, transformed: transformed)
        }
    }
    
    /// Creates a transition that sets a property to a fixed value regardless of progress.
    ///
    /// - Parameters:
    ///   - keyPath: The property to set.
    ///   - value: The constant value to apply.
    /// - Returns: A constant transition.
    public static func constant<T>(_ keyPath: ReferenceWritableKeyPath<Base, T>, _ value: T) -> UITransition {
        UITransition(keyPath) { _, view, _ in
            value
        }
    }
}

#if canImport(UIKit)
extension UITransition {
    
    public static func value(_ keyPath: ReferenceWritableKeyPath<Base, UIColor?>, _ transformed: UIColor, default defaultValue: UIColor? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            value.map {
                progress.value(identity: defaultValue ?? $0, transformed: transformed)
            }
        }
    }
    
    public static func value(_ keyPath: ReferenceWritableKeyPath<Base, UIColor>, _ transformed: UIColor, default defaultValue: UIColor? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            progress.value(identity: defaultValue ?? value, transformed: transformed)
        }
    }
}

extension UITransition where Base == UIView {
    
    /// A transition from transparent to opaque on insertion, and from opaque to transparent on removal.
    public static var opacity: UITransition {
        .value(\.alpha, 0)
    }

    public static func cornerRadius(_ radius: CGFloat) -> UITransition {
        .value(\.layer.cornerRadius, radius)
    }

    public static func backgroundColor(_ color: UIColor, default initial: UIColor? = nil) -> UITransition {
        .value(\.backgroundColor, color, default: initial)
    }
}
#endif

/// `Transformable` transitions operate on `\.affineTransform` and `\.anchorPoint` via the
/// `Transformable` protocol. These are the canonical entry points for transform-based animations.
///
/// **Important:** `scale()`, `rotate()`, `offset()`, and `anchor()` all use `\.affineTransform`
/// (or `\.anchorPoint`) from the `Transformable` protocol. If you create a custom transition
/// on `\.transform` (UIView's native property) or any other alias to the same underlying storage,
/// conflict detection via ``UITransition/matches(_:)`` and ``UITransition/combined(_:)-1tcyc``
/// will **not** recognize them as conflicting, because the `PartialKeyPath` values differ.
/// Always use these factory methods for transform-based transitions.
extension UITransition where Base: Transformable {

    /// Scales the view by `(scale.x, scale.y)` at full transformation.
    ///
    /// - Parameter scale: Target scale factors per axis.
    /// - Returns: A scale transition on `\.affineTransform`.
    public static func scale(_ scale: CGPoint) -> UITransition {
        UITransition(\.affineTransform) { progress, view, transform in
            transform.scaledBy(
                x: progress.value(identity: 1, transformed: scale.x),
                y: progress.value(identity: 1, transformed: scale.y)
            )
        }
    }

    /// Rotates the view by `angle` radians at full transformation.
    ///
    /// - Parameter angle: Rotation angle in radians.
    /// - Returns: A rotation transition on `\.affineTransform`.
    public static func rotate(_ angle: CGFloat) -> UITransition {
        UITransition(\.affineTransform) { progress, view, transform in
            transform.rotated(
                by: progress.value(identity: 0, transformed: angle)
            )
        }
    }
    
    /// Scales the view uniformly by the given factor.
    ///
    /// - Parameter scale: Uniform scale factor (applied to both axes).
    /// - Returns: A scale transition.
    public static func scale(_ scale: CGFloat) -> UITransition {
        .scale(CGPoint(x: scale, y: scale))
    }

    /// Scales the view around a custom anchor point.
    ///
    /// Animates both `\.anchorPoint` and `\.affineTransform` together, compensating
    /// for the anchor shift so the view scales from the specified point.
    ///
    /// - Parameters:
    ///   - scale: Target scale factors per axis.
    ///   - anchor: The unit-space anchor point (e.g. `.topLeading`). Respects RTL layout.
    /// - Returns: A scale transition with custom anchor.
    public static func scale(_ scale: CGPoint, anchor: UnitPoint) -> UITransition {
        UITransition(\.anchorPoint, \.affineTransform) { progress, view, initial -> (CGPoint, CGAffineTransform) in
            let anchor = view.isLtrDirection ? anchor : UnitPoint(x: 1 - anchor.x, y: anchor.y)
            let scaleX = scale.x != 0 ? scale.x : 0.0001
            let scaleY = scale.y != 0 ? scale.y : 0.0001
            let xPadding = 1 / scaleX * (anchor.x - initial.0.x) * view.bounds.width
            let yPadding = 1 / scaleY * (anchor.y - initial.0.y) * view.bounds.height
            
            return (
                CGPoint(
                    x: progress.value(identity: initial.0.x, transformed: anchor.x),
                    y: progress.value(identity: initial.0.y, transformed: anchor.y)
                ),
                initial.1
                    .scaledBy(
                        x: progress.value(identity: 1, transformed: scaleX),
                        y: progress.value(identity: 1, transformed: scaleY)
                    )
                    .translatedBy(
                        x: progress.value(identity: 0, transformed: xPadding),
                        y: progress.value(identity: 0, transformed: yPadding)
                    )
            )
        }
    }

    /// Scales the view uniformly around a custom anchor point.
    ///
    /// - Parameters:
    ///   - scale: Uniform scale factor (defaults to near-zero for a "disappear" effect).
    ///   - anchor: The unit-space anchor point. Respects RTL layout.
    /// - Returns: A scale transition with custom anchor.
    public static func scale(_ scale: CGFloat = 0.0001, anchor: UnitPoint) -> UITransition {
        .scale(CGPoint(x: scale, y: scale), anchor: anchor)
    }

    /// A transition that scales the view to near-zero (effectively disappearing).
    public static var scale: UITransition { .scale(0.0001) }

    /// Animates the view's anchor point to the given unit-space position.
    ///
    /// - Parameter point: Target anchor point. Respects RTL layout.
    /// - Returns: An anchor point transition on `\.anchorPoint`.
    public static func anchor(point: UnitPoint) -> UITransition {
        UITransition(\.anchorPoint) { progress, view, anchor in
            let point = view.isLtrDirection ? point : UnitPoint(x: 1 - point.x, y: point.y)
            return CGPoint(
                x: progress.value(identity: anchor.x, transformed: point.x),
                y: progress.value(identity: anchor.y, transformed: point.y)
            )
        }
    }

    /// Translates the view by the given offset at full transformation.
    ///
    /// - Parameter point: Translation offset in points.
    /// - Returns: An offset transition on `\.affineTransform`.
    public static func offset(_ point: CGPoint) -> UITransition {
        UITransition(\.affineTransform) { progress, view, affineTransform in
            affineTransform.translatedBy(
                x: progress.value(identity: 0, transformed: point.x),
                y: progress.value(identity: 0, transformed: point.y)
            )
        }
    }

    /// Translates the view by the given `x` and `y` offsets.
    ///
    /// - Parameters:
    ///   - x: Horizontal offset in points.
    ///   - y: Vertical offset in points.
    /// - Returns: An offset transition.
    public static func offset(x: CGFloat = 0, y: CGFloat = 0) -> UITransition {
        .offset(CGPoint(x: x, y: y))
    }

    /// Returns a transition that moves the view away, towards the specified edge of the view.
    public static func move(edge: Edge, offset: RelationValue<CGFloat> = .relative(1)) -> UITransition {
        UITransition(\.affineTransform) { progress, view, affineTransform in
            switch (edge, view.isLtrDirection) {
            case (.leading, true), (.trailing, false):
                return affineTransform.translatedBy(
                    x: progress.value(identity: 0, transformed: -offset.value(for: view.frame.width)),
                    y: 0
                )
            case (.leading, false), (.trailing, true):
                return affineTransform.translatedBy(
                    x: progress.value(identity: 0, transformed: offset.value(for: view.frame.width)),
                    y: 0
                )
            case (.top, _):
                return affineTransform.translatedBy(
                    x: 0,
                    y: progress.value(identity: 0, transformed: -offset.value(for: view.frame.height))
                )
            case (.bottom, _):
                return affineTransform.translatedBy(
                    x: 0,
                    y: progress.value(identity: 0, transformed: offset.value(for: view.frame.height))
                )
            }
        }
    }

    /// Creates an asymmetric slide: inserts from one edge, removes towards another.
    ///
    /// - Parameters:
    ///   - insertion: Edge to slide in from.
    ///   - removal: Edge to slide out towards.
    /// - Returns: An asymmetric slide transition.
    public static func slide(insertion: Edge, removal: Edge) -> UITransition {
        .asymmetric(insertion: .move(edge: insertion), removal: .move(edge: removal))
    }

    /// A transition that inserts by moving in from the leading edge, and removes by moving out towards the trailing edge.
    public static var slide: UITransition {
        .slide(insertion: .leading, removal: .trailing)
    }
}
