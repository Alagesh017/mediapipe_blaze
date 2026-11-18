import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateOneLeggedPose(YogaAngleInput i) {
  var res = '';
  var accuracy = 0;

  final noHuman = i.hipKneeAnkleLeft <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderHipKneeLeft <= 0 &&
      i.shoulderHipKneeRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0 &&
      i.angleBetweenLegs <= 0;

  final incomplete = i.hipKneeAnkleLeft < 40 ||
      i.hipKneeAnkleRight < 40 ||
      i.shoulderHipKneeLeft < 40 ||
      i.shoulderHipKneeRight < 40 ||
      i.angleBetweenLegs < 30;

  if (noHuman || incomplete) {
    return {'res': 'Fix Position', 'accuracy': 0};
  }

  final isLeftLegRaised = i.shoulderHipKneeLeft < i.shoulderHipKneeRight;

  const standingLegHipKneeMin = 160, standingLegHipKneeMax = 185;
  const raisedLegHipKneeMin = 85, raisedLegHipKneeMax = 120;
  const standingShoulderHipKneeMin = 150, standingShoulderHipKneeMax = 185;
  const raisedShoulderHipKneeMin = 85, raisedShoulderHipKneeMax = 120;
  const shoulderElbowWristMin = 130, shoulderElbowWristMax = 180;
  const angleBetweenLegsMin = 95, angleBetweenLegsMax = 145;

  late int hkaLMin, hkaLMax, hkaRMin, hkaRMax, shkLMin, shkLMax, shkRMin, shkRMax;

  if (isLeftLegRaised) {
    hkaLMin = raisedLegHipKneeMin;
    hkaLMax = raisedLegHipKneeMax;
    shkLMin = raisedShoulderHipKneeMin;
    shkLMax = raisedShoulderHipKneeMax;
    hkaRMin = standingLegHipKneeMin;
    hkaRMax = standingLegHipKneeMax;
    shkRMin = standingShoulderHipKneeMin;
    shkRMax = standingShoulderHipKneeMax;
  } else {
    hkaRMin = raisedLegHipKneeMin;
    hkaRMax = raisedLegHipKneeMax;
    shkRMin = raisedShoulderHipKneeMin;
    shkRMax = raisedShoulderHipKneeMax;
    hkaLMin = standingLegHipKneeMin;
    hkaLMax = standingLegHipKneeMax;
    shkLMin = standingShoulderHipKneeMin;
    shkLMax = standingShoulderHipKneeMax;
  }

  final hkaL = yogaCalculateAccuracy(i.hipKneeAnkleLeft, hkaLMin, hkaLMax);
  final hkaR = yogaCalculateAccuracy(i.hipKneeAnkleRight, hkaRMin, hkaRMax);
  final shkL = yogaCalculateAccuracy(i.shoulderHipKneeLeft, shkLMin, shkLMax);
  final shkR = yogaCalculateAccuracy(i.shoulderHipKneeRight, shkRMin, shkRMax);
  final sewL = yogaCalculateAccuracy(
      i.shoulderElbowWristLeft, shoulderElbowWristMin, shoulderElbowWristMax);
  final sewR = yogaCalculateAccuracy(
      i.shoulderElbowWristRight, shoulderElbowWristMin, shoulderElbowWristMax);
  final legSpread = yogaCalculateAccuracy(
      i.angleBetweenLegs, angleBetweenLegsMin, angleBetweenLegsMax);

  final leftSide = (hkaL + shkL + sewL + legSpread) ~/ 4;
  final rightSide = (hkaR + shkR + sewR + legSpread) ~/ 4;
  accuracy = leftSide > rightSide ? leftSide : rightSide;

  if (accuracy >= 85) {
    res = 'Good';
  } else if (accuracy >= 45) {
    res = 'Almost There';
  } else {
    res = 'Fix Position';
  }

  return {'res': res, 'accuracy': accuracy};
}