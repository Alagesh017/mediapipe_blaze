import 'dart:math' as math;
import 'dart:ui';

import '../pose/pose_landmark.dart';

/// Joint angles and flags passed into each pose's scoring logic (matches your
/// generated `main(...)` inputs).
class YogaAngleInput {
  const YogaAngleInput({
  required this.elbowShoulderHipLeft,
    required this.elbowShoulderHipRight,
    required this.shoulderElbowHipLeft,
    required this.shoulderElbowHipRight,
    required this.hipKneeAnkleLeft,
    required this.hipKneeAnkleRight,
    required this.shoulderHipElbowLeft,
    required this.shoulderHipElbowRight,
    required this.shoulderHipKneeLeft,
    required this.shoulderHipKneeRight,
    required this.elbowShoulderWristLeft,
    required this.elbowShoulderWristRight,
    required this.shoulderHipShoulder,
    required this.shoulderElbowWristLeft,
    required this.shoulderElbowWristRight,
    required this.angleBetweenHands,
    required this.angleBetweenLegs,
    required this.areBothHandsAboveNose,
    required this.isAnyHandAboveNose,
    required this.isAnyLegAboveNose,
  });

  final int elbowShoulderHipLeft;
  final int elbowShoulderHipRight;
  final int shoulderElbowHipLeft;
  final int shoulderElbowHipRight;
  final int hipKneeAnkleLeft;
  final int hipKneeAnkleRight;
  final int shoulderHipElbowLeft;
  final int shoulderHipElbowRight;
  final int shoulderHipKneeLeft;
  final int shoulderHipKneeRight;
  final int elbowShoulderWristLeft;
  final int elbowShoulderWristRight;
  final int shoulderHipShoulder;
  final int shoulderElbowWristLeft;
  final int shoulderElbowWristRight;
  final int angleBetweenHands;
  final int angleBetweenLegs;
  final bool areBothHandsAboveNose;
  final bool isAnyHandAboveNose;
  final bool isAnyLegAboveNose;

  static const empty = YogaAngleInput(
    elbowShoulderHipLeft: 0,
    elbowShoulderHipRight: 0,
    shoulderElbowHipLeft: 0,
    shoulderElbowHipRight: 0,
    hipKneeAnkleLeft: 0,
    hipKneeAnkleRight: 0,
    shoulderHipElbowLeft: 0,
    shoulderHipElbowRight: 0,
    shoulderHipKneeLeft: 0,
    shoulderHipKneeRight: 0,
    elbowShoulderWristLeft: 0,
    elbowShoulderWristRight: 0,
    shoulderHipShoulder: 0,
    shoulderElbowWristLeft: 0,
    shoulderElbowWristRight: 0,
    angleBetweenHands: 0,
    angleBetweenLegs: 0,
    areBothHandsAboveNose: false,
    isAnyHandAboveNose: false,
    isAnyLegAboveNose: false,
  );

  static YogaAngleInput fromLandmarks(
    List<PoseLandmark> landmarks, {
    double visibilityThreshold = 0.5,
  }) {
    if (landmarks.length < kPoseLandmarkCount) return empty;
    PoseLandmark lm(int i) => landmarks[i];

    return YogaAngleInput(
      hipKneeAnkleLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftHip),
        lm(_BlazeLandmarkIndex.leftKnee),
        lm(_BlazeLandmarkIndex.leftAnkle),
        visibilityThreshold,
      ),
      hipKneeAnkleRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightHip),
        lm(_BlazeLandmarkIndex.rightKnee),
        lm(_BlazeLandmarkIndex.rightAnkle),
        visibilityThreshold,
      ),
      shoulderHipKneeLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftHip),
        lm(_BlazeLandmarkIndex.leftKnee),
        visibilityThreshold,
      ),
      shoulderHipKneeRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightHip),
        lm(_BlazeLandmarkIndex.rightKnee),
        visibilityThreshold,
      ),
      shoulderElbowWristLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftElbow),
        lm(_BlazeLandmarkIndex.leftWrist),
        visibilityThreshold,
      ),
      shoulderElbowWristRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightElbow),
        lm(_BlazeLandmarkIndex.rightWrist),
        visibilityThreshold,
      ),
      elbowShoulderHipLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftElbow),
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftHip),
        visibilityThreshold,
      ),
      elbowShoulderHipRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightElbow),
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightHip),
        visibilityThreshold,
      ),
      shoulderElbowHipLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftElbow),
        lm(_BlazeLandmarkIndex.leftHip),
        visibilityThreshold,
      ),
      shoulderElbowHipRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightElbow),
        lm(_BlazeLandmarkIndex.rightHip),
        visibilityThreshold,
      ),
      shoulderHipElbowLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftHip),
        lm(_BlazeLandmarkIndex.leftElbow),
        visibilityThreshold,
      ),
      shoulderHipElbowRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightHip),
        lm(_BlazeLandmarkIndex.rightElbow),
        visibilityThreshold,
      ),
      elbowShoulderWristLeft: _jointAngle(
        lm(_BlazeLandmarkIndex.leftElbow),
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.leftWrist),
        visibilityThreshold,
      ),
      elbowShoulderWristRight: _jointAngle(
        lm(_BlazeLandmarkIndex.rightElbow),
        lm(_BlazeLandmarkIndex.rightShoulder),
        lm(_BlazeLandmarkIndex.rightWrist),
        visibilityThreshold,
      ),
      shoulderHipShoulder: _jointAngle(
        lm(_BlazeLandmarkIndex.leftHip),
        lm(_BlazeLandmarkIndex.leftShoulder),
        lm(_BlazeLandmarkIndex.rightShoulder),
        visibilityThreshold,
      ),
      angleBetweenHands: _angleBetweenVectors(
        _vec(lm(_BlazeLandmarkIndex.leftWrist), lm(_BlazeLandmarkIndex.leftShoulder)),
        _vec(lm(_BlazeLandmarkIndex.rightWrist), lm(_BlazeLandmarkIndex.rightShoulder)),
      ),
      angleBetweenLegs: _angleBetweenVectors(
        _vec(lm(_BlazeLandmarkIndex.leftAnkle), lm(_BlazeLandmarkIndex.leftHip)),
        _vec(lm(_BlazeLandmarkIndex.rightAnkle), lm(_BlazeLandmarkIndex.rightHip)),
      ),
      areBothHandsAboveNose: _bothHandsAbove(lm(_BlazeLandmarkIndex.nose), lm(_BlazeLandmarkIndex.leftWrist),
          lm(_BlazeLandmarkIndex.rightWrist), visibilityThreshold),
      isAnyHandAboveNose: _anyHandAbove(lm(_BlazeLandmarkIndex.nose), lm(_BlazeLandmarkIndex.leftWrist),
          lm(_BlazeLandmarkIndex.rightWrist), visibilityThreshold),
      isAnyLegAboveNose: _anyLegAbove(lm(_BlazeLandmarkIndex.nose), lm(_BlazeLandmarkIndex.leftAnkle),
          lm(_BlazeLandmarkIndex.rightAnkle), visibilityThreshold),
    );
  }
}

abstract final class _BlazeLandmarkIndex {
  static const nose = 0;
  static const leftShoulder = 11;
  static const rightShoulder = 12;
  static const leftElbow = 13;
  static const rightElbow = 14;
  static const leftWrist = 15;
  static const rightWrist = 16;
  static const leftHip = 23;
  static const rightHip = 24;
  static const leftKnee = 25;
  static const rightKnee = 26;
  static const leftAnkle = 27;
  static const rightAnkle = 28;
}

Offset _vec(PoseLandmark a, PoseLandmark b) =>
    Offset(b.x - a.x, b.y - a.y);

int _jointAngle(
  PoseLandmark a,
  PoseLandmark b,
  PoseLandmark c,
  double thresh,
) {
  if (a.visibility < thresh || b.visibility < thresh || c.visibility < thresh) {
    return 0;
  }
  return _angleDegrees(Offset(a.x, a.y), Offset(b.x, b.y), Offset(c.x, c.y));
}

int _angleDegrees(Offset a, Offset b, Offset c) {
  final ba = a - b;
  final bc = c - b;
  final denom = ba.distance * bc.distance;
  if (denom < 1e-9) return 0;
  final cos = ((ba.dx * bc.dx + ba.dy * bc.dy) / denom).clamp(-1.0, 1.0);
  return (math.acos(cos) * 180 / math.pi).round();
}

int _angleBetweenVectors(Offset v1, Offset v2) {
  final d = v1.distance * v2.distance;
  if (d < 1e-9) return 0;
  final cos = ((v1.dx * v2.dx + v1.dy * v2.dy) / d).clamp(-1.0, 1.0);
  return (math.acos(cos) * 180 / math.pi).round();
}

bool _bothHandsAbove(
  PoseLandmark nose,
  PoseLandmark lw,
  PoseLandmark rw,
  double thresh,
) {
  if (nose.visibility < thresh ||
      lw.visibility < thresh ||
      rw.visibility < thresh) {
    return false;
  }
  return lw.y < nose.y && rw.y < nose.y;
}

bool _anyHandAbove(
  PoseLandmark nose,
  PoseLandmark lw,
  PoseLandmark rw,
  double thresh,
) {
  if (nose.visibility < thresh) return false;
  final left = lw.visibility >= thresh && lw.y < nose.y;
  final right = rw.visibility >= thresh && rw.y < nose.y;
  return left || right;
}

bool _anyLegAbove(
  PoseLandmark nose,
  PoseLandmark la,
  PoseLandmark ra,
  double thresh,
) {
  if (nose.visibility < thresh) return false;
  final left = la.visibility >= thresh && la.y < nose.y;
  final right = ra.visibility >= thresh && ra.y < nose.y;
  return left || right;
}