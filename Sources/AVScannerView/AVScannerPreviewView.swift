//
//  AVScannerPreviewView.swift
//  AVScanner
//
//  Created by mrfour on 16/12/2016.
//

import AVFoundation
import UIKit

public class AVScannerPreviewView: UIView {
    // MARK: - Properties
    
    public var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }
}

extension AVScannerPreviewView {
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    internal var screenshotImage: UIImage? {
        let targetLayer = layer
        
        UIGraphicsBeginImageContextWithOptions(targetLayer.frame.size, true, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        targetLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
}
