//
//  AVCaptureDevice+.swift
//  AVScanner
//
//  Created by Liang, KaiChih on 2018/4/3.
//

import AVFoundation

// MARK: - AVCaptureDevice

extension AVCaptureDevice {
    static func `default`(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}
