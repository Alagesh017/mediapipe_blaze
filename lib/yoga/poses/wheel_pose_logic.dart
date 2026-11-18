import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateWheelPose(
  YogaAngleInput i, {
  int validPosesCount = 0,
  int currentPoseIndex = 0,
}) {
  var res = '';
  var accuracy = 0;

  Map<String, dynamic> base(String res, int acc) => {
        'res': res,
        'accuracy': acc,
        'validPosesCount': validPosesCount,
        'currentPose': 'Chakrasana (Wheel Pose)',
        'currentPoseIndex': currentPoseIndex,
      };

  final noHuman = i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderHipElbowLeft <= 0 &&
      i.shoulderHipElbowRight <= 0 &&
      i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0;

  final incomplete = i.hipKneeAnkleLeft < 60 ||
      i.hipKneeAnkleRight < 60 ||
      i.shoulderHipKneeLeft < 40 ||
      i.shoulderHipKneeRight < 40 ||
      i.shoulderElbowWristLeft < 60 ||
      i.shoulderElbowWristRight < 60 ||
      i.shoulderHipElbowLeft <= 0 ||
      i.shoulderHipElbowRight <= 0;

  if (noHuman) return base('No Human', 0);
  if (incomplete) return base('Fix Position', 0);

  if (i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160 &&
      i.shoulderHipKneeLeft > 160 &&
      i.shoulderHipKneeRight > 160) {
    return base('Standing', 0);
  }

  const legMin = 120, legMax = 145;
  const archMin = 75, archMax = 105;
  const torsoMin = 2, torsoMax = 10;
  const armMin = 160, armMax = 180;

  final legScore = (yogaCalculateAccuracy(i.hipKneeAnkleLeft, legMin, legMax) +
          yogaCalculateAccuracy(i.hipKneeAnkleRight, legMin, legMax)) ~/
      2;

  final archScore = (yogaCalculateAccuracy(
              i.shoulderHipKneeLeft, archMin, archMax) +
          yogaCalculateAccuracy(i.shoulderHipKneeRight, archMin, archMax)) ~/
      2;

  final torsoScore = (yogaCalculateAccuracy(
              i.shoulderHipElbowLeft, torsoMin, torsoMax) +
          yogaCalculateAccuracy(i.shoulderHipElbowRight, torsoMin, torsoMax)) ~/
      2;

  final armScore = (yogaCalculateAccuracy(
              i.shoulderElbowWristLeft, armMin, armMax) +
          yogaCalculateAccuracy(i.shoulderElbowWristRight, armMin, armMax)) ~/
      2;

  accuracy =
      ((legScore * 25) + (archScore * 35) + (armScore * 25) + (torsoScore * 15)) ~/
          100;

  if (accuracy < 0) accuracy = 0;
  if (accuracy > 100) accuracy = 100;

  if (accuracy >= 75) {
    res = 'Good';
    validPosesCount += 1;
  } else if (accuracy >= 40) {
    res = 'Incomplete';
  } else {
    res = 'Fix Position';
  }

  return base(res, accuracy);
}