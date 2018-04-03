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
    
    open var supportedMetadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr] {
        didSet {
            sessionQueue.async {
                guard self.setupResult == .success else { return }
                self.session.beginConfiguration()
                self.captureMetaDataOutput.metadataObjectTypes = self.supportedMetadataObjectTypes
                self.session.commitConfiguration()
            }
        }
    }
    
    open var alertTitle: String? = nil
    open var alertErrorTitle: String? = nil
    open var alertConfirmTitle = NSLocalizedString("OK", comment: "")
    open var alertSettingsTitle = NSLocalizedString("Settings", comment: "")
    open var cameraPermissionRequestMessage = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
    open var configurSessionFailureMessage = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
    
    // MARK: - Session management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let previewView = AVScannerPreviewView()
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "AVScannerSessionQueue")
    
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var setupResult: SessionSetupResult = .success
    
    public var isSessionRunning = false
    
    // MARK: - Meta data output
    
    public let captureMetaDataOutput = AVCaptureMetadataOutput()
    
    // MARK: - Focus view
    
    public let focusView = AVScannerFocusView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    
    // MARK: - Life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
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
}

// MARK: - Public functions

extension AVScannerViewController {
    
    // MARK: Session control
    
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
                    self.requestCameraPermission()
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: self.alertErrorTitle, message: self.configurSessionFailureMessage, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: self.alertConfirmTitle, style: .cancel, handler: nil))
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
    
    // MARK: Camera control
    
    /// Flip the camera between front and back camera
    public func flip() {
        guard !session.inputs.isEmpty else { return }
        
        sessionQueue.async {
            self.flipCamera()
        }
    }
}

// MARK: - Private functions

fileprivate extension AVScannerViewController {
    func flipCamera() {
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
            let newCaptureDeviceInput = try AVCaptureDeviceInput(device: AVCaptureDevice.default(position: newPosition)!)
            session.addInput(newCaptureDeviceInput)
        } catch let error as NSError {
            loggingPrint(error.localizedDescription)
            session.commitConfiguration()
        }
        
        session.commitConfiguration()
    }
    
    func requestCameraPermission() {
        let message = cameraPermissionRequestMessage
        let alertController = UIAlertController(title: self.alertTitle, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: self.alertConfirmTitle, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: self.alertSettingsTitle, style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Prepare view

fileprivate extension AVScannerViewController {
    func prepareView() {
        prepareSession()
        preparePreviewView()
        prepareFocusView()
    }
    
    private func preparePreviewView() {
        view.addSubview(previewView)
        
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: previewView.topAnchor),
            view.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: previewView.bottomAnchor)
        ])
    }
    
    private func prepareFocusView() {
        view.addSubview(focusView)
        view.bringSubview(toFront: focusView)
    }
    
    // MARK: - Configure
    
    private func prepareSession() {
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
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
    
    private func configureSession() {
        guard setupResult == .success else { return }
        
        loggingPrint("start configure session")
        
        session.beginConfiguration()
        
        guard let defaultVideoDevice = AVCaptureDevice.default(position: .back) ?? AVCaptureDevice.default(position: .front) else {
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
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
            loggingPrint(error.localizedDescription)
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.addOutput(captureMetaDataOutput)
        captureMetaDataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        captureMetaDataOutput.metadataObjectTypes = supportedMetadataObjectTypes
        
        session.commitConfiguration()
    }
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
                    self.focusView.transform(to: transformedMetadataObject.__corners) {
                        self.barcodeHandler?(transformedMetadataObject)
                    }
                }
            }
        }
    }
}

