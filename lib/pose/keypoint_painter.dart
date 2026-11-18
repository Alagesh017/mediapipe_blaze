import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pose_keypoint.dart';

/// Draws dots only (no lines, no text). The canvas must have the SAME aspect
/// ratio as the camera preview, so normalized x/y map straight onto it.
class KeypointPainter extends CustomPainter {
  KeypointPainter({
    required this.keypoints,
    this.mirror = false,
    this.scoreThreshold = 0.3,
    this.radius = 5.0,
    this.color = Colors.greenAccent,
  }) : super(repaint: keypoints);

  final ValueListenable<List<PoseKeypoint>> keypoints;
  final bool mirror;
  final double scoreThreshold;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final list = keypoints.value;
    if (list.isEmpty) return;

    final points = <Offset>[];
    for (final k in list) {
      if (k.score < scoreThreshold) continue;
      final x = mirror ? 1.0 - k.x : k.x;
      points.add(Offset(x * size.width, k.y * size.height));
    }
    if (points.isEmpty) return;

    canvas.drawPoints(
      ui.PointMode.points,
      points,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * 2,
    );
  }

  @override
  bool shouldRepaint(KeypointPainter old) =>
      old.keypoints != keypoints ||
      old.mirror != mirror ||
      old.scoreThreshold != scoreThreshold ||
      old.radius != radius ||
      old.color != color;
}
