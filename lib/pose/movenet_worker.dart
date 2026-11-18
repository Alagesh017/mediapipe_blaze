import 'dart:isolate';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

const int kInputSize = 192; // MoveNet Lightning input: 192x192

/// One camera frame, sent to the worker isolate (planes are transferred, not copied twice).
class FrameMessage {
  FrameMessage({
    required this.width,
    required this.height,
    required this.rotation,
    required this.isBgra,
    required this.planes,
    required this.rowStrides,
    required this.pixelStrides,
  });

  final int width;
  final int height;
  final int rotation; // clockwise degrees needed to make the frame upright
  final bool isBgra;
  final List<TransferableTypedData> planes;
  final List<int> rowStrides;
  final List<int> pixelStrides;
}

/// Owns a background isolate that runs preprocessing + TFLite inference.
class MoveNetWorker {
  MoveNetWorker._(this._isolate, this._commands, this._results);

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _results;

  /// Receives Float32List of 52 values: 17 x (y, x, score) followed by inference ms.
  void Function(Float32List)? onResult;

  static Future<MoveNetWorker> start(Uint8List modelBytes) async {
    final ready = ReceivePort();
    final results = ReceivePort();
    final isolate = await Isolate.spawn(
      _entry,
      <Object>[results.sendPort, ready.sendPort, modelBytes],
    );
    final first = await ready.first;
    if (first is! SendPort) {
      isolate.kill(priority: Isolate.immediate);
      results.close();
      throw StateError('MoveNet init failed: $first');
    }
    final worker = MoveNetWorker._(isolate, first, results);
    results.listen((m) {
      if (m is Float32List) worker.onResult?.call(m);
    });
    return worker;
  }

  void send(FrameMessage m) => _commands.send(m);

  void dispose() {
    _commands.send('close');
    _results.close();
    _isolate.kill(priority: Isolate.beforeNextEvent);
  }
}

// ---------------------------------------------------------------- isolate side

void _entry(List<Object> init) {
  final resultPort = init[0] as SendPort;
  final readyPort = init[1] as SendPort;
  final modelBytes = init[2] as Uint8List;

  late Interpreter interpreter;
  try {
    interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: InterpreterOptions()..threads = 2,
    );
  } catch (e) {
    readyPort.send('$e');
    return;
  }

  final type = interpreter.getInputTensor(0).type.toString().toLowerCase();
  final isUint8 = type.contains('uint8');
  final isInt32 = type.contains('int32');
  final isFloat = type.contains('float32');
  if (!isUint8 && !isInt32 && !isFloat) {
    readyPort.send('Unsupported input tensor type: $type');
    return;
  }

  final rgb = Uint8List(kInputSize * kInputSize * 3);
  final i32 = isInt32 ? Int32List(rgb.length) : null;
  final f32 = isFloat ? Float32List(rgb.length) : null;
  final Uint8List inputBytes = isUint8
      ? rgb
      : (isInt32 ? i32!.buffer.asUint8List() : f32!.buffer.asUint8List());

  // [1][1][17][3] -> (y, x, score)
  final output = List.generate(
    1,
    (_) => List.generate(1, (_) => List.generate(17, (_) => List.filled(3, 0.0))),
  );

  final commands = ReceivePort();
  readyPort.send(commands.sendPort);

  final sw = Stopwatch();
  commands.listen((msg) {
    if (msg == 'close') {
      interpreter.close();
      commands.close();
      return;
    }
    if (msg is! FrameMessage) return;
    try {
      _fillRgb(msg, rgb);
      if (isInt32) {
        for (var i = 0; i < rgb.length; i++) {
          i32![i] = rgb[i];
        }
      } else if (isFloat) {
        for (var i = 0; i < rgb.length; i++) {
          f32![i] = rgb[i].toDouble();
        }
      }
      sw
        ..reset()
        ..start();
      interpreter.run(inputBytes, output);
      sw.stop();

      final out = Float32List(52);
      final kp = output[0][0];
      for (var k = 0; k < 17; k++) {
        out[k * 3] = kp[k][0].toDouble();
        out[k * 3 + 1] = kp[k][1].toDouble();
        out[k * 3 + 2] = kp[k][2].toDouble();
      }
      out[51] = sw.elapsedMicroseconds / 1000.0;
      resultPort.send(out);
    } catch (_) {
      resultPort.send(Float32List(52)); // all zero => treated as "no person"
    }
  });
}

/// Rotate + resize (nearest neighbour) + colour-convert in ONE pass straight into
/// the 192x192 RGB buffer. No full-frame RGB image is ever created.
void _fillRgb(FrameMessage m, Uint8List rgb) {
  final w = m.width, h = m.height, r = m.rotation;
  final uw = (r == 90 || r == 270) ? h : w; // upright width
  final uh = (r == 90 || r == 270) ? w : h; // upright height

  final p0 = m.planes[0].materialize().asUint8List();
  final p1 = m.isBgra ? null : m.planes[1].materialize().asUint8List();
  final p2 = m.isBgra ? null : m.planes[2].materialize().asUint8List();
  final rs0 = m.rowStrides[0];
  final rs1 = m.isBgra ? 0 : m.rowStrides[1];
  final ps1 = m.isBgra ? 0 : m.pixelStrides[1];

  var o = 0;
  for (var oy = 0; oy < kInputSize; oy++) {
    final v = ((oy + 0.5) * uh / kInputSize).floor().clamp(0, uh - 1);
    for (var ox = 0; ox < kInputSize; ox++) {
      final u = ((ox + 0.5) * uw / kInputSize).floor().clamp(0, uw - 1);

      int sx, sy; // source (sensor) coordinates
      switch (r) {
        case 90:
          sx = v;
          sy = h - 1 - u;
          break;
        case 180:
          sx = w - 1 - u;
          sy = h - 1 - v;
          break;
        case 270:
          sx = w - 1 - v;
          sy = u;
          break;
        default:
          sx = u;
          sy = v;
      }

      int rr, gg, bb;
      if (m.isBgra) {
        final idx = sy * rs0 + sx * 4;
        bb = p0[idx];
        gg = p0[idx + 1];
        rr = p0[idx + 2];
      } else {
        final y = p0[sy * rs0 + sx];
        final uvIdx = (sy >> 1) * rs1 + (sx >> 1) * ps1;
        final uu = p1![uvIdx] - 128;
        final vv = p2![uvIdx] - 128;
        rr = (y + 1.402 * vv).round();
        gg = (y - 0.344136 * uu - 0.714136 * vv).round();
        bb = (y + 1.772 * uu).round();
      }
      rgb[o++] = rr < 0 ? 0 : (rr > 255 ? 255 : rr);
      rgb[o++] = gg < 0 ? 0 : (gg > 255 ? 255 : gg);
      rgb[o++] = bb < 0 ? 0 : (bb > 255 ? 255 : bb);
    }
  }
}
