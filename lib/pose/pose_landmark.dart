import 'dart:typed_data';

const int kPoseLandmarkCount = 33;
const int _kStride = 5; // x, y, z, visibility, presence

/// Official MediaPipe 33-landmark order.
const List<String> kPoseLandmarkNames = [
  'nose', 'left eye inner', 'left eye', 'left eye outer',
  'right eye inner', 'right eye', 'right eye outer',
  'left ear', 'right ear', 'mouth left', 'mouth right',
  'left shoulder', 'right shoulder', 'left elbow', 'right elbow',
  'left wrist', 'right wrist', 'left pinky', 'right pinky',
  'left index', 'right index', 'left thumb', 'right thumb',
  'left hip', 'right hip', 'left knee', 'right knee',
  'left ankle', 'right ankle', 'left heel', 'right heel',
  'left foot index', 'right foot index',
];

class PoseLandmark {
  const PoseLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
  });

  final int index;
  final double x; // normalized 0..1 (upright image, NOT mirrored)
  final double y; // normalized 0..1
  final double z;
  final double visibility;
  final double presence;

  String get name => kPoseLandmarkNames[index];

  /// Empty list => no person detected.
  static List<PoseLandmark> decode(Object? raw) {
    if (raw is Float64List) {
      return _decodeValues(raw);
    }
    if (raw is Uint8List) {
      return _decodeValues(Float64List.view(raw.buffer));
    }
    if (raw is! List || raw.length < _kStride) return const [];
    final Float64List data =
        Float64List.fromList(raw.map((e) => (e as num).toDouble()).toList());
    return _decodeValues(data);
  }

  static List<PoseLandmark> _decodeValues(Float64List data) {
    if (data.length < _kStride) return const [];
    final count = data.length ~/ _kStride;
    return List<PoseLandmark>.generate(count, (i) {
      final o = i * _kStride;
      return PoseLandmark(
        index: i,
        x: data[o],
        y: data[o + 1],
        z: data[o + 2],
        visibility: data[o + 3],
        presence: data[o + 4],
      );
    }, growable: false);
  }
}
