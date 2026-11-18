import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'movenet_worker.dart';
import 'pose_keypoint.dart';

class MoveNetDetector {
  String _modelAsset = 'assets/modal/movenet_lightning.tflite';

  /// Empty list => nobody detected.
  final ValueNotifier<List<PoseKeypoint>> keypoints =
      ValueNotifier<List<PoseKeypoint>>(const []);

  /// Keypoints below this score are not drawn / not counted.
  double scoreThreshold = 0.3;

  /// If fewer than this many keypoints pass the threshold, we say "no person".
  int minKeypoints = 5;

  /// Debug helper: add 90/180/270 if the dots come out rotated on a device.
  int rotationFixDegrees = 0;

  MoveNetWorker? _worker;
  bool _busy = false;
  bool _disposed = false;
  double _msSum = 0;
  int _msCount = 0;

  Future<void> init({String? modelAsset}) async {
    if (modelAsset != null) _modelAsset = modelAsset;
    final data = await rootBundle.load(_modelAsset);
    final bytes = data.buffer.asUint8List();
    final worker = await MoveNetWorker.start(bytes);
    if (_disposed) {
      worker.dispose();
      return;
    }
    worker.onResult = _onResult;
    _worker = worker;
  }

  /// Call this from CameraController.startImageStream. Drops frames while busy.
  void process(
    CameraImage image, {
    required int sensorOrientation,
    required bool frontCamera,
    required DeviceOrientation deviceOrientation,
  }) {
    final worker = _worker;
    if (worker == null || _busy || _disposed) return;
    _busy = true;

    final dev = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    var rotation = frontCamera
        ? (sensorOrientation + dev) % 360
        : (sensorOrientation - dev + 360) % 360;
    rotation = (rotation + rotationFixDegrees) % 360;

    final isBgra = image.format.group == ImageFormatGroup.bgra8888;
    worker.send(FrameMessage(
      width: image.width,
      height: image.height,
      rotation: rotation,
      isBgra: isBgra,
      planes: [
        for (final p in image.planes) TransferableTypedData.fromList([p.bytes])
      ],
      rowStrides: [for (final p in image.planes) p.bytesPerRow],
      pixelStrides: [for (final p in image.planes) p.bytesPerPixel ?? 1],
    ));
  }

  void clear() {
    if (keypoints.value.isNotEmpty) keypoints.value = const [];
  }

  void _onResult(Float32List r) {
    _busy = false;
    if (_disposed) return;

    _msSum += r[51];
    if (++_msCount == 60) {
      debugPrint('MoveNet avg inference: ${(_msSum / _msCount).toStringAsFixed(1)} ms');
      _msSum = 0;
      _msCount = 0;
    }

    final list = <PoseKeypoint>[];
    var good = 0;
    for (var k = 0; k < kKeypointCount; k++) {
      final score = r[k * 3 + 2];
      if (score >= scoreThreshold) good++;
      list.add(PoseKeypoint(
        index: k,
        y: r[k * 3].clamp(0.0, 1.0),
        x: r[k * 3 + 1].clamp(0.0, 1.0),
        score: score,
      ));
    }
    if (good < minKeypoints) {
      clear();
    } else {
      keypoints.value = List.unmodifiable(list);
    }
  }

  void dispose() {
    _disposed = true;
    _worker?.dispose();
    _worker = null;
    keypoints.dispose();
  }
}
