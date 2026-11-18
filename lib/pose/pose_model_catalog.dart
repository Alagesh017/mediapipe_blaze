enum PoseModelBackend { mediaPipe, moveNet }

/// Models under [assets/modal/] for comparison testing.
class PoseModelOption {
  const PoseModelOption({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.backend,
    this.androidBundledName,
  });

  final String id;
  final String label;
  final String assetPath;
  final PoseModelBackend backend;

  /// Basename copied into `android/app/src/main/assets/` at build time.
  final String? androidBundledName;

  bool get isMediaPipe => backend == PoseModelBackend.mediaPipe;
}

const List<PoseModelOption> kPoseModelCatalog = [
  PoseModelOption(
    id: 'blaze_lite',
    label: 'BlazePose Lite (.task)',
    assetPath: 'assets/modal/pose_landmarker_lite.task',
    backend: PoseModelBackend.mediaPipe,
    androidBundledName: 'pose_landmarker_lite.task',
  ),
  PoseModelOption(
    id: 'blaze_full',
    label: 'BlazePose Full (.task)',
    assetPath: 'assets/modal/pose_landmarker_full.task',
    backend: PoseModelBackend.mediaPipe,
    androidBundledName: 'pose_landmarker_full.task',
  ),
  PoseModelOption(
    id: 'movenet_lightning',
    label: 'MoveNet Lightning (.tflite)',
    assetPath: 'assets/modal/movenet_lightning.tflite',
    backend: PoseModelBackend.moveNet,
  ),
  PoseModelOption(
    id: 'movenet_thunder',
    label: 'MoveNet Thunder (.tflite)',
    assetPath: 'assets/modal/movenet_thunder.tflite',
    backend: PoseModelBackend.moveNet,
  ),
];

PoseModelOption kDefaultPoseModel = kPoseModelCatalog.first;