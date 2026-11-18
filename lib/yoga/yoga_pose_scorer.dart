import '../pose/pose_landmark.dart';
import 'yoga_angle_input.dart';
import 'yoga_pose_item.dart';

class YogaPoseScorer {
  YogaPoseScorer(this.pose, {this.visibilityThreshold = 0.5});

  final YogaPoseItem pose;
  final double visibilityThreshold;

  Map<String, dynamic> scoreLandmarks(List<PoseLandmark> landmarks) {
    final input = YogaAngleInput.fromLandmarks(
      landmarks,
      visibilityThreshold: visibilityThreshold,
    );
    return pose.evaluate(input);
  }
}