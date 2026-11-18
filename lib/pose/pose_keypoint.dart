/// MoveNet outputs 17 COCO keypoints (NOT the 33 of BlazePose).
const int kKeypointCount = 17;

const List<String> kKeypointNames = [
  'nose', 'left eye', 'right eye', 'left ear', 'right ear',
  'left shoulder', 'right shoulder', 'left elbow', 'right elbow',
  'left wrist', 'right wrist', 'left hip', 'right hip',
  'left knee', 'right knee', 'left ankle', 'right ankle',
];

class PoseKeypoint {
  const PoseKeypoint({
    required this.index,
    required this.x,
    required this.y,
    required this.score,
  });

  final int index;
  final double x; // normalized 0..1 over the UPRIGHT camera frame (not mirrored)
  final double y; // normalized 0..1
  final double score; // confidence 0..1

  String get name => kKeypointNames[index];
}
