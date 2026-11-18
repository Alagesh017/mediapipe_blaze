import Foundation
import CoreMedia
import CoreVideo
import UIKit
import MediaPipeTasksVision

final class PoseEngine: NSObject, PoseLandmarkerLiveStreamDelegate {
    static let shared = PoseEngine()

    private let lock = NSLock()
    private var landmarker: PoseLandmarker?
    private var loadedModelPath: String?
    private var inFlight = false
    private var lastTimestampMs = -1
    private(set) var running = false

    var onLandmarks: (([Double]) -> Void)?

    func initialize(modelPath: String) throws {
        lock.lock(); defer { lock.unlock() }
        if landmarker != nil, loadedModelPath == modelPath { return }
        landmarker = nil
        loadedModelPath = modelPath
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.shouldOutputSegmentationMasks = false
        options.poseLandmarkerLiveStreamDelegate = self
        landmarker = try PoseLandmarker(options: options)
    }

    func start() {
        lock.lock(); running = true; inFlight = false; lock.unlock()
    }

    func stop() {
        lock.lock(); running = false; inFlight = false; lock.unlock()
        onLandmarks?([])
    }

    func dispose() {
        lock.lock(); running = false; landmarker = nil; loadedModelPath = nil; lock.unlock()
    }

    func process(bgra: Data, width: Int, height: Int, rotation: Int, timestampMs: Int) {
        lock.lock()
        guard running, !inFlight, let lm = landmarker else { lock.unlock(); return }
        if timestampMs <= lastTimestampMs { lock.unlock(); return }
        lastTimestampMs = timestampMs
        inFlight = true
        lock.unlock()

        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ] as CFDictionary
        CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA, attrs, &pixelBuffer
        )
        guard let buffer = pixelBuffer else {
            lock.lock(); inFlight = false; lock.unlock()
            return
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let destStride = CVPixelBufferGetBytesPerRow(buffer)
        let srcStride = width * 4
        guard let base = CVPixelBufferGetBaseAddress(buffer) else {
            lock.lock(); inFlight = false; lock.unlock()
            return
        }
        let dest = base.assumingMemoryBound(to: UInt8.self)
        for row in 0..<height {
            let srcOff = row * srcStride
            let dstOff = row * destStride
            let copyLen = min(srcStride, bgra.count - srcOff)
            if copyLen <= 0 { break }
            bgra.copyBytes(to: dest.advanced(by: dstOff), from: srcOff..<(srcOff + copyLen))
        }

        do {
            let orientation: UIImage.Orientation = rotation == 0 ? .up
                : (rotation == 90 ? .right : (rotation == 180 ? .down : .left))
            let image = try MPImage(pixelBuffer: buffer, orientation: orientation)
            try lm.detectAsync(image: image, timestampInMilliseconds: timestampMs)
        } catch {
            lock.lock(); inFlight = false; lock.unlock()
            NSLog("PoseLandmarker BGRA error: \(error)")
        }
    }

    /// Called on the camera video queue. Buffers are already upright.
    func process(sampleBuffer: CMSampleBuffer) {
        lock.lock()
        guard running, !inFlight, let lm = landmarker else { lock.unlock(); return }
        let ts = Int(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000)
        if ts <= lastTimestampMs { lock.unlock(); return }
        lastTimestampMs = ts
        inFlight = true
        lock.unlock()

        do {
            let image = try MPImage(sampleBuffer: sampleBuffer, orientation: .up)
            try lm.detectAsync(image: image, timestampInMilliseconds: ts)
        } catch {
            lock.lock(); inFlight = false; lock.unlock()
            NSLog("PoseLandmarker detect error: \(error)")
        }
    }

    // MARK: PoseLandmarkerLiveStreamDelegate
    func poseLandmarker(
        _ poseLandmarker: PoseLandmarker,
        didFinishDetection result: PoseLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        lock.lock(); inFlight = false; let isRunning = running; lock.unlock()
        guard isRunning else { return }
        if let error = error { NSLog("PoseLandmarker error: \(error)"); return }

        guard let pose = result?.landmarks.first, !pose.isEmpty else {
            onLandmarks?([]); return
        }
        var out = [Double]()
        out.reserveCapacity(pose.count * 5)
        for l in pose {
            out.append(Double(l.x))
            out.append(Double(l.y))
            out.append(Double(l.z))
            out.append(l.visibility?.doubleValue ?? 0)
            out.append(l.presence?.doubleValue ?? 0)
        }
        onLandmarks?(out)
    }
}
