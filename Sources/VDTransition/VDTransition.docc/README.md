# VDTransition

- <doc:/Tutorial>

## Description

VDTransition provides easy way to describe view transitions.

## Example
```swift 
view1.set(hidden: true, transition: .opacity)
view2.set(hidden: true, transition: .move(edge: .trailing))
view3.removeFromSuperview(transition: [.move(edge: .trailing), .opacity])
```
