import 'pose_keypoint.dart';
import 'pose_landmark.dart';

/// Maps MoveNet’s 17 COCO keypoints into BlazePose’s 33-landmark layout so yoga
/// scoring can run (approximate — hand / foot detail points are omitted).
const List<(int moveNet, int blaze)> _kMoveNetToBlaze = [
  (0, 0), // nose
  (1, 2), // left eye
  (2, 5), // right eye
  (3, 7), // left ear
  (4, 8), // right ear
  (5, 11), // left shoulder
  (6, 12), // right shoulder
  (7, 13), // left elbow
  (8, 14), // right elbow
  (9, 15), // left wrist
  (10, 16), // right wrist
  (11, 23), // left hip
  (12, 24), // right hip
  (13, 25), // left knee
  (14, 26), // right knee
  (15, 27), // left ankle
  (16, 28), // right ankle
];

List<PoseLandmark> landmarksFromMoveNet(
  List<PoseKeypoint> keypoints, {
  double visibilityThreshold = 0.3,
}) {
  if (keypoints.length < 17) return const [];

  final out = List<PoseLandmark?>.filled(kPoseLandmarkCount, null);
  for (final pair in _kMoveNetToBlaze) {
    final k = keypoints[pair.$1];
    if (k.score < visibilityThreshold) continue;
    out[pair.$2] = PoseLandmark(
      index: pair.$2,
      x: k.x,
      y: k.y,
      z: 0,
      visibility: k.score,
      presence: k.score,
    );
  }

  final list = <PoseLandmark>[];
  for (var i = 0; i < kPoseLandmarkCount; i++) {
    final lm = out[i];
    if (lm != null) {
      list.add(lm);
    } else {
      list.add(PoseLandmark(
        index: i,
        x: 0,
        y: 0,
        z: 0,
        visibility: 0,
        presence: 0,
      ));
    }
  }
  return list;
}