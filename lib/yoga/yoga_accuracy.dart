int yogaCalculateAccuracy(int angle, int minAngle, int maxAngle) {
  if (maxAngle == minAngle) return angle == minAngle ? 100 : 0;
  var accuracy = 100;
  if (angle < minAngle) {
    accuracy = 100 - ((minAngle - angle) * 100 ~/ (maxAngle - minAngle));
  } else if (angle > maxAngle) {
    accuracy = 100 - ((angle - maxAngle) * 100 ~/ (maxAngle - minAngle));
  }
  if (accuracy < 0) accuracy = 0;
  if (accuracy > 100) accuracy = 100;
  return accuracy;
}