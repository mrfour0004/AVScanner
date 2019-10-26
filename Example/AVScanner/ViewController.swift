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
        scannerView.flip()
    }
    
    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViewTapHandler()
        
        view.bringSubviewToFront(cameraButton)
        scannerView.supportedMetadataObjectTypes = [.qr, .pdf417]
    }
    
    deinit {
        print("deinit")
    }
    
    // MARK: - Prepare viewDidLoad
    
    private func prepareViewTapHandler() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapHandler))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - AVScanner view handler
    
    // Be careful with retain cycle
    lazy var barcodeDidCaptured: (_ codeObject: AVMetadataMachineReadableCodeObject) -> Void = { [unowned self] codeObject in
        let string = codeObject.stringValue!
        
        guard let url = URL(string: string), UIApplication.shared.canOpenURL(url) else { return }
        self.openSafariViewController(with: url)
    }
    
    
    @objc func viewTapHandler(_ gesture: UITapGestureRecognizer) {
        scannerView.startSession()
    }

    // MARK: - Scanner view delegate

    override func scannerView(_ scannerView: AVScannerView, didCapture metadataObject: AVMetadataMachineReadableCodeObject) {
        let barcodeString = metadataObject.stringValue

        let alertController = UIAlertController(title: nil, message: barcodeString, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.scannerView.startSession()
        }))
        
        present(alertController, animated: true, completion: nil)
    }

}

fileprivate extension ViewController {
    func openSafariViewController(with url: URL) {
        let safariView = SFSafariViewController(url: url)
        safariView.modalPresentationStyle = .popover
        present(safariView, animated: true, completion: nil)
    }
}


