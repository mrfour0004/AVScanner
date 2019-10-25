//
//  RootViewController.swift
//  AVScanner_Example
//
//  Created by mrfour on 2019/10/7.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AVScanner
import AVFoundation

class RootViewController: ScannerViewController {

    @IBAction func flip(_ sender: Any) {
        scannerView.flip()
    }
}
