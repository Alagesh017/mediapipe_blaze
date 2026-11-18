import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'keypoint_painter.dart';
import 'movenet_detector.dart';

/// Self-contained camera screen. It owns the ONE CameraController, so there is
/// never a second camera session.
///
/// Already have your own camera screen? You only need:
///   1. detector.init()
///   2. controller.startImageStream((img) => detector.process(img, ...))
///   3. stack KeypointPainter on top of your CameraPreview (same size/aspect)
///   4. stopImageStream() + detector.dispose() when leaving.
class PoseCameraScreen extends StatefulWidget {
  const PoseCameraScreen({super.key, this.useFrontCamera = true});
  final bool useFrontCamera;

  @override
  State<PoseCameraScreen> createState() => _PoseCameraScreenState();
}

class _PoseCameraScreenState extends State<PoseCameraScreen>
    with WidgetsBindingObserver {
  final _detector = MoveNetDetector();
  CameraController? _controller;
  CameraDescription? _description;
  bool _starting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    if (_starting) return;
    _starting = true;
    try {
      final cams = await availableCameras();
      final lens = widget.useFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      _description = cams.firstWhere(
        (c) => c.lensDirection == lens,
        orElse: () => cams.first,
      );

      await _detector.init(); // loads model into background isolate (once)

      final controller = CameraController(
        _description!,
        ResolutionPreset.medium, // 640x480 is plenty for a 192x192 model
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = e.description ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      _starting = false;
    }
  }

  void _onFrame(CameraImage image) {
    final c = _controller;
    final d = _description;
    if (c == null || d == null) return;
    _detector.process(
      image,
      sensorOrientation: d.sensorOrientation,
      frontCamera: d.lensDirection == CameraLensDirection.front,
      deviceOrientation: c.value.deviceOrientation,
    );
  }

  Future<void> _releaseCamera() async {
    final c = _controller;
    _controller = null;
    _detector.clear();
    if (c == null) return;
    if (mounted) setState(() {});
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _boot();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    () async {
      try {
        if (c != null && c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      await c?.dispose();
    }();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.white))),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final front = _description!.lensDirection == CameraLensDirection.front;
    // Android front frames arrive un-mirrored (preview is mirrored) => mirror dots.
    // iOS front frames are already mirrored => don't mirror again.
    // If dots are flipped on iOS, change this to `front`.
    final mirrorDots = front && Platform.isAndroid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: ValueListenableBuilder<CameraValue>(
          valueListenable: c,
          builder: (_, value, __) {
            final landscape =
                value.deviceOrientation == DeviceOrientation.landscapeLeft ||
                    value.deviceOrientation == DeviceOrientation.landscapeRight;
            final ps = value.previewSize!; // sensor-style size (w > h)
            final pw = landscape ? ps.width : ps.height;
            final ph = landscape ? ps.height : ps.width;
            return ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: pw,
                  height: ph,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(c),
                      IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: KeypointPainter(
                              keypoints: _detector.keypoints,
                              mirror: mirrorDots,
                              scoreThreshold: _detector.scoreThreshold,
                              radius: 8, // in preview pixels (scaled with the preview)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
