//
//  AVCaptureSessionController.swift
//  AVScanner
//
//  Created by mrfour on 2019/9/30.
//

import Foundation
import AVFoundation

public typealias AVSessionSetupResult = Result<Void, Error>
public typealias AVSessionStartResult = Result<Void, Error>

public class AVCaptureSessionController: NSObject {

    static let kAVCaptureSessionQueue = "AVCaptureSessionQueue"

    // MARK: - Properties

    let session: AVCaptureSession
    let sessionQueue: DispatchQueue = DispatchQueue(label: kAVCaptureSessionQueue)
    var metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr] {
        didSet {
            sessionQueue.async { [metadataObjectTypes] in
                guard case .success = self.setupResult else { return }
                self.session.beginConfiguration()
                self.captureMetadataOutput.metadataObjectTypes = metadataObjectTypes
                self.session.commitConfiguration()
            }
        }
    }

    var isSessionRunning = false
    private var setupResult: AVSessionSetupResult = .success
    private var deviceInput: AVCaptureDeviceInput!
    private let captureMetadataOutput: AVCaptureMetadataOutput

    private lazy var videoDeviceDiscoverySession: AVCaptureDevice.DiscoverySession = {
        var preferredDevices: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(iOS 11.1, *) {
            preferredDevices.append(.builtInTrueDepthCamera)
        }
        if #available(iOS 10.2, *) {
            preferredDevices.append(.builtInDualCamera)
        } else {
            preferredDevices.append(.builtInDuoCamera)
        }
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredDevices,
            mediaType: .video,
            position: .unspecified
        )
    }()

    // MARK: - Initializers

    public init(
        session: AVCaptureSession = .init(),
        captureMetaDataOutput: AVCaptureMetadataOutput = .init()
    ) {
        self.session = session
        self.captureMetadataOutput = captureMetaDataOutput
    }

    // MARK: - Change Camera

    func flipCamera(_ completion: (() -> Void)? = nil) {
        guard !session.inputs.isEmpty else { return }

        sessionQueue.async { [session] in
            let currentDevice = self.deviceInput.device
            let currentPosition = currentDevice.position

            let preferredPosition = self.preferredPosition(forFlippingCameraFrom: currentPosition)
            let preferredDeviceType = self.preferredDeviceType(forFlippingCameraFrom: currentPosition)

            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice?

            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType}) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }

            guard let videoDevice = newVideoDevice else { return }

            do {
                let deviceInput = try AVCaptureDeviceInput(device: videoDevice)
                session.beginConfiguration()
                defer {
                    session.commitConfiguration()
                    completion?()
                }

                session.removeInput(self.deviceInput)

                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                    self.deviceInput = deviceInput
                } else {
                    session.addInput(self.deviceInput)
                }
            } catch {
                print("[AVScanner] Error occurred while creating video device input: \(error)")
            }
        }
    }

    private func preferredPosition(
        forFlippingCameraFrom currentPosition: AVCaptureDevice.Position
    ) -> AVCaptureDevice.Position {
        return currentPosition == .back ? .front : .back
    }

    private func preferredDeviceType(
        forFlippingCameraFrom currentPosition: AVCaptureDevice.Position
    ) -> AVCaptureDevice.DeviceType {
        switch currentPosition {
        case .unspecified, .front:
            if #available(iOS 10.2, *) {
                return .builtInDualCamera
            } else {
                return .builtInDuoCamera
            }
        case .back:
            if #available(iOS 11.1, *) {
                return .builtInTrueDepthCamera
            } else if #available(iOS 10.2, *) {
                return .builtInDualCamera
            } else {
                return .builtInDuoCamera
            }
        @unknown default:
            print("Unknown capture position. Defaulting to back, dual-camera.")
            if #available(iOS 10.2, *) {
                return .builtInDualCamera
            } else {
                return .builtInDuoCamera
            }
        }
    }

    // MARK: - Session Control

    public func initSession(
        withMetadataObjectsDelegate metadataObjectsDelegate: AVCaptureMetadataOutputObjectsDelegate,
        completion: @escaping (AVSessionSetupResult) -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.setupResult = .failure(AVScannerError.videoNotAuthorized)
                }
                self.sessionQueue.resume()
            }
        default:
            setupResult = .failure(AVScannerError.videoNotAuthorized)
        }

        sessionQueue.async {
            self.configureSession(withMetadataObjectsDelegate: metadataObjectsDelegate, completion: completion)
        }
    }

    private func configureSession(
        withMetadataObjectsDelegate metadataObjectsDelegate: AVCaptureMetadataOutputObjectsDelegate,
        completion: @escaping (AVSessionSetupResult) -> Void
    ) {
        guard case .success = setupResult else {
            return completion(setupResult)
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(position: .back) ?? AVCaptureDevice.default(position: .front) else {
            setupResult = .failure(AVScannerError.configurationFailed)
            return
        }

        if let deviceInput = try? AVCaptureDeviceInput(device: device), session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
            self.deviceInput = deviceInput
            setupResult = .success
        } else {
            setupResult = .failure(AVScannerError.configurationFailed)
        }

        session.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(metadataObjectsDelegate, queue: sessionQueue)
        captureMetadataOutput.metadataObjectTypes = metadataObjectTypes
        completion(setupResult)
    }

    /// Starts/resumes the session
    func start(_ completion: @escaping (AVSessionStartResult) -> Void) {
        sessionQueue.async { [session] in
            guard !self.isSessionRunning else { return }
            switch self.setupResult {
            case .success:
                session.startRunning()
                self.isSessionRunning = true
                completion(.success)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Stops the session.
    func stop(_ completion: (() -> Void)? = nil) {
        sessionQueue.async {
            guard case .success = self.setupResult else { return }
            self.session.stopRunning()
            self.isSessionRunning = false
            completion?()
        }
    }

}
