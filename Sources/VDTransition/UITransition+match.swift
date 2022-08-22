#if canImport(UIKit)
import UIKit

extension UITransition where Base == UIView {

    /// A transition from one view to another.
    public static func turn(to targetView: UIView) -> UITransition {
        UITransition(\.[matching: targetView]) { progress, view, initial in
            let (sourceScale, sourceOffset) = transform(progress: progress, initial: initial)
            view.transform = initial.sourceTransform
                .translatedBy(x: sourceOffset.x, y: sourceOffset.y)
                .scaledBy(x: sourceScale.width, y: sourceScale.height)

            let (targetScale, targetOffset) = transform(progress: progress.reversed, initial: initial)
            targetView.transform = initial.targetTransform
                .translatedBy(x: -targetOffset.x, y: -targetOffset.y)
                .scaledBy(x: 1 / targetScale.width.notZero, y: 1 / targetScale.height.notZero)
        }
    }
    
    private static func transform(progress: Progress, initial: UIView.Matching) -> (scale: CGSize, offset: CGPoint) {
        let scale = CGSize(
            width: progress.value(
                identity: 1,
                transformed: initial.targetRect.width / initial.sourceRect.width.notZero
            ),
            height: progress.value(
                identity: 1,
                transformed: initial.targetRect.height / initial.sourceRect.height.notZero
            )
        )
        
        let offset = CGPoint(
            x: progress.value(
                identity: 0,
                transformed: initial.targetRect.midX - initial.sourceRect.midX
            ),
            y: progress.value(
                identity: 0,
                transformed: initial.targetRect.midY - initial.sourceRect.midY
            )
        )
        
        return (scale, offset)
    }
}

private extension UIView {

    subscript(matching view: UIView) -> Matching {
        get {
            Matching(
                sourceTransform: transform,
                targetTransform: view.transform,
                sourceRect: convert(bounds, to: window),
                targetRect: view.convert(view.bounds, to: view.window)
            )
        }
        set {
            transform = newValue.sourceTransform
            view.transform = newValue.targetTransform
        }
    }

    struct Matching {
        
        var sourceTransform: CGAffineTransform
        var targetTransform: CGAffineTransform
        var sourceRect: CGRect
        var targetRect: CGRect
    }
}

private extension CGFloat {
    
    var notZero: CGFloat { self == 0 ? 0.0001 : self }
}
#endif
