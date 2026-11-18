import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateHalfMoonPose(
  YogaAngleInput i, {
  int validPosesCount = 0,
  int currentPoseIndex = 0,
}) {
  var res = '';
  var accuracy = 0;

  final noHuman = i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.elbowShoulderHipLeft <= 0 &&
      i.elbowShoulderHipRight <= 0 &&
      i.angleBetweenHands <= 0 &&
      i.angleBetweenLegs <= 0;

  final incomplete = i.shoulderHipKneeLeft < 40 ||
      i.shoulderHipKneeRight < 40 ||
      i.hipKneeAnkleLeft < 40 ||
      i.hipKneeAnkleRight < 40;

  Map<String, dynamic> fail() => {
        'res': 'Fix Position',
        'accuracy': 0,
        'validPosesCount': validPosesCount,
        'currentPose': 'Ardha Chandrasana',
        'currentPoseIndex': currentPoseIndex,
      };

  if (noHuman || incomplete) return fail();

  if (i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160 &&
      i.shoulderHipKneeLeft > 150 &&
      i.shoulderHipKneeRight > 150 &&
      i.angleBetweenLegs < 20) {
    return fail();
  }

  const elbowShoulderHipMin = 70, elbowShoulderHipMax = 115;
  const shoulderHipKneeMin = 60, shoulderHipKneeMax = 180;
  const hipKneeAnkleMin = 60, hipKneeAnkleMax = 180;
  const handAngleMin = 160, handAngleMax = 180;
  const legAngleMin = 85, legAngleMax = 115;

  final eshL = yogaCalculateAccuracy(
      i.elbowShoulderHipLeft, elbowShoulderHipMin, elbowShoulderHipMax);
  final eshR = yogaCalculateAccuracy(
      i.elbowShoulderHipRight, elbowShoulderHipMin, elbowShoulderHipMax);
  final shkL = yogaCalculateAccuracy(
      i.shoulderHipKneeLeft, shoulderHipKneeMin, shoulderHipKneeMax);
  final shkR = yogaCalculateAccuracy(
      i.shoulderHipKneeRight, shoulderHipKneeMin, shoulderHipKneeMax);
  final hkaL =
      yogaCalculateAccuracy(i.hipKneeAnkleLeft, hipKneeAnkleMin, hipKneeAnkleMax);
  final hkaR = yogaCalculateAccuracy(
      i.hipKneeAnkleRight, hipKneeAnkleMin, hipKneeAnkleMax);
  final handAcc =
      yogaCalculateAccuracy(i.angleBetweenHands, handAngleMin, handAngleMax);
  final legAcc =
      yogaCalculateAccuracy(i.angleBetweenLegs, legAngleMin, legAngleMax);

  accuracy = (eshL + eshR + shkL + shkR + hkaL + hkaR + handAcc + legAcc) ~/ 8;

  final isStanding = i.angleBetweenHands <= 90 &&
      i.angleBetweenLegs <= 20 &&
      i.shoulderHipKneeLeft >= 165 &&
      i.shoulderHipKneeRight >= 165 &&
      i.hipKneeAnkleLeft >= 165 &&
      i.hipKneeAnkleRight >= 165;

  final leftSideValid = i.elbowShoulderHipLeft >= elbowShoulderHipMin &&
      i.shoulderHipKneeLeft >= shoulderHipKneeMin &&
      i.hipKneeAnkleLeft >= hipKneeAnkleMin &&
      handAcc >= 85 &&
      legAcc >= 85;

  final rightSideValid = i.elbowShoulderHipRight >= elbowShoulderHipMin &&
      i.shoulderHipKneeRight >= shoulderHipKneeMin &&
      i.hipKneeAnkleRight >= hipKneeAnkleMin &&
      handAcc >= 85 &&
      legAcc >= 85;

  if (isStanding) {
    accuracy = 0;
    res = 'Standby Pose';
  } else if (leftSideValid || rightSideValid) {
    res = 'Good';
    validPosesCount += 1;
  } else {
    res = 'Fix Position';
  }

  if (accuracy > 96) accuracy = 96;
  if (accuracy < 0) accuracy = 0;

  return {
    'res': res,
    'accuracy': accuracy,
    'validPosesCount': validPosesCount,
    'currentPose': 'Ardha Chandrasana',
    'currentPoseIndex': currentPoseIndex,
  };
}