import SwiftUI

extension UITransition where Base: Transformable & AnyObject {

    /// A transition that morphs this view toward `targetView` by interpolating
    /// scale and position.
    ///
    /// Source `affineTransform` and `globalFrame` are captured at `beforeTransition` time.
    /// Target frame and transform are read each frame so the target can move in parallel.
    ///
    /// ```swift
    /// var transition: UIViewTransition = .transform(to: otherView)
    /// transition.beforeTransition(view: sourceView)
    /// transition.update(progress: .removal(0.5), view: sourceView)
    /// ```
    ///
    /// - Parameter targetView: The view to morph toward. Held weakly.
    /// - Returns: A transition that writes to `\.affineTransform`.
    // @ai-generated(guided)
    public static func transform(to targetView: Base) -> UITransition {
        UITransition(\.affineTransform, \.globalFrame) { [weak target = targetView] progress, view, initial -> (CGAffineTransform, CGRect) in
            let (sourceTransform, sourceRect) = initial
            guard let target else { return (sourceTransform, sourceRect) }

            let targetRect = target.convert(target.bounds, to: nil)

            let scale = CGSize(
                width: progress.value(
                    identity: 1,
                    transformed: targetRect.width / sourceRect.width.notZero
                ),
                height: progress.value(
                    identity: 1,
                    transformed: targetRect.height / sourceRect.height.notZero
                )
            )

            let offset = CGPoint(
                x: progress.value(
                    identity: 0,
                    transformed: targetRect.midX - sourceRect.midX
                ),
                y: progress.value(
                    identity: 0,
                    transformed: targetRect.midY - sourceRect.midY
                )
            )

            let newTransform = sourceTransform
                .translatedBy(x: offset.x, y: offset.y)
                .scaledBy(x: scale.width, y: scale.height)

            // globalFrame: return sourceRect unchanged — the empty setter makes this a no-op,
            // but we need the value in the dictionary for the two-keyPath init contract.
            return (newTransform, sourceRect)
        }
    }
}

private extension Transformable {

    /// Global frame in window coordinates. Read-only in practice:
    /// the setter is intentionally empty so this can be used as a `ReferenceWritableKeyPath`
    /// for capture-only properties (captured at `beforeTransition`, never written back).
    var globalFrame: CGRect {
        get { convert(bounds, to: nil) }
        nonmutating set {}
    }
}

private extension CGFloat {

    var notZero: CGFloat { self == 0 ? 0.0001 : self }
}
