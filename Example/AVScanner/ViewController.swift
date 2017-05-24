//
//  ViewController.swift
//  AVScanner
//
//  Created by mrfour on 12/26/2016.
//  Copyright (c) 2016 mrfour. All rights reserved.
//

import UIKit
import AVFoundation
import AVScanner
import SafariServices

class ViewController: AVScannerViewController {
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func cameraChange(_ sender: Any) {
        guard isSessionRunning else { return }
        flip()
    }
    
    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareBarcodeHandler()
        prepareViewTapHandler()
        
        view.bringSubview(toFront: cameraButton)
        supportedMetadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypePDF417Code]
    }
    
    deinit {
        print("deinit")
    }
    
    // MARK: - Prepare viewDidLoad
    
    private func prepareBarcodeHandler () {
        barcodeHandler = barcodeDidCaptured
    }
    
    private func prepareViewTapHandler() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapHandler))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MAKR: - AVScanner view handler
    
    // Be careful with retain cycle
    lazy var barcodeDidCaptured: (_ codeObject: AVMetadataMachineReadableCodeObject) -> Void = { [unowned self] codeObject in
        let string = codeObject.stringValue!
        
        if #available(iOS 9.0, *), let url = URL(string: string), UIApplication.shared.canOpenURL(url) {
            self.openSafariViewController(with: url)
        } else {
            let alertViewController = UIAlertController(title: "Code String", message: string, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
                alertViewController.dismiss(animated: true)
                self.startRunningSession()
            })
            alertViewController.addAction(action)
            self.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    func viewTapHandler(_ gesture: UITapGestureRecognizer) {
        guard !isSessionRunning else { return }
        startRunningSession()
    }
}

extension ViewController {
    @available(iOS 9.0, *)
    fileprivate func openSafariViewController(with url: URL) {
        let safariView = SFSafariViewController(url: url)
        safariView.modalPresentationStyle = .popover
        present(safariView, animated: true, completion: nil)
    }
}


