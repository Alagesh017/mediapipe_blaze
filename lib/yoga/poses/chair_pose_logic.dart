import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

bool _chairIsStanding(YogaAngleInput i) {
  return i.shoulderHipKneeLeft > 150 &&
      i.shoulderHipKneeRight > 150 &&
      i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160;
}

Map<String, dynamic> evaluateChairPose(
  YogaAngleInput i, {
  int validPosesCount = 0,
  int currentPoseIndex = 0,
}) {
  var res = '';
  var accuracy = 0;

  Map<String, dynamic> out(String res, int accuracy) => {
        'res': res,
        'accuracy': accuracy,
        'validPosesCount': validPosesCount,
        'currentPose': 'Utkatasana',
        'currentPoseIndex': currentPoseIndex,
      };

  final noHuman = i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.elbowShoulderWristLeft <= 0 &&
      i.elbowShoulderWristRight <= 0;

  final incomplete = i.shoulderHipKneeLeft < 40 ||
      i.shoulderHipKneeRight < 40 ||
      i.hipKneeAnkleLeft < 40 ||
      i.hipKneeAnkleRight < 40;

  if (noHuman || incomplete) return out('Fix Position', 0);
  if (_chairIsStanding(i)) return out('Fix Position', 0);

  const shoulderHipKneeMin = 90, shoulderHipKneeMax = 140;
  const hipKneeAnkleMin = 90, hipKneeAnkleMax = 140;
  const minHandLiftAngle = 5;

  final shkL = yogaCalculateAccuracy(
      i.shoulderHipKneeLeft, shoulderHipKneeMin, shoulderHipKneeMax);
  final shkR = yogaCalculateAccuracy(
      i.shoulderHipKneeRight, shoulderHipKneeMin, shoulderHipKneeMax);
  final hkaL =
      yogaCalculateAccuracy(i.hipKneeAnkleLeft, hipKneeAnkleMin, hipKneeAnkleMax);
  final hkaR = yogaCalculateAccuracy(
      i.hipKneeAnkleRight, hipKneeAnkleMin, hipKneeAnkleMax);

  var handRaiseScore = 0;
  if (i.areBothHandsAboveNose) {
    handRaiseScore = 100;
  } else if (i.elbowShoulderWristLeft >= minHandLiftAngle &&
      i.elbowShoulderWristRight >= minHandLiftAngle) {
    handRaiseScore = 85;
  }

  accuracy = (shkL + shkR + hkaL + hkaR + handRaiseScore) ~/ 5;

  if (i.shoulderHipKneeLeft >= shoulderHipKneeMin &&
      i.shoulderHipKneeRight >= shoulderHipKneeMin &&
      i.hipKneeAnkleLeft >= hipKneeAnkleMin &&
      i.hipKneeAnkleRight >= hipKneeAnkleMin &&
      handRaiseScore >= 85) {
    res = 'Good';
    validPosesCount += 1;
  } else {
    res = 'Fix Position';
  }

  return out(res, accuracy);
}