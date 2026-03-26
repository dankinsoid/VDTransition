import SwiftUI

/// A view that exposes transform-related properties for animation.
///
/// `Transformable` provides a unified interface for `UIView` and `NSView` properties
/// used by the library's transform transitions (`.scale()`, `.rotate()`, `.offset()`, `.anchor()`).
///
/// **KeyPath identity caveat:** The properties declared here (`affineTransform`, `anchorPoint`)
/// are computed wrappers over the platform's native storage (e.g. `UIView.transform`,
/// `CALayer.anchorPoint`). Their `PartialKeyPath` values are **distinct** from the native
/// keyPaths. The library's factory methods consistently use `Transformable` keyPaths,
/// so conflict detection works correctly as long as you use those methods rather than
/// accessing `\.transform` or `\.layer.anchorPoint` directly.
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
