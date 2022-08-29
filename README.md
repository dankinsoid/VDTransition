# VDTransition

[![CI Status](https://img.shields.io/travis/dankinsoid/VDTransition.svg?style=flat)](https://travis-ci.org/dankinsoid/VDTransition)
[![Version](https://img.shields.io/cocoapods/v/VDTransition.svg?style=flat)](https://cocoapods.org/pods/VDTransition)
[![License](https://img.shields.io/cocoapods/l/VDTransition.svg?style=flat)](https://cocoapods.org/pods/VDTransition)
[![Platform](https://img.shields.io/cocoapods/p/VDTransition.svg?style=flat)](https://cocoapods.org/pods/VDTransition)

## Description

VDTransition provides easy way to describe view transitions.

- [Documantaion](https://dankinsoid.github.io/VDTransition/documentation/vdtransition)
- [Tutorial](https://dankinsoid.github.io/VDTransition/tutorials/vdtransition/tutorial)

## Example
```swift 
view1.set(hidden: true, transition: .opacity)
view2.set(hidden: true, transition: .move(edge: .trailing))
view3.removeFromSuperview(transition: [.move(edge: .trailing), .opacity])
```

## Installation
1.  [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:
```ruby
pod 'VDTransition'
```
and run `pod update` from the podfile directory first.

2. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.
```swift
// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/VDTransition.git", from: "1.11.0")
  ],
  targets: [
    .target(name: "SomeProject", dependencies: ["VDTransition"])
  ]
)
```
```ruby
$ swift build
```

## Author

dankinsoid, voidilov@gmail.com

## License

VDTransition is available under the MIT license. See the LICENSE file for more info.

