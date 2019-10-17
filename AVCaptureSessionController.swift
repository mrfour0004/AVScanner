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

    // MARK: - Initializers

    public init(
        session: AVCaptureSession = .init(),
        captureMetaDataOutput: AVCaptureMetadataOutput = .init()
    ) {
        self.session = session
        self.captureMetadataOutput = captureMetaDataOutput
    }

    // MARK: - Sessoion Control

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
        guard case .success = setupResult else { return }

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
    func stop(_ completion: @escaping () -> Void) {
        sessionQueue.async {
            guard case .success = self.setupResult else { return }
            self.session.stopRunning()
            self.isSessionRunning = false
            completion()
        }
    }

}