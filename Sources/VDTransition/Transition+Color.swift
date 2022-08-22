#if canImport(UIKit)
import SwiftUI

extension UIColor {
    
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

extension Progress {
    
    public func value(identity: UIColor, transformed: UIColor) -> UIColor {
        let iRGBA = identity.rgba
        let tRGBA = transformed.rgba
        let identityAnimatable = AnimatablePair(
            AnimatablePair(iRGBA.red, iRGBA.green),
            AnimatablePair(iRGBA.blue, iRGBA.alpha)
        )
        let transformedAnimatable = AnimatablePair(
            AnimatablePair(tRGBA.red, tRGBA.green),
            AnimatablePair(tRGBA.blue, tRGBA.alpha)
        )
        var result = identityAnimatable - transformedAnimatable
        result.scale(by: progress)
        result += transformedAnimatable
        return UIColor(
            red: result.first.first,
            green: result.first.second,
            blue: result.second.first,
            alpha: result.second.second
        )
    }
}
#endif
