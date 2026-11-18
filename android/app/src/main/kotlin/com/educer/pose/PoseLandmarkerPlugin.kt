package com.educer.pose

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

class PoseLandmarkerPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.RequestPermissionsResultListener {

    private val engine = PoseEngine()
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()

    private var appContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var pendingPermission: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "educer/pose").also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, "educer/pose/events").also {
            it.setStreamHandler(this)
        }
        engine.onLandmarks = { data ->
            main.post { sink?.success(data.toList()) }
        }
        engine.onError = { msg -> android.util.Log.e("PoseLandmarker", msg) }
        binding.platformViewRegistry.registerViewFactory(
            "educer/pose_camera_view",
            PoseCameraViewFactory(engine) { activity },
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        engine.dispose()
        worker.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestCameraPermission" -> {
                val act = activity
                    ?: return result.error("NO_ACTIVITY", "No activity", null)
                if (ContextCompat.checkSelfPermission(act, Manifest.permission.CAMERA) ==
                    PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(true)
                } else {
                    pendingPermission = result
                    ActivityCompat.requestPermissions(
                        act,
                        arrayOf(Manifest.permission.CAMERA),
                        REQ_CAMERA,
                    )
                }
            }
            "initialize" -> {
                val ctx = appContext!!
                val androidModel = call.argument<String>("androidModelAsset")
                    ?: PoseEngine.MODEL_ASSET_NAME
                worker.execute {
                    try {
                        engine.initialize(ctx, androidModel)
                        main.post { result.success(null) }
                    } catch (e: Exception) {
                        main.post {
                            result.error(
                                "INIT_FAILED",
                                "Could not load pose model. Rebuild the app.",
                                e.message,
                            )
                        }
                    }
                }
            }
            "start" -> {
                engine.start()
                result.success(null)
            }
            "stop" -> {
                engine.stop()
                result.success(null)
            }
            "dispose" -> {
                engine.dispose()
                result.success(null)
            }
            "processCameraFrame" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.success(null)
                    return
                }
                val format = args["format"] as? String ?: run {
                    result.success(null)
                    return
                }
                val width = (args["width"] as? Number)?.toInt() ?: 0
                val height = (args["height"] as? Number)?.toInt() ?: 0
                val rotation = (args["rotation"] as? Number)?.toInt() ?: 0
                val ts = (args["timestampMs"] as? Number)?.toLong()
                    ?: SystemClock.uptimeMillis()
                worker.execute {
                    try {
                        val bitmap = when (format) {
                            "bgra" -> {
                                val bytes = byteArrayFromPlatform(args["bgra"]) ?: return@execute
                                CameraImageConverter.bgraToBitmap(
                                    width, height, bytes, rotation,
                                )
                            }
                            "yuv420" -> {
                                val y = byteArrayFromPlatform(args["y"]) ?: return@execute
                                val u = byteArrayFromPlatform(args["u"]) ?: return@execute
                                val v = byteArrayFromPlatform(args["v"]) ?: return@execute
                                CameraImageConverter.yuv420ToBitmap(
                                    width, height,
                                    y, u, v,
                                    (args["yRowStride"] as? Number)?.toInt() ?: width,
                                    (args["uRowStride"] as? Number)?.toInt() ?: width / 2,
                                    (args["vRowStride"] as? Number)?.toInt() ?: width / 2,
                                    (args["yPixelStride"] as? Number)?.toInt() ?: 1,
                                    (args["uPixelStride"] as? Number)?.toInt() ?: 1,
                                    (args["vPixelStride"] as? Number)?.toInt() ?: 1,
                                    rotation,
                                )
                            }
                            else -> return@execute
                        }
                        engine.detect(bitmap, ts)
                    } catch (e: Exception) {
                        android.util.Log.w("PoseLandmarker", "frame: ${e.message}")
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQ_CAMERA) return false
        pendingPermission?.success(
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED,
        )
        pendingPermission = null
        return true
    }

    companion object {
        private const val REQ_CAMERA = 7421

        private fun byteArrayFromPlatform(value: Any?): ByteArray? = when (value) {
            is ByteArray -> value
            is java.nio.ByteBuffer -> {
                val dup = value.duplicate()
                val out = ByteArray(dup.remaining())
                dup.get(out)
                out
            }
            else -> null
        }
    }
}