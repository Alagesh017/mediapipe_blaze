import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateThreeLeggedDogPose(
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
        'currentPose': 'Three-Legged Downward Dog',
        'currentPoseIndex': currentPoseIndex,
      };

  final noHuman = i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0 &&
      i.elbowShoulderHipLeft <= 0 &&
      i.elbowShoulderHipRight <= 0 &&
      i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0;

  final incomplete = i.hipKneeAnkleLeft < 40 ||
      i.hipKneeAnkleRight < 40 ||
      i.shoulderHipKneeLeft < 40 ||
      i.shoulderHipKneeRight < 40 ||
      i.shoulderElbowWristLeft < 40 ||
      i.shoulderElbowWristRight < 40;

  if (noHuman || incomplete) return base('Fix Position', 0);
  if (!i.isAnyLegAboveNose) return base('Fix Position', 0);

  const armMin = 150, armMax = 180;
  const legMin = 160, legMax = 180;
  const torsoMin = 150, torsoMax = 180;
  const splitMin = 80, splitMax = 180;
  const diagonalMin = 40, diagonalMax = 170;

  final armL = yogaCalculateAccuracy(i.shoulderElbowWristLeft, armMin, armMax);
  final armR = yogaCalculateAccuracy(i.shoulderElbowWristRight, armMin, armMax);
  final armScore = (((armL + armR) ~/ 2) * 20) ~/ 100;

  final legL = yogaCalculateAccuracy(i.hipKneeAnkleLeft, legMin, legMax);
  final legR = yogaCalculateAccuracy(i.hipKneeAnkleRight, legMin, legMax);
  final legScore = (((legL + legR) ~/ 2) * 20) ~/ 100;

  final legSplitScore =
      (yogaCalculateAccuracy(i.angleBetweenLegs, splitMin, splitMax) * 20) ~/ 100;

  final torsoL =
      yogaCalculateAccuracy(i.elbowShoulderHipLeft, torsoMin, torsoMax);
  final torsoR =
      yogaCalculateAccuracy(i.elbowShoulderHipRight, torsoMin, torsoMax);
  final torsoScore = (((torsoL + torsoR) ~/ 2) * 20) ~/ 100;

  final diagL =
      yogaCalculateAccuracy(i.shoulderHipKneeLeft, diagonalMin, diagonalMax);
  final diagR =
      yogaCalculateAccuracy(i.shoulderHipKneeRight, diagonalMin, diagonalMax);
  final diagScore = (((diagL + diagR) ~/ 2) * 20) ~/ 100;

  accuracy = armScore + legScore + legSplitScore + torsoScore + diagScore;
  if (accuracy > 100) accuracy = 100;

  if (accuracy >= 85) {
    res = 'Good';
    validPosesCount += 1;
  } else if (accuracy >= 40) {
    res = 'Almost There';
  } else {
    res = 'Fix Position';
  }

  return base(res, accuracy);
}