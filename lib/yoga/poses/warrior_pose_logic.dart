import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

/// YOGA_CODE_ID = 5 — Warrior Pose (Virabhadrasana).
Map<String, dynamic> evaluateWarriorPose(YogaAngleInput i) {
  var res = '';
  var accuracy = 0;

  final noHuman = i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0;

  final incomplete =
      i.hipKneeAnkleLeft < 40 || i.hipKneeAnkleRight < 40;

  if (noHuman || incomplete) {
    return {'res': 'Fix Position', 'accuracy': 0};
  }

  if (i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160 &&
      i.shoulderHipKneeLeft > 150 &&
      i.shoulderHipKneeRight > 150) {
    return {'res': 'Standing', 'accuracy': 0};
  }

  const bentLegMin = 70, bentLegMax = 130;
  const straightLegMin = 160, straightLegMax = 180;
  const torsoBentMin = 75, torsoBentMax = 125;
  const torsoUprightMin = 110;
  const armMin = 150, armMax = 180;

  final validLegs = (i.hipKneeAnkleLeft >= bentLegMin &&
          i.hipKneeAnkleLeft <= bentLegMax &&
          i.hipKneeAnkleRight >= straightLegMin &&
          i.hipKneeAnkleRight <= straightLegMax) ||
      (i.hipKneeAnkleRight >= bentLegMin &&
          i.hipKneeAnkleRight <= bentLegMax &&
          i.hipKneeAnkleLeft >= straightLegMin &&
          i.hipKneeAnkleLeft <= straightLegMax);

  final validTorso = (i.shoulderHipKneeLeft >= torsoUprightMin ||
          i.shoulderHipKneeRight >= torsoUprightMin) ||
      (i.shoulderHipKneeLeft >= torsoBentMin &&
          i.shoulderHipKneeLeft <= torsoBentMax) ||
      (i.shoulderHipKneeRight >= torsoBentMin &&
          i.shoulderHipKneeRight <= torsoBentMax);

  final validArms = i.shoulderElbowWristLeft >= armMin &&
      i.shoulderElbowWristLeft <= armMax &&
      i.shoulderElbowWristRight >= armMin &&
      i.shoulderElbowWristRight <= armMax;

  final leftArmAcc =
      yogaCalculateAccuracy(i.shoulderElbowWristLeft, armMin, armMax);
  final rightArmAcc =
      yogaCalculateAccuracy(i.shoulderElbowWristRight, armMin, armMax);
  final leftLegAcc = yogaCalculateAccuracy(
      i.hipKneeAnkleLeft, bentLegMin, straightLegMax);
  final rightLegAcc = yogaCalculateAccuracy(
      i.hipKneeAnkleRight, bentLegMin, straightLegMax);

  accuracy = (leftArmAcc + rightArmAcc + leftLegAcc + rightLegAcc) ~/ 4;

  if (validLegs && validTorso && validArms) {
    res = 'Good';
    if (accuracy < 80) accuracy = 80;
  } else if ((validLegs && validTorso) ||
      (validLegs && validArms) ||
      (validTorso && validArms)) {
    res = 'Incomplete';
    if (accuracy < 50) accuracy = 50;
    if (accuracy > 75) accuracy = 75;
  } else {
    res = 'Fix Position';
    if (accuracy > 40) accuracy = 40;
  }

  return {'res': res, 'accuracy': accuracy};
}