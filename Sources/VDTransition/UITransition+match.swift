import SwiftUI

extension UITransition where Base: Transformable & AnyObject {

    /// A transition from one view to another.
    public static func transform(to targetView: Base) -> UITransition {
        UITransition(TransformToModifier(targetView)) { progress, view, initial in
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

private struct TransformToModifier<Root: Transformable & AnyObject>: TransitionModifier {
    
    public typealias Value = Matching
    
    weak var target: Root?
    
    init(_ target: Root?) {
        self.target = target
    }
    
    func matches(other: TransformToModifier<Root>) -> Bool {
        other.target === target
    }
    
    func set(value: Matching, to root: Root) {
        root.affineTransform = value.sourceTransform
    }
    
    func value(for root: Root) -> Matching {
        Matching(
            sourceTransform: root.affineTransform,
            targetTransform: target?.affineTransform ?? root.affineTransform,
            sourceRect: root.convert(root.bounds, to: nil),
            targetRect: target?.convert(target?.bounds ?? .zero, to: nil) ?? root.convert(root.bounds, to: nil)
        )
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
