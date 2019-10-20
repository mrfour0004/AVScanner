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

    open var metadataObjectTypes: [AVMetadataObject.ObjectType] {
        get { return sessionController.metadataObjectTypes }
        set { sessionController.metadataObjectTypes = newValue }
    }
    
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
}

// MARK: - Session Control

extension AVScannerView {
    public func initSession() {
        session = sessionController.session
        videoPreviewLayer.videoGravity = .resizeAspectFill

        sessionController.initSession(withMetadataObjectsDelegate: self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown, let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
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

    public func stopSession() {
        sessionController.stop {
            DispatchQueue.main.async {
                self.delegate?.scannerViewDidStopSession(self)
            }
        }
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
