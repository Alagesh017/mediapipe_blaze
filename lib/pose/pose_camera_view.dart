import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'movenet_detector.dart';
import 'movenet_to_landmarks.dart';
import 'pose_landmark.dart';
import 'pose_landmark_painter.dart';
import 'pose_landmarker_service.dart';
import 'pose_model_catalog.dart';
import 'pose_angles.dart';
import '../settings/camera_preference.dart';
import '../settings/screen_wake.dart';
import '../yoga/yoga_pose_item.dart';

class PoseCameraView extends StatefulWidget {
  const PoseCameraView({
    super.key,
    required this.pose,
    required this.model,
    this.useFrontCamera = true,
    this.visibilityThreshold = 0.5,
    this.dotRadius = 4,
    this.dotColor = Colors.greenAccent,
  });

  final YogaPoseItem pose;
  final PoseModelOption model;
  final bool useFrontCamera;
  final double visibilityThreshold;
  final double dotRadius;
  final Color dotColor;

  @override
  State<PoseCameraView> createState() => _PoseCameraViewState();
}

class _PoseCameraViewState extends State<PoseCameraView>
    with WidgetsBindingObserver {
  final _mpService = PoseLandmarkerService();
  final _moveNet = MoveNetDetector();
  late final YogaPoseScorer _yogaScorer =
      YogaPoseScorer(widget.pose, visibilityThreshold: widget.visibilityThreshold);

  final _landmarks = ValueNotifier<List<PoseLandmark>>(const []);
  StreamSubscription<List<PoseLandmark>>? _mpSub;
  CameraController? _controller;
  CameraDescription? _description;
  late bool _useFrontCamera = widget.useFrontCamera;
  bool _starting = false;
  bool _switchingCamera = false;
  bool _pipelineReady = false;
  String? _error;

  bool get _usesMediaPipe => widget.model.isMediaPipe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ScreenWake.acquire();
    _moveNet.keypoints.addListener(_syncMoveNetLandmarks);
    _boot();
  }

  void _syncMoveNetLandmarks() {
    if (_usesMediaPipe) return;
    _landmarks.value = landmarksFromMoveNet(
      _moveNet.keypoints.value,
      visibilityThreshold: widget.visibilityThreshold,
    );
  }

  Future<void> _boot() async {
    if (_starting) return;
    _starting = true;
    setState(() {
      _pipelineReady = false;
      _error = null;
    });
    try {
      if (_usesMediaPipe) {
        if (!await _mpService.requestCameraPermission()) {
          if (mounted) setState(() => _error = 'Camera permission denied');
          return;
        }
        _mpSub ??= _mpService.landmarks.listen(
          (l) => _landmarks.value = l,
          onError: (e) => debugPrint('Pose stream error: $e'),
        );
        await _mpService.initialize(widget.model);
        await _mpService.start();
      } else {
        await _moveNet.init(modelAsset: widget.model.assetPath);
      }

      final cams = await availableCameras();
      final lens = _useFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      _description = cams.firstWhere(
        (c) => c.lensDirection == lens,
        orElse: () => cams.first,
      );

      final controller = CameraController(
        _description!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: PoseLandmarkerService.preferredImageFormat,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _pipelineReady = true;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = e.description ?? e.code);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _error = e.message ?? 'Pose model failed to load');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      _starting = false;
      _switchingCamera = false;
    }
  }

  void _onFrame(CameraImage image) {
    final c = _controller;
    final d = _description;
    if (c == null || d == null || !_pipelineReady) return;

    final dev = switch (c.value.deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    final front = d.lensDirection == CameraLensDirection.front;
    var rotation = front
        ? (d.sensorOrientation + dev) % 360
        : (d.sensorOrientation - dev + 360) % 360;

  if (_usesMediaPipe) {
      final isBgra = image.format.group == ImageFormatGroup.bgra8888;
      _mpService.processCameraFrame(
        image,
        rotation: rotation,
        isBgra: isBgra,
      );
    } else {
      _moveNet.process(
        image,
        sensorOrientation: d.sensorOrientation,
        frontCamera: front,
        deviceOrientation: c.value.deviceOrientation,
      );
    }
  }

  Future<void> _releaseCamera() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        if (c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      await c.dispose();
    }
    if (_usesMediaPipe) {
      await _mpService.stop();
    } else {
      _moveNet.clear();
    }
    _landmarks.value = const [];
    if (mounted) setState(() => _pipelineReady = false);
  }

  Future<void> _toggleCamera() async {
    if (_switchingCamera || _starting) return;
    _switchingCamera = true;
    await _releaseCamera();
    _useFrontCamera = !_useFrontCamera;
    await CameraPreference.saveUseFrontCamera(_useFrontCamera);
    if (mounted) setState(() {});
    await _boot();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed) {
      ScreenWake.acquire();
      if (_controller == null && !_starting) {
        _boot();
      }
    }
  }

  @override
  void dispose() {
    ScreenWake.release();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WidgetsBinding.instance.removeObserver(this);
    _moveNet.keypoints.removeListener(_syncMoveNetLandmarks);
    _mpSub?.cancel();
    final c = _controller;
    _controller = null;
    () async {
      try {
        if (c != null && c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      await c?.dispose();
      if (_usesMediaPipe) {
        await _mpService.stop();
        await _mpService.dispose();
      }
      _moveNet.dispose();
    }();
    _landmarks.dispose();
    super.dispose();
  }

  Widget _maybeFlipFront({required bool flip, required Widget child}) {
    if (!flip) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(widget.pose.displayName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !_pipelineReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.pose.displayName),
          foregroundColor: Colors.white,
          backgroundColor: Colors.black54,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Android front preview is selfie-mirrored; flip preview + dots together so
    // the video looks natural and markers still line up with the body.
    final flipFrontPreview = _useFrontCamera && Platform.isAndroid;
    final mirrorDots =
        _useFrontCamera && Platform.isAndroid && !flipFrontPreview;
    final portrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final imageAspect = portrait ? 3 / 4 : 4 / 3;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Text(widget.pose.displayName),
        actions: [
          IconButton(
            tooltip: _useFrontCamera ? 'Use rear camera' : 'Use front camera',
            onPressed: _switchingCamera ? null : _toggleCamera,
            icon: Icon(
              _useFrontCamera
                  ? Icons.camera_rear_outlined
                  : Icons.camera_front_outlined,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox.expand(
            child: ValueListenableBuilder<CameraValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final ps = value.previewSize;
                if (ps == null) {
                  return const ColoredBox(color: Colors.black);
                }
                final landscape =
                    value.deviceOrientation == DeviceOrientation.landscapeLeft ||
                        value.deviceOrientation ==
                            DeviceOrientation.landscapeRight;
                final pw = landscape ? ps.width : ps.height;
                final ph = landscape ? ps.height : ps.width;
                return ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: pw,
                      height: ph,
                      child: _maybeFlipFront(
                        flip: flipFrontPreview,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(controller),
                            IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: PoseLandmarkPainter(
                                    landmarks: _landmarks,
                                    imageAspect: imageAspect,
                                    mirror: mirrorDots,
                                    visibilityThreshold:
                                        widget.visibilityThreshold,
                                    radius: widget.dotRadius,
                                    color: widget.dotColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<List<PoseLandmark>>(
            valueListenable: _landmarks,
            builder: (context, list, _) {
              final result = _yogaScorer.scoreLandmarks(list);
              final accuracy = (result['accuracy'] as int?) ?? 0;
              final status = result['res'] as String? ?? '';
              final lensLabel = _useFrontCamera ? 'Front camera' : 'Rear camera';
              return Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.model.label} · $lensLabel',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black87),
                            ],
                          ),
                        ),
                        Text(
                          '$accuracy%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black87),
                            ],
                          ),
                        ),
                        if (status.isNotEmpty)
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black87),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}