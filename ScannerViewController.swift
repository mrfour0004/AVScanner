//
//  ScannerViewController.swift
//  AVScanner
//
//  Created by mrfour on 2019/10/6.
//

import UIKit
import AVFoundation

open class ScannerViewController: UIViewController {

    // MARK: - Properties

    // MARK: - Scanner View

    public private(set) lazy var scannerView = AVScannerView(controller: .init())

    // MARK: - Initializer

    // MARK: - View Lifecycle

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
    }

    // MARK: - View controller rotation

    open override var shouldAutorotate: Bool {
        return false
    }
}

// MARK: - Prepare Views

private extension ScannerViewController {
    func prepareView() {
        prepareScannerView()
    }

    func prepareScannerView() {
        view.addSubview(scannerView)
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.leading, .top, .centerX, .centerY]
        let constraints = attributes.map {
            NSLayoutConstraint(item: scannerView, attribute: $0, relatedBy: .equal, toItem: view, attribute: $0, multiplier: 1, constant: 0)
        }
        NSLayoutConstraint.activate(constraints)

        scannerView.delegate = self
    }
}


// MARK: - Scanner view delegate

extension ScannerViewController: AVScannerViewDelegate {
    public func scannerViewDidFinishConfiguration(_ scannerView: AVScannerView) {
        loggingPrint("")
    }

    public func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error) {
        loggingPrint("")
    }

    public func scannerViewDidStartSession(_ scannerView: AVScannerView) {
        loggingPrint("")
    }

    public func scannerView(_ scannerView: AVScannerView, didFailStartingSessionWithError error: Error) {
        loggingPrint("")
    }

    public func scannerViewDidStopSession(_ scannerView: AVScannerView) {
        loggingPrint("")
    }

    public func scannerView(_ scannerView: AVScannerView, didCapture metadataObject: AVMetadataMachineReadableCodeObject) {
        loggingPrint(metadataObject.stringValue ?? "")
    }
}
