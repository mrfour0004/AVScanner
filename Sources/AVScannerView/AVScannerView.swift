//
//  AVScannerView.swift
//  AVScanner
//
//  Created by mrfour on 2019/9/30.
//

import AVFoundation
import UIKit

public class AVScannerView: AVScannerPreviewView {

    // MARK: - Properties

    /// A boolean value represents whether the capture session is running.
    public var isSessionRunning: Bool {
        return sessionController.isSessionRunning
    }

    public var videoOrientation: AVCaptureVideoOrientation? {
        get { videoPreviewLayer.connection?.videoOrientation }
        set {
            guard let newValue = newValue else { return }
            videoPreviewLayer.connection?.videoOrientation = newValue
            if isSessionRunning {
                focusView.startAnimation()
            }
        }
    }

    /// An array of strings identifying the types of metadata objects which can be recoganized.
    ///
    /// Set this property to any types of metadata you want to support. The default value of this property is
    /// `[.qr]`.
    public var supportedMetadataObjectTypes: [AVMetadataObject.ObjectType] {
        get { sessionController.metadataObjectTypes }
        set { sessionController.metadataObjectTypes = newValue }
    }

    /// The object acts as the delegate of the scanner view.
    open weak var delegate: AVScannerViewDelegate?

    private let sessionController: AVCaptureSessionController
    private var windowOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return window?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

    // MARK: - Focus view

    private let focusView = AVScannerFocusView()

    // MARK: - Initializers

    public init(controller: AVCaptureSessionController = .init()) {
        self.sessionController = controller
        super.init(frame: .zero)
        prepareView()
    }

    public required init?(coder: NSCoder) {
        self.sessionController = AVCaptureSessionController()
        super.init(coder: coder)
        prepareView()
    }

    // MARK: - View lifecycle

    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

// MARK: - Camera Control

extension AVScannerView {
    public func flip() {
        sessionController.stop()
        
        let blurEffectView = UIVisualEffectView()
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)

        UIView.transition(with: self, duration: 0.4, options: [.transitionFlipFromLeft, .curveEaseInOut], animations: {
            blurEffectView.effect = UIBlurEffect(style: .light)
        }, completion: { _ in
            self.sessionController.flipCamera { [unowned sessionController = self.sessionController] in
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.2) { self.alpha = 0 }
                    sessionController.start { _ in
                        DispatchQueue.main.async {
                            UIView.animate(withDuration: 0.2, animations: {
                                self.alpha = 1
                                blurEffectView.effect = nil
                            }, completion: { _ in
                                blurEffectView.removeFromSuperview()
                            })
                        }
                    }
                }
            }
        })
    }
}

// MARK: - Session Control

extension AVScannerView {
    /// Initializes the capture session.
    ///
    /// You need to call this function to initialize the capture session before you calling `startSession()`.
    public func initSession() {
        session = sessionController.session
        videoPreviewLayer.videoGravity = .resizeAspectFill

        sessionController.initSession(withMetadataObjectsDelegate: self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown,
                        let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                        initialVideoOrientation = videoOrientation
                    }
                    self.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                    self.delegate?.scannerViewDidFinishConfiguration(self)
                case .failure(let error):
                    self.delegate?.scannerView(self, didFailConfigurationWithError: error)
                }
            }
        }
    }

    /// Starts running the capture session.
    ///
    /// If the session has started, calling this function does nothing.
    public func startSession() {
        sessionController.start { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.focusView.startAnimation()
                    self.delegate?.scannerViewDidStartSession(self)
                case .failure(let error):
                    self.delegate?.scannerView(self, didFailStartingSessionWithError: error)
                }
            }
        }
    }

    /// Stops the capture session if the capture session is running.
    public func stopSession() {
        sessionController.stop()
    }
}

// MARK: - Prepare view

private extension AVScannerView {
    func prepareView() {
        prepareFocusView()
    }

    func prepareFocusView() {
        addSubview(focusView)
    }
}


// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension AVScannerView: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            guard
                let barcodeObject = metadataObjects.first,
                let transformedMetadataObject = self.videoPreviewLayer.transformedMetadataObject(for: barcodeObject) as? AVMetadataMachineReadableCodeObject
                else { return }

            self.sessionController.stop { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.focusView.transform(to: transformedMetadataObject.__corners) {
                        self.delegate?.scannerView(self, didCapture: transformedMetadataObject)
                    }
                }
            }
        }
    }
}
