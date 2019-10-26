//
//  ScannerViewController.swift
//  AVScanner
//
//  Created by mrfour on 2019/10/6.
//

import UIKit
import AVFoundation

open class AVScannerViewController: UIViewController, AVScannerViewDelegate {

    // MARK: - Scanner View

    public private(set) lazy var scannerView = AVScannerView(controller: .init())

    // MARK: - View lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        scannerView.initSession()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scannerView.startSession()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let orientaton = UIDevice.current.orientation

        guard
            let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: orientaton),
            orientaton.isPortrait || orientaton.isLandscape
        else { return }

        scannerView.videoOrientation = newVideoOrientation
    }

    // MARK: - Scanner view delegate

    open func scannerViewDidFinishConfiguration(_ scannerView: AVScannerView) {

    }

    open func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error) {

    }

    open func scannerViewDidStartSession(_ scannerView: AVScannerView) {

    }

    open func scannerView(_ scannerView: AVScannerView, didFailStartingSessionWithError error: Error) {

    }

    open func scannerViewDidStopSession(_ scannerView: AVScannerView) {

    }

    open func scannerView(_ scannerView: AVScannerView, didCapture metadataObject: AVMetadataMachineReadableCodeObject) {

    }
}

// MARK: - Prepare views

private extension AVScannerViewController {
    func prepareView() {
        prepareScannerView()
    }

    func prepareScannerView() {
        // Prevent scanner view covering any views set in storyboard or xib.
        view.insertSubview(scannerView, at: 0)
        scannerView.frame = view.bounds
        scannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scannerView.delegate = self
    }
}

