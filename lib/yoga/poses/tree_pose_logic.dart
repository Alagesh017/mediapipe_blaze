import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateTreePose(
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
        'currentPose': 'Tree Pose',
        'currentPoseIndex': currentPoseIndex,
      };

  if (i.hipKneeAnkleLeft == 0 &&
      i.hipKneeAnkleRight == 0 &&
      i.shoulderElbowWristLeft == 0 &&
      i.shoulderElbowWristRight == 0 &&
      i.elbowShoulderHipLeft == 0 &&
      i.elbowShoulderHipRight == 0 &&
      i.shoulderHipKneeLeft == 0 &&
      i.shoulderHipKneeRight == 0) {
    return base('No Human', 0);
  }

  if (i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160 &&
      i.shoulderHipKneeLeft > 160 &&
      i.shoulderHipKneeRight > 160 &&
      i.angleBetweenLegs < 20) {
    return base('Standing', 0);
  }

  const bentLegMin = 15, bentLegMax = 130;
  const standingLegMin = 160, standingLegMax = 185;
  const armMin = 25, armMax = 75;
  const balanceMin = 95, balanceMax = 180;

  final isLeftTree = i.hipKneeAnkleLeft >= bentLegMin &&
      i.hipKneeAnkleLeft <= bentLegMax &&
      i.hipKneeAnkleRight >= standingLegMin &&
      i.hipKneeAnkleRight <= standingLegMax &&
      i.shoulderHipKneeRight >= balanceMin;

  final isRightTree = i.hipKneeAnkleRight >= bentLegMin &&
      i.hipKneeAnkleRight <= bentLegMax &&
      i.hipKneeAnkleLeft >= standingLegMin &&
      i.hipKneeAnkleLeft <= standingLegMax &&
      i.shoulderHipKneeLeft >= balanceMin;

  if (isLeftTree || isRightTree) {
    final bentLeg =
        isRightTree ? i.hipKneeAnkleRight : i.hipKneeAnkleLeft;
    final standingLeg =
        isRightTree ? i.hipKneeAnkleLeft : i.hipKneeAnkleRight;
    final balanceAngle =
        isRightTree ? i.shoulderHipKneeLeft : i.shoulderHipKneeRight;

    final bentLegAcc =
        yogaCalculateAccuracy(bentLeg, bentLegMin, bentLegMax);
    final standingLegAcc =
        yogaCalculateAccuracy(standingLeg, standingLegMin, standingLegMax);
    final balanceAcc =
        yogaCalculateAccuracy(balanceAngle, balanceMin, balanceMax);
    final armL = yogaCalculateAccuracy(
        i.shoulderElbowWristLeft, armMin, armMax);
    final armR = yogaCalculateAccuracy(
        i.shoulderElbowWristRight, armMin, armMax);

    accuracy =
        (bentLegAcc + standingLegAcc + balanceAcc + armL + armR) ~/ 5;
    res = accuracy >= 75 ? 'Good' : 'Fix Position';
    if (accuracy >= 75) validPosesCount += 1;
    return base(res, accuracy);
  }

  final partial = (i.hipKneeAnkleLeft > 20 && i.hipKneeAnkleRight > 20) &&
      (i.shoulderElbowWristLeft > 10 || i.shoulderElbowWristRight > 10);

  if (partial) {
    return base('Incomplete', 30);
  }
  return base('Fix Position', 0);
}