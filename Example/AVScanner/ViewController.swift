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
        
        view.bringSubviewToFront(cameraButton)
        supportedMetadataObjectTypes = [.qr, .pdf417]
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
        
        guard let url = URL(string: string), UIApplication.shared.canOpenURL(url) else { return }
        self.openSafariViewController(with: url)
    }
    
    
    @objc func viewTapHandler(_ gesture: UITapGestureRecognizer) {
        guard !isSessionRunning else { return }
        startRunningSession()
    }
}

fileprivate extension ViewController {
    func openSafariViewController(with url: URL) {
        let safariView = SFSafariViewController(url: url)
        safariView.modalPresentationStyle = .popover
        present(safariView, animated: true, completion: nil)
    }
}


