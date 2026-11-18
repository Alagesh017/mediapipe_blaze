import Flutter
import UIKit
import AVFoundation

public class PoseLandmarkerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PoseLandmarkerPlugin()

        let method = FlutterMethodChannel(name: "educer/pose",
                                          binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: method)

        let events = FlutterEventChannel(name: "educer/pose/events",
                                         binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)

        registrar.register(PoseCameraViewFactory(), withId: "educer/pose_camera_view")

        PoseEngine.shared.onLandmarks = { [weak instance] values in
            instance?.emit(values)
        }
    }

    private func emit(_ values: [Double]) {
        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        let typed = FlutterStandardTypedData(float64: data)
        DispatchQueue.main.async { [weak self] in self?.eventSink?(typed) }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestCameraPermission":
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: result(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async { result(granted) }
                }
            default: result(false)
            }

        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let asset = args["modelAsset"] as? String else {
                result(FlutterError(code: "ARG", message: "modelAsset missing", details: nil)); return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let key = FlutterDartProject.lookupKey(forAsset: asset)
                guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "MODEL_NOT_FOUND",
                                            message: "Model not found in bundle: \(asset)", details: nil))
                    }
                    return
                }
                do {
                    try PoseEngine.shared.initialize(modelPath: path)
                    DispatchQueue.main.async { result(nil) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "INIT_FAILED",
                                            message: error.localizedDescription, details: nil))
                    }
                }
            }

        case "start":   PoseEngine.shared.start();   result(nil)
        case "stop":    PoseEngine.shared.stop();    result(nil)
        case "dispose": PoseEngine.shared.dispose(); result(nil)

        case "processCameraFrame":
            guard let args = call.arguments as? [String: Any],
                  let width = args["width"] as? Int,
                  let height = args["height"] as? Int,
                  let rotation = args["rotation"] as? Int,
                  let ts = args["timestampMs"] as? Int else {
                result(nil)
                return
            }
            let format = args["format"] as? String ?? ""
            if format == "bgra", let data = args["bgra"] as? FlutterStandardTypedData {
                PoseEngine.shared.process(
                    bgra: data.data,
                    width: width,
                    height: height,
                    rotation: rotation,
                    timestampMs: ts
                )
            }
            result(nil)

        default: result(FlutterMethodNotImplemented)
        }
    }

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
}
