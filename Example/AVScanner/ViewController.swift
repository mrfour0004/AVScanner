//
//  ViewController.swift
//  AVScanner
//
//  Created by mrfour on 12/26/2016.
//  Copyright (c) 2016 mrfour. All rights reserved.
//

import AVFoundation
import AVScanner
import UIKit

class ViewController: AVScannerViewController {
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func cameraChange(_ sender: Any) {
        scannerView.flip()
    }
    
    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.bringSubviewToFront(cameraButton)
        scannerView.supportedMetadataObjectTypes = [.qr, .pdf417]
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

override func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error) {
    guard let saError = error as? AVScannerError else { return }
    switch saError {
    case .videoNotAuthorized:
        print("The user didn't authorize to access the camera")
    case .configurationFailed:
        print("This device somehow can't capture videos.")
    }
}

}

