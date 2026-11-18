import 'poses/bow_pose_logic.dart';
import 'poses/chair_pose_logic.dart';
import 'poses/half_moon_pose_logic.dart';
import 'poses/one_legged_pose_logic.dart';
import 'poses/three_legged_dog_logic.dart';
import 'poses/tree_pose_logic.dart';
import 'poses/triangle_pose_logic.dart';
import 'poses/warrior_pose_logic.dart';
import 'poses/wheel_pose_logic.dart';
import 'yoga_pose_item.dart';

/// All poses from [code.txt]. Add new entries here when you send more logic.
final List<YogaPoseItem> kYogaPoseCatalog = [
  YogaPoseItem(
    id: 5,
    displayName: 'Warrior Pose',
    sanskritName: 'Virabhadrasana',
    evaluate: evaluateWarriorPose,
  ),
  YogaPoseItem(
    id: 6,
    displayName: 'Half Moon Pose',
    sanskritName: 'Ardha Chandrasana',
    evaluate: evaluateHalfMoonPose,
  ),
  YogaPoseItem(
    id: 7,
    displayName: 'Chair Pose',
    sanskritName: 'Utkatasana',
    evaluate: evaluateChairPose,
  ),
  YogaPoseItem(
    id: 8,
    displayName: 'One-Legged Pose',
    evaluate: evaluateOneLeggedPose,
  ),
  YogaPoseItem(
    id: 9,
    displayName: 'Triangle Pose',
    sanskritName: 'Trikonasana',
    evaluate: evaluateTrianglePose,
  ),
  YogaPoseItem(
    id: 11,
    displayName: 'Three-Legged Downward Dog',
    evaluate: evaluateThreeLeggedDogPose,
  ),
  YogaPoseItem(
    id: 12,
    displayName: 'Bow Pose',
    evaluate: evaluateBowPose,
  ),
  YogaPoseItem(
    id: 13,
    displayName: 'Wheel Pose',
    sanskritName: 'Chakrasana',
    evaluate: evaluateWheelPose,
  ),
  YogaPoseItem(
    id: 14,
    displayName: 'Tree Pose',
    evaluate: evaluateTreePose,
  ),
];

YogaPoseItem yogaPoseById(int id) =>
    kYogaPoseCatalog.firstWhere((p) => p.id == id);