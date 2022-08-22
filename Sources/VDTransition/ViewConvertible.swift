import SwiftUI

public protocol ViewConvertible {
    #if canImport(UIKit)
    var asView: UIView { get }
    #endif
    #if canImport(Cocoa)
    var asView: NSView { get }
    #endif
}

public protocol Transformable {
    
    var frame: CGRect { get nonmutating set }
    var bounds: CGRect { get nonmutating set }
    var anchorPoint: CGPoint { get nonmutating set }
    var affineTransform: CGAffineTransform { get nonmutating set }
    var isLtrDirection: Bool { get }
    func convert(_ frame: CGRect, to: Self?) -> CGRect
}

#if canImport(UIKit)
extension UIView: Transformable {
    
    public var affineTransform: CGAffineTransform {
        get { transform }
        set { transform = newValue }
    }
    
    public var anchorPoint: CGPoint {
        get { layer.anchorPoint }
        set { layer.anchorPoint = newValue }
    }
    
    public var isLtrDirection: Bool {
        effectiveUserInterfaceLayoutDirection == .leftToRight
    }
}
#endif

#if canImport(Cocoa)
extension NSView: Transformable {
    
    public var anchorPoint: CGPoint {
        get { layer?.anchorPoint ?? .zero }
        set { layer?.anchorPoint = newValue }
    }
    
    public var affineTransform: CGAffineTransform {
        get {
            layer?.affineTransform() ?? .identity
        }
        set {
            layer?.setAffineTransform(newValue)
        }
    }
    
    public var isLtrDirection: Bool {
        userInterfaceLayoutDirection == .leftToRight
    }
}
#endif
