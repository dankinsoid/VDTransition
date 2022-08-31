import SwiftUI

public protocol Transformable {
    
    var frame: CGRect { get nonmutating set }
    var bounds: CGRect { get nonmutating set }
    var anchorPoint: CGPoint { get nonmutating set }
    var affineTransform: CGAffineTransform { get nonmutating set }
    var isLtrDirection: Bool { get }
    func convert(_ frame: CGRect, to: Self?) -> CGRect
}

extension Transformable {
    
    subscript<A, B>(keyPath1: ReferenceWritableKeyPath<Self, A>, keyPath2: ReferenceWritableKeyPath<Self, B>) -> (A, B) {
        get {
            (self[keyPath: keyPath1], self[keyPath: keyPath2])
        }
        nonmutating set {
            self[keyPath: keyPath1] = newValue.0
            self[keyPath: keyPath2] = newValue.1
        }
    }
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
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight
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
