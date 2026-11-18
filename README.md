# MoveNet Lightning + tflite_flutter

## 1. DELETE the old MediaPipe stuff (important, or the build breaks)
- lib/pose/pose_landmark.dart
- lib/pose/pose_landmarker_service.dart
- lib/pose/pose_landmark_painter.dart
- lib/pose/pose_camera_view.dart
- android/app/src/main/kotlin/com/educer/   (whole folder)
- ios/Runner/PoseEngine.swift, PoseCameraView.swift, PoseLandmarkerPlugin.swift
  -> delete them INSIDE XCODE too (right-click > Delete > Move to Trash)
- assets/modal/pose_landmarker_full.task   (optional, saves app size)

## 2. COPY these files (same relative paths)
pubspec.yaml
lib/main.dart
lib/pose/pose_keypoint.dart
lib/pose/movenet_worker.dart
lib/pose/movenet_detector.dart
lib/pose/keypoint_painter.dart
lib/pose/pose_camera_screen.dart
android/app/build.gradle
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/example/mediapipe_lbaze/MainActivity.kt
ios/Podfile
ios/Runner/AppDelegate.swift
ios/Runner/Info.plist

## 3. RUN
flutter clean && flutter pub get
cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd ..
flutter run --release     (physical device)
