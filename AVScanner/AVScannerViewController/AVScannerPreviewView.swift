//
//  AVScannerPreviewView.swift
//  AVScanner
//
//  Created by mrfour on 16/12/2016.
//  Copyright © 2016 mrfour. All rights reserved.
//

import UIKit
import AVFoundation

class AVScannerPreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var previewView: AVScannerPreviewView!
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: - UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
