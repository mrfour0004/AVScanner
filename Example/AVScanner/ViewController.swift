//
//  ViewController.swift
//  AVScanner
//
//  Created by mrfour on 12/26/2016.
//  Copyright (c) 2016 mrfour. All rights reserved.
//

import UIKit
import AVScanner

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
    lazy var barcodeDidCaptured: (_ barcodeString: String) -> Void = { barcodeString in
        print("barcode did captured: \(barcodeString)")
    }
    
    func viewTapHandler(_ gesture: UITapGestureRecognizer) {
        guard !isSessionRunning else { return }
        startRunningSession()
    }
}


