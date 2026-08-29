import AVFoundation
import Combine
import CoreImage
import CoreMedia
import UIKit

/// Owns the camera session and exposes a frame-by-frame stream for Vision.
/// The session is deliberately kept independent from SwiftUI so it can be
/// reused by both the machine scanner and the workout tracker.
final class CameraManager: NSObject, ObservableObject {
    @Published private(set) var permissionGranted = false
    @Published private(set) var isRunning = false
    @Published var errorMessage: String?

    let session = AVCaptureSession()

    /// Called on the camera frame queue. Consumers should do their own
    /// throttling if they perform expensive work with each frame.
    var onFrame: ((CMSampleBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "neon-gym.camera.session")
    private let frameQueue = DispatchQueue(label: "neon-gym.camera.frames")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let ciContext = CIContext()
    private var latestPixelBuffer: CVPixelBuffer?
    private var configuredPosition: AVCaptureDevice.Position?

    override init() {
        super.init()
        checkPermission()
    }

    func start(position: AVCaptureDevice.Position = .front) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            configureAndStart(position: position)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
                guard granted else { return }
                self?.configureAndStart(position: position)
            }
        default:
            DispatchQueue.main.async { [weak self] in
                self?.permissionGranted = false
                self?.errorMessage = "Camera access is disabled. Enable it in Settings to continue."
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    /// Returns the most recent camera frame as a JPEG for the machine scanner.
    /// This keeps the scanner independent from a particular networking client.
    func captureLatestFrameJPEGData() -> Data? {
        frameQueue.sync { [self] in
            guard let latestPixelBuffer else { return nil }
            let image = CIImage(cvPixelBuffer: latestPixelBuffer)
            guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
                return nil
            }
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86)
        }
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        default:
            permissionGranted = false
        }
    }

    private func configureAndStart(position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.configuredPosition != position {
                let wasRunning = self.session.isRunning
                if wasRunning {
                    self.session.stopRunning()
                }

                guard self.configureSession(position: position) else {
                    DispatchQueue.main.async {
                        self.isRunning = false
                    }
                    return
                }

                if wasRunning {
                    self.session.startRunning()
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                self.isRunning = self.session.isRunning
            }
        }
    }

    @discardableResult
    private func configureSession(position: AVCaptureDevice.Position) -> Bool {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: position) else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "No compatible camera is available on this device."
            }
            return false
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(input) else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "The camera input could not be added."
                }
                return false
            }
            session.addInput(input)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Unable to start the camera: \(error.localizedDescription)"
            }
            return false
        }

        if session.outputs.isEmpty {
            guard session.canAddOutput(videoOutput) else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "The camera video output could not be added."
                }
                return false
            }
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        }

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                // Keep Vision's input in the camera's native orientation.
                // The preview and skeleton overlay apply selfie mirroring together.
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }

        configuredPosition = position
        return true
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        latestPixelBuffer = pixelBuffer
        onFrame?(sampleBuffer)
    }
}
