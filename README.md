# AVScanner

[![CI Status](http://img.shields.io/travis/mrfour/AVScanner.svg?style=flat)](https://travis-ci.org/mrfour/AVScanner)
[![Version](https://img.shields.io/cocoapods/v/AVScanner.svg?style=flat)](http://cocoapods.org/pods/AVScanner)
[![License](https://img.shields.io/cocoapods/l/AVScanner.svg?style=flat)](http://cocoapods.org/pods/AVScanner)
[![Platform](https://img.shields.io/cocoapods/p/AVScanner.svg?style=flat)](http://cocoapods.org/pods/AVScanner)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

AVScanner is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AVScanner"
```

## Reguirement

- iOS 8.0+
- Xcode 9.0
- Swift 4.0

## Usage

In your UIViewController class, import the following framework

``` swift
import AVScanner
import AVFoundation
```

Setup the `barcodeHandler:`, and bring any views you set up in storyboard or xib to front.

``` swift 
override viewDidLoad() {
    super.viewDidLoad()

    // Set up `supportedMetadataObjectTypes` if needed, 
    // it only support `AVMetadataObjectTypeQRCode` by default.
    supportedMetadataObjectTypes = [.qr, .pdf417]    

    // If you have set up any views in storyboard or xib, remember to bring them to front.
    view.bringSubview(toFront: myView)

    // If you use `self` in this block will result in a retain cycle, 
    // it's your duty to break it through `[unowned self]`.
    barcodeHandler = { barcodeObj in
        loggingPrint("captured barcode: \(barcodeObj.stringValue!)")
    }
}

// You can also flip the camera between front and back through invoking `flip()`
@IBAction func buttonClick(_ sender: Any) {
    guard isSessionRunning else { return }
    flip()
}
```

### Attention

When `isSessionRunning` is `false`, the autorotate will be disabled. It usually happens when it captures a barcode. However, if the viewController is owned by an `UINavigationController` or `UITabBarController`, you have to override `sholdAutoRotate` in the class of `UINavigationController` or `UITabBarController` by yourself.

For more detail, please refer to the exemple project and feel free to contact me.

## License

AVScanner is available under the MIT license. See the LICENSE file for more info.
