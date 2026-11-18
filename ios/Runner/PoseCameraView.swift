import Flutter
import UIKit
import AVFoundation

final class PoseCameraViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        let front = ((args as? [String: Any])?["lens"] as? String) == "front"
        return PoseCameraView(frame: frame, front: front)
    }
}

final class PoseCameraView: NSObject, FlutterPlatformView {
    private let container: PreviewContainer

    init(frame: CGRect, front: Bool) {
        container = PreviewContainer(frame: frame)
        super.init()
        container.configure(front: front)
    }

    func view() -> UIView { container }
    deinit { container.teardown() }
}

final class PreviewContainer: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "educer.pose.session")
    private let videoQueue = DispatchQueue(label: "educer.pose.video")

    func configure(front: Bool) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .vga640x480

            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video,
                    position: front ? .front : .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(input)

            self.output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.output.alwaysDiscardsLateVideoFrames = true
            self.output.setSampleBufferDelegate(self, queue: self.videoQueue)
            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async { self.updateOrientation() }
        }
    }

    func teardown() {
        sessionQueue.async { [session, output] in
            output.setSampleBufferDelegate(nil, queue: nil)
            if session.isRunning { session.stopRunning() }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateOrientation()
    }

    private func updateOrientation() {
        guard let scene = window?.windowScene else { return }
        let vo = AVCaptureVideoOrientation(rawValue: scene.interfaceOrientation.rawValue) ?? .portrait
        if let c = previewLayer.connection, c.isVideoOrientationSupported {
            c.videoOrientation = vo
        }
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let c = self.output.connection(with: .video) else { return }
            if c.isVideoOrientationSupported { c.videoOrientation = vo }
            // Keep frames UNmirrored; Flutter mirrors the dots for the front camera.
            if c.isVideoMirroringSupported {
                c.automaticallyAdjustsVideoMirroring = false
                c.isVideoMirrored = false
            }
        }
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        PoseEngine.shared.process(sampleBuffer: sampleBuffer)
    }
}
