//
//  AVScannerViewController.swift
//  AVScanner
//
//  Created by mrfour on 16/12/2016.
//

import UIKit
import AVFoundation

open class AVScannerViewController: UIViewController {
    
    // MARK: - Open Properties
    
    open var barcodeHandler: ((_ codeObject: AVMetadataMachineReadableCodeObject) -> Void)?
    
    // MARK: - Device configuration
    
    open var supportedMetadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr] {
        didSet {
            guard setupResult == .success else { return }
            sessionQueue.async {
                print("did set supportedMetadataObjectTypes")
                self.session.beginConfiguration()
                self.captureMetaDataOutput.metadataObjectTypes = self.supportedMetadataObjectTypes
                self.session.commitConfiguration()
            }
        }
    }
    
    // MARK: - Session management
    
    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    fileprivate let previewView = AVScannerPreviewView()
    fileprivate let session = AVCaptureSession()
    fileprivate let sessionQueue = DispatchQueue(label: "session queue")
    
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate var setupResult: SessionSetupResult = .success
    
    public var isSessionRunning = false
    
    
    // MARK: - Meta data output
    
    public let captureMetaDataOutput = AVCaptureMetadataOutput()
    
    // MARK: - Focus view
    
    public let focusView = AVScannerFocusView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    
    // MARK: - View controller life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        
        previewView.session = session
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startRunningSession()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopRunningSession()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        focusView.layer.anchorPoint = CGPoint.zero
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if isSessionRunning {
            focusView.startAnimation()
        }
        
        let deviceOrientation = UIDevice.current.orientation
        
        guard let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection ,
            let newVideoOrientation = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else { return }
        
        videoPreviewLayerConnection.videoOrientation = newVideoOrientation
    }
    
    open override var shouldAutorotate: Bool {
        return isSessionRunning
    }
    
    // MARK: - Prepare view
    
    private func prepareView() {
        preparePreviewView()
        prepareFocusView()
    }
    
    private func preparePreviewView() {
        view.addSubview(previewView)
        
        previewView.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: previewView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: previewView, attribute: .centerY, multiplier: 1, constant: 0)
        let heightConstraint  = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: previewView, attribute: .height, multiplier: 1, constant: 0)
        let widthConstraint   = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: previewView, attribute: .width, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([centerXConstraint, centerYConstraint, heightConstraint, widthConstraint])
    }
    
    private func prepareFocusView() {
        view.addSubview(focusView)
        view.bringSubview(toFront: focusView)
    }
    
    // MARK: - Configure
    
    private func configureSession() {
        guard setupResult == .success else { return }
        
        print("start configure session")
        
        session.beginConfiguration()
        
        do {
            let defaultVideoDevice = AVCaptureDevice.device(withPosition: .back) ?? AVCaptureDevice.device(withPosition: .front)
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                        if let videoOrientation = statusBarOrientation.videoOrientation {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                setupResult = .configurationFailed
                session.commitConfiguration()
            }
            
        } catch let error {
            print(error.localizedDescription)
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.addOutput(captureMetaDataOutput)
        captureMetaDataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        captureMetaDataOutput.metadataObjectTypes = supportedMetadataObjectTypes
        
        session.commitConfiguration()
    }
    
    // MARK: - Session control
    
    public func startRunningSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                DispatchQueue.main.async {
                    self.focusView.startAnimation()
                }
            case .notAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                        }
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    public func stopRunningSession() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    /// Flip the camera between front and back camera 
    public func flip() {
        guard session.inputs.count > 0 else { return }
        
        sessionQueue.async {
            self.flipCamera()
        }
    }
    
    fileprivate func flipCamera() {
        DispatchQueue.main.async {
            self.focusView.stopAnimation()
            
            let blurView = UIVisualEffectView()
            blurView.frame = self.previewView.frame
            blurView.tag = 100
            blurView.effect = UIBlurEffect(style: .light)
            self.previewView.addSubview(blurView)
            
            UIView.transition(with: self.previewView, duration: 0.4, options: [.transitionFlipFromLeft, .curveEaseInOut], animations: nil, completion: { _ in
                UIView.transition(with: self.previewView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
                    blurView.removeFromSuperview()
                }, completion: { _ in
                    self.focusView.startAnimation()
                })
            })
        }
        
        session.beginConfiguration()
        
        guard let currentCaptureInput = session.inputs.first as? AVCaptureDeviceInput else {
            session.commitConfiguration()
            return
        }
        
        session.removeInput(currentCaptureInput)
        let newPosition: AVCaptureDevice.Position = currentCaptureInput.device.position == .front ? .back : .front
        
        do {
            let newCaptureDeviceInput = try AVCaptureDeviceInput(device: AVCaptureDevice.device(withPosition: newPosition)!)
            session.addInput(newCaptureDeviceInput)
        } catch let error as NSError {
            print(error.localizedDescription)
            session.commitConfiguration()
        }
        
        session.commitConfiguration()
        
//        DispatchQueue.main.async { 
//            if let blurView = self.previewView.viewWithTag(100) {
//                UIView.transition(with: self.previewView, duration: 0.1, options: [.transitionCrossDissolve, .curveEaseInOut], animations: {
//                    blurView.removeFromSuperview()
//                }, completion: nil)
////                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: {
////                    blurView.removeFromSuperview()
////                }, completion: nil)
//            }
//        }
    }
    
    // MARK: - KVO and Notification
    
}

// MARK: - AV Capture

extension AVScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            guard let barcodeObject = metadataObjects.first, let transformedMetadataObject = self.previewView.videoPreviewLayer.transformedMetadataObject(for: barcodeObject) as? AVMetadataMachineReadableCodeObject else { return }
            self.sessionQueue.async {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                DispatchQueue.main.async {
                    self.focusView.transform(to: transformedMetadataObject.corners) {
                        self.barcodeHandler?(transformedMetadataObject)
                    }
                }
            }
        }
    }
}

// MARK: - Device orientation

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}

// MARK: - Interface orientation

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

extension AVCaptureDevice {
    class func device(withPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            if position == .back {
                return AVCaptureDevice.default(.builtInDuoCamera, for: .video, position: .back) ??  AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            } else {
                return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            }
        }
        
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

























