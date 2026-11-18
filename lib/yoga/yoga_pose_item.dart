import 'yoga_angle_input.dart';

typedef YogaEvaluateFn = Map<String, dynamic> Function(YogaAngleInput input);

class YogaPoseItem {
  const YogaPoseItem({
    required this.id,
    required this.displayName,
    this.sanskritName,
    required this.evaluate,
  });

  final int id;
  final String displayName;
  final String? sanskritName;
  final YogaEvaluateFn evaluate;
}