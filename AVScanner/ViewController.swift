//
//  ViewController.swift
//  AVScanner
//
//  Created by mrfour on 16/12/2016.
//  Copyright © 2016 mrfour. All rights reserved.
//

import UIKit

class ViewController: AVScannerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareBarcodeHandler()
        prepareViewTapHandler()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func barcodeDidCaptured(barcodeString: String) {
        print("barcode did captured: \(barcodeString)")
    }
    
    func viewTapHandler(_ gesture: UITapGestureRecognizer) {
        guard !isSessionRunning else { return }
        startRunningSession()
    }
}

