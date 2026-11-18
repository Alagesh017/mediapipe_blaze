import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFrontKey = 'pref_use_front_camera';
const _kCameraChosenKey = 'pref_camera_chosen';

/// Saved default camera (front vs rear). User picks once, can change on home or in practice.
class CameraPreference {
  static Future<bool> loadUseFrontCamera() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFrontKey) ?? true;
  }

  static Future<bool> hasChosenCamera() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCameraChosenKey) ?? false;
  }

  static Future<void> saveUseFrontCamera(bool useFront) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFrontKey, useFront);
    await prefs.setBool(_kCameraChosenKey, true);
  }
}

Future<bool?> showCameraPreferenceDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Choose your camera'),
      content: const Text(
        'Pick which camera to use for yoga practice. '
        'You can switch anytime from the camera button on the practice screen.',
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.camera_front_outlined),
          label: const Text('Front (selfie)'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.camera_rear_outlined),
          label: const Text('Rear'),
        ),
      ],
    ),
  );
}