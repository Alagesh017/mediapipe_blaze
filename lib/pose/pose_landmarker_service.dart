import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'pose_landmark.dart';
import 'pose_model_catalog.dart';

class PoseLandmarkerService {
  static const MethodChannel _method = MethodChannel('educer/pose');
  static const EventChannel _events = EventChannel('educer/pose/events');

  Stream<List<PoseLandmark>> get landmarks =>
      _events.receiveBroadcastStream().map(PoseLandmark.decode);

  bool _frameBusy = false;

  Future<bool> requestCameraPermission() async =>
      (await _method.invokeMethod<bool>('requestCameraPermission')) ?? false;

  Future<void> initialize(PoseModelOption model) => _method.invokeMethod(
        'initialize',
        {
          'modelAsset': model.assetPath,
          if (model.androidBundledName != null)
            'androidModelAsset': model.androidBundledName,
        },
      );

  Future<void> start() => _method.invokeMethod('start');
  Future<void> stop() => _method.invokeMethod('stop');
  Future<void> dispose() => _method.invokeMethod('dispose');

  void processCameraFrame(
    CameraImage image, {
    required int rotation,
    required bool isBgra,
  }) {
    if (_frameBusy) return;
    _frameBusy = true;

    final Map<String, dynamic> args = {
      'width': image.width,
      'height': image.height,
      'rotation': rotation,
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
    };

    if (isBgra && image.planes.length == 1) {
      args['format'] = 'bgra';
      args['bgra'] = image.planes[0].bytes;
    } else if (image.planes.length >= 3) {
      args['format'] = 'yuv420';
      args['y'] = image.planes[0].bytes;
      args['u'] = image.planes[1].bytes;
      args['v'] = image.planes[2].bytes;
      args['yRowStride'] = image.planes[0].bytesPerRow;
      args['uRowStride'] = image.planes[1].bytesPerRow;
      args['vRowStride'] = image.planes[2].bytesPerRow;
      args['yPixelStride'] = image.planes[0].bytesPerPixel ?? 1;
      args['uPixelStride'] = image.planes[1].bytesPerPixel ?? 1;
      args['vPixelStride'] = image.planes[2].bytesPerPixel ?? 1;
    } else {
      _frameBusy = false;
      return;
    }

    _method.invokeMethod('processCameraFrame', args).whenComplete(() {
      _frameBusy = false;
    });
  }

  static ImageFormatGroup get preferredImageFormat =>
      Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888;
}