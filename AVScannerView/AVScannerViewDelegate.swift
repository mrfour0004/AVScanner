//
//  AVScannerViewDelegate.swift
//  AVScanner
//
//  Created by mrfour on 2019/9/30.
//

import AVFoundation

public protocol AVScannerViewDelegate: AnyObject {
    //func numberOfCapture
    func scannerViewDidFinishConfiguration(_ scannerView: AVScannerView)
    func scannerView(_ scannerView: AVScannerView, didFailConfigurationWithError error: Error)

    func scannerViewDidStartSession(_ scannerView: AVScannerView)
    func scannerView(_ scannerView: AVScannerView, didFailStartingSessionWithError error: Error)
    func scannerViewDidStopSession(_ scannerView: AVScannerView)

    func scannerView(_ scannerView: AVScannerView, didCapture metadataObject: AVMetadataMachineReadableCodeObject)
}
