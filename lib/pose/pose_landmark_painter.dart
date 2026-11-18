import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pose_landmark.dart';

/// Draws dots only. [imageAspect] = width/height of the UPRIGHT camera image
/// (3/4 portrait, 4/3 landscape). Matches "cover" scaling of the native preview.
class PoseLandmarkPainter extends CustomPainter {
  PoseLandmarkPainter({
    required this.landmarks,
    required this.imageAspect,
    this.mirror = false,
    this.visibilityThreshold = 0.5,
    this.radius = 4.0,
    this.color = Colors.greenAccent,
  }) : super(repaint: landmarks);

  final ValueListenable<List<PoseLandmark>> landmarks;
  final double imageAspect;
  final bool mirror;
  final double visibilityThreshold;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final list = landmarks.value;
    if (list.isEmpty || size.isEmpty) return;

    final scale = math.max(size.width / imageAspect, size.height / 1.0);
    final dw = imageAspect * scale;
    final dh = scale;
    final dx = (size.width - dw) / 2;
    final dy = (size.height - dh) / 2;

    final points = <Offset>[];
    for (final l in list) {
      if (l.visibility < visibilityThreshold) continue;
      final nx = mirror ? 1.0 - l.x : l.x;
      points.add(Offset(dx + nx * dw, dy + l.y * dh));
    }
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 2;
    canvas.drawPoints(ui.PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(PoseLandmarkPainter old) =>
      old.landmarks != landmarks ||
      old.imageAspect != imageAspect ||
      old.mirror != mirror ||
      old.visibilityThreshold != visibilityThreshold ||
      old.radius != radius ||
      old.color != color;
}
