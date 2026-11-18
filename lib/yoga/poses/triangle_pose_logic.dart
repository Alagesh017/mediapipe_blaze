import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

bool _triangleStanding(YogaAngleInput i) {
  return i.hipKneeAnkleLeft >= 170 &&
      i.hipKneeAnkleRight >= 170 &&
      i.shoulderHipKneeLeft >= 160 &&
      i.shoulderHipKneeRight >= 160 &&
      i.elbowShoulderHipLeft < 50 &&
      i.elbowShoulderHipRight < 50 &&
      i.shoulderElbowWristLeft > 160 &&
      i.shoulderElbowWristRight > 160 &&
      i.angleBetweenLegs < 20;
}

Map<String, dynamic> evaluateTrianglePose(
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
        'currentPose': 'Trikonasana',
        'currentPoseIndex': currentPoseIndex,
      };

  final noHuman = i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0 &&
      i.angleBetweenLegs <= 0 &&
      i.elbowShoulderHipLeft <= 0 &&
      i.elbowShoulderHipRight <= 0;

  final incomplete = i.hipKneeAnkleLeft < 40 ||
      i.hipKneeAnkleRight < 40 ||
      i.angleBetweenLegs < 30;

  if (noHuman || incomplete) return base('Fix Position', 0);
  if (_triangleStanding(i)) return base('Fix Position', 0);

  const legSpreadMin = 30, legSpreadMax = 80;
  const shoulderAngleMin = 40, shoulderAngleMax = 140;
  const handRaiseMin = 120, handRaiseMax = 180;
  const otherAngleMin = 100, otherAngleMax = 178;

  final legAcc =
      yogaCalculateAccuracy(i.angleBetweenLegs, legSpreadMin, legSpreadMax);
  final legScore = (legAcc * 30) ~/ 100;

  var handScore = 0;
  if (i.isAnyHandAboveNose) {
    final raised = i.shoulderElbowWristLeft > i.shoulderElbowWristRight
        ? i.shoulderElbowWristLeft
        : i.shoulderElbowWristRight;
    final handAcc = yogaCalculateAccuracy(raised, handRaiseMin, handRaiseMax);
    handScore = (handAcc * 30) ~/ 100;
  }

  final shL = yogaCalculateAccuracy(
      i.shoulderHipKneeLeft, shoulderAngleMin, shoulderAngleMax);
  final shR = yogaCalculateAccuracy(
      i.shoulderHipKneeRight, shoulderAngleMin, shoulderAngleMax);
  final shoulderScore = (((shL + shR) ~/ 2) * 20) ~/ 100;

  final hkaL =
      yogaCalculateAccuracy(i.hipKneeAnkleLeft, otherAngleMin, otherAngleMax);
  final hkaR =
      yogaCalculateAccuracy(i.hipKneeAnkleRight, otherAngleMin, otherAngleMax);
  final eshL =
      yogaCalculateAccuracy(i.elbowShoulderHipLeft, otherAngleMin, otherAngleMax);
  final eshR = yogaCalculateAccuracy(
      i.elbowShoulderHipRight, otherAngleMin, otherAngleMax);
  final othersScore = (((hkaL + hkaR + eshL + eshR) ~/ 4) * 20) ~/ 100;

  accuracy = legScore + handScore + shoulderScore + othersScore;
  if (accuracy > 100) accuracy = 100;
  if (accuracy < 0) accuracy = 0;

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