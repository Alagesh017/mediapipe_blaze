package com.educer.pose

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

class PoseEngine {
    private var landmarker: PoseLandmarker? = null
    private var loadedModelName: String? = null

    @Volatile
    private var running = false

    @Volatile
    private var inFlight = false

    private var lastTimestampMs = -1L

    var onLandmarks: ((DoubleArray) -> Unit)? = null
    var onError: ((String) -> Unit)? = null

    /** Model must live in `android/app/src/main/assets/` (copied at build time). */
    fun initialize(context: Context, modelAssetName: String = MODEL_ASSET_NAME) {
        if (landmarker != null && loadedModelName == modelAssetName) return
        landmarker?.close()
        landmarker = null
        loadedModelName = modelAssetName
        landmarker = buildLandmarker(context, modelAssetName, Delegate.GPU)
            ?: buildLandmarker(context, modelAssetName, Delegate.CPU)
            ?: throw IllegalStateException("Pose model failed to load (GPU and CPU).")
    }

    private fun buildLandmarker(
        context: Context,
        modelAssetName: String,
        delegate: Delegate,
    ): PoseLandmarker? {
        return try {
            val base = BaseOptions.builder()
                .setModelAssetPath(modelAssetName)
                .setDelegate(delegate)
                .build()
            val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(base)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setNumPoses(1)
                .setMinPoseDetectionConfidence(0.5f)
                .setMinPosePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setResultListener { result, _ -> handleResult(result) }
                .setErrorListener { e ->
                    inFlight = false
                    onError?.invoke(e.message ?: "PoseLandmarker error")
                }
                .build()
            PoseLandmarker.createFromOptions(context, options).also {
                Log.i(TAG, "Pose landmarker ready (${delegate.name})")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Pose init failed with ${delegate.name}: ${e.message}")
            null
        }
    }

    fun start() {
        running = true
        inFlight = false
    }

    fun stop() {
        running = false
        inFlight = false
        onLandmarks?.invoke(doubleArrayOf())
    }

    fun dispose() {
        running = false
        landmarker?.close()
        landmarker = null
        loadedModelName = null
    }

    fun detect(bitmap: Bitmap, timestampMs: Long) {
        if (!running || landmarker == null || inFlight) return
        if (timestampMs <= lastTimestampMs) return
        lastTimestampMs = timestampMs
        inFlight = true
        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            landmarker?.detectAsync(mpImage, timestampMs)
        } catch (e: Exception) {
            inFlight = false
            onError?.invoke(e.message ?: "detect failed")
        }
    }

    private fun handleResult(result: PoseLandmarkerResult) {
        inFlight = false
        if (!running) return
        val poses = result.landmarks()
        if (poses.isEmpty() || poses[0].isEmpty()) {
            onLandmarks?.invoke(doubleArrayOf())
            return
        }
        val pose = poses[0]
        val out = DoubleArray(pose.size * 5)
        var i = 0
        for (lm in pose) {
            out[i++] = lm.x().toDouble()
            out[i++] = lm.y().toDouble()
            out[i++] = lm.z().toDouble()
            out[i++] = (lm.visibility().orElse(0f)).toDouble()
            out[i++] = (lm.presence().orElse(0f)).toDouble()
        }
        onLandmarks?.invoke(out)
    }

    companion object {
        private const val TAG = "PoseEngine"
        const val MODEL_ASSET_NAME = "pose_landmarker_lite.task"
    }
}