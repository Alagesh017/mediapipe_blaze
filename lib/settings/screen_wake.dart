import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display on while yoga practice / camera is active.
class ScreenWake {
  static Future<void> acquire() => WakelockPlus.enable();

  static Future<void> release() => WakelockPlus.disable();
}