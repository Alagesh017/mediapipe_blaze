import '../yoga_accuracy.dart';
import '../yoga_angle_input.dart';

Map<String, dynamic> evaluateBowPose(YogaAngleInput i) {
  var res = '';
  var accuracy = 0;

  final noHuman = i.shoulderElbowHipLeft <= 0 &&
      i.hipKneeAnkleLeft <= 0 &&
      i.shoulderElbowHipRight <= 0 &&
      i.hipKneeAnkleRight <= 0 &&
      i.shoulderHipElbowLeft <= 0 &&
      i.shoulderHipElbowRight <= 0 &&
      i.shoulderElbowWristLeft <= 0 &&
      i.shoulderElbowWristRight <= 0;

  final incomplete = i.shoulderElbowHipLeft < 30 ||
      i.hipKneeAnkleLeft < 30 ||
      i.shoulderElbowHipRight < 30 ||
      i.hipKneeAnkleRight < 30;

  if (noHuman || incomplete) {
    return {'res': 'Fix Position', 'accuracy': 0};
  }

  if (i.shoulderElbowHipLeft > 130 &&
      i.shoulderElbowHipRight > 130 &&
      i.hipKneeAnkleLeft > 160 &&
      i.hipKneeAnkleRight > 160 &&
      i.shoulderHipElbowLeft < 30 &&
      i.shoulderHipElbowRight < 30 &&
      i.shoulderElbowWristLeft > 160 &&
      i.shoulderElbowWristRight > 160) {
    return {'res': 'Fix Position', 'accuracy': 0};
  }

  const sehLMin = 70, sehLMax = 90;
  const sehRMin = 70, sehRMax = 90;
  const hkaLMin = 75, hkaLMax = 95;
  const hkaRMin = 75, hkaRMax = 95;
  const sheLMin = 15, sheLMax = 40;
  const sheRMin = 15, sheRMax = 40;
  const sewLMin = 160, sewLMax = 180;
  const sewRMin = 160, sewRMax = 180;

  final acc = [
    yogaCalculateAccuracy(i.shoulderElbowHipLeft, sehLMin, sehLMax),
    yogaCalculateAccuracy(i.shoulderElbowHipRight, sehRMin, sehRMax),
    yogaCalculateAccuracy(i.hipKneeAnkleLeft, hkaLMin, hkaLMax),
    yogaCalculateAccuracy(i.hipKneeAnkleRight, hkaRMin, hkaRMax),
    yogaCalculateAccuracy(i.shoulderHipElbowLeft, sheLMin, sheLMax),
    yogaCalculateAccuracy(i.shoulderHipElbowRight, sheRMin, sheRMax),
    yogaCalculateAccuracy(i.shoulderElbowWristLeft, sewLMin, sewLMax),
    yogaCalculateAccuracy(i.shoulderElbowWristRight, sewRMin, sewRMax),
  ];

  accuracy = acc.reduce((a, b) => a + b) ~/ acc.length;

  if (accuracy >= 80) {
    res = 'Good';
  } else if (accuracy >= 40) {
    res = 'Almost There';
  } else {
    res = 'Fix Position';
  }

  return {'res': res, 'accuracy': accuracy};
}