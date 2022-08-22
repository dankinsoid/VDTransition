import SwiftUI

extension UITransition where Base: Transformable & Hashable {

    /// A transition from one view to another.
    public static func transform(to targetView: Base) -> UITransition {
        UITransition(\Base[matching: targetView]) { progress, view, initial in
            let (sourceScale, sourceOffset) = transform(progress: progress, initial: initial)
            view.affineTransform = initial.sourceTransform
                .translatedBy(x: sourceOffset.x, y: sourceOffset.y)
                .scaledBy(x: sourceScale.width, y: sourceScale.height)
        }
    }
    
    private static func transform(progress: Progress, initial: Matching) -> (scale: CGSize, offset: CGPoint) {
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

private extension Transformable {

    subscript(matching view: Self) -> Matching {
        get {
            Matching(
                sourceTransform: affineTransform,
                targetTransform: view.affineTransform,
                sourceRect: convert(bounds, to: nil),
                targetRect: view.convert(view.bounds, to: nil)
            )
        }
        nonmutating set {
            affineTransform = newValue.sourceTransform
            view.affineTransform = newValue.targetTransform
        }
    }
}

private struct Matching {
    
    var sourceTransform: CGAffineTransform
    var targetTransform: CGAffineTransform
    var sourceRect: CGRect
    var targetRect: CGRect
}

private extension CGFloat {
    
    var notZero: CGFloat { self == 0 ? 0.0001 : self }
}
