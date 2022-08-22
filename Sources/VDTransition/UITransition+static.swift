import SwiftUI

extension UITransition {

    /// A transition that don't modify the view.
    public static var identity: UITransition {
        UITransition(transitions: [], modifiers: [], initialStates: [])
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
    
    public static func value<T: VectorArithmetic>(_ keyPath: ReferenceWritableKeyPath<Base, T>, _ transformed: T, default defaultValue: T? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            view[keyPath: keyPath] = progress.value(identity: defaultValue ?? value, transformed: transformed)
        }
    }
    
    public static func constant<T>(_ keyPath: ReferenceWritableKeyPath<Base, T>, _ value: T) -> UITransition {
        UITransition(keyPath) { _, view, _ in
            view[keyPath: keyPath] = value
        }
    }
}

#if canImport(UIKit)
extension UITransition {
    
    public static func value(_ keyPath: ReferenceWritableKeyPath<Base, UIColor?>, _ transformed: UIColor, default defaultValue: UIColor? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            view[keyPath: keyPath] = value.map {
                progress.value(identity: defaultValue ?? $0, transformed: transformed)
            }
        }
    }
    
    public static func value(_ keyPath: ReferenceWritableKeyPath<Base, UIColor>, _ transformed: UIColor, default defaultValue: UIColor? = nil) -> UITransition {
        UITransition(keyPath) { progress, view, value in
            view[keyPath: keyPath] = progress.value(identity: defaultValue ?? value, transformed: transformed)
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

    public static func backgroundColor(_ color: UIColor) -> UITransition {
        .value(\.backgroundColor, color)
    }
}
#endif

extension UITransition where Base: Transformable {

    public static func scale(_ scale: CGPoint) -> UITransition {
        UITransition(\.affineTransform) { progress, view, transform in
            view.affineTransform = transform.scaledBy(
                x: progress.value(identity: 1, transformed: scale.x),
                y: progress.value(identity: 1, transformed: scale.y)
            )
        }
    }

    public static func scale(_ scale: CGFloat) -> UITransition {
        .scale(CGPoint(x: scale, y: scale))
    }

    public static func scale(_ scale: CGPoint, anchor: CGPoint) -> UITransition {
        UITransition(\.affineTransform) { progress, view, transform in
            let scaleX = scale.x != 0 ? scale.x : 0.0001
            let scaleY = scale.y != 0 ? scale.y : 0.0001
            let xPadding = 1 / scaleX * (anchor.x - view.anchorPoint.x) * view.bounds.width
            let yPadding = 1 / scaleY * (anchor.y - view.anchorPoint.y) * view.bounds.height

            view.affineTransform = transform
                .scaledBy(
                    x: progress.value(identity: 1, transformed: scaleX),
                    y: progress.value(identity: 1, transformed: scaleY)
                )
                .translatedBy(
                    x: progress.value(identity: 0, transformed: xPadding),
                    y: progress.value(identity: 0, transformed: yPadding)
                )
        }
    }

    public static func scale(_ scale: CGFloat = 0.0001, anchor: CGPoint) -> UITransition {
        .scale(CGPoint(x: scale, y: scale), anchor: anchor)
    }

    public static var scale: UITransition { .scale(0.0001) }

    public static func anchor(point: CGPoint) -> UITransition {
        UITransition(\.anchorPoint) { progress, view, anchor in
            let anchorPoint = CGPoint(
                x: progress.value(identity: anchor.x, transformed: point.x),
                y: progress.value(identity: anchor.y, transformed: point.y)
            )
            view.anchorPoint = anchorPoint
        }
    }

    public static func offset(_ point: CGPoint) -> UITransition {
        UITransition(\.affineTransform) { progress, view, affineTransform in
            view.affineTransform = affineTransform.translatedBy(
                x: progress.value(identity: 0, transformed: point.x),
                y: progress.value(identity: 0, transformed: point.y)
            )
        }
    }

    public static func offset(x: CGFloat = 0, y: CGFloat = 0) -> UITransition {
        .offset(CGPoint(x: x, y: y))
    }

    /// Returns a transition that moves the view away, towards the specified edge of the view.
    public static func move(edge: Edge, offset: RelationValue<CGFloat> = .relative(1)) -> UITransition {
        UITransition(\.affineTransform) { progress, view, affineTransform in
            switch (edge, view.isLtrDirection) {
            case (.leading, true), (.trailing, false):
                view.affineTransform = affineTransform.translatedBy(
                    x: progress.value(identity: 0, transformed: -offset.value(for: view.frame.width)),
                    y: 0
                )
            case (.leading, false), (.trailing, true):
                view.affineTransform = affineTransform.translatedBy(
                    x: progress.value(identity: 0, transformed: offset.value(for: view.frame.width)),
                    y: 0
                )
            case (.top, _):
                view.affineTransform = affineTransform.translatedBy(
                    x: 0,
                    y: progress.value(identity: 0, transformed: -offset.value(for: view.frame.height))
                )
            case (.bottom, _):
                view.affineTransform = affineTransform.translatedBy(
                    x: 0,
                    y: progress.value(identity: 0, transformed: offset.value(for: view.frame.height))
                )
            }
        }
    }

    public static func slide(insertion: Edge, removal: Edge) -> UITransition {
        .asymmetric(insertion: .move(edge: insertion), removal: .move(edge: removal))
    }

    /// A transition that inserts by moving in from the leading edge, and removes by moving out towards the trailing edge.
    public static var slide: UITransition {
        .slide(insertion: .leading, removal: .trailing)
    }
}
