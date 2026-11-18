package com.educer.pose

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.core.AspectRatio
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.Executors

class PoseCameraViewFactory(
    private val engine: PoseEngine,
    private val activityProvider: () -> Activity?,
) : io.flutter.plugin.platform.PlatformViewFactory(io.flutter.plugin.common.StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val map = args as? Map<*, *>
        val front = map?.get("lens") == "front"
        return PoseCameraView(context, engine, activityProvider, front)
    }
}

class PoseCameraView(
    context: Context,
    private val engine: PoseEngine,
    private val activityProvider: () -> Activity?,
    private val useFrontCamera: Boolean,
) : PlatformView {

    private val root = FrameLayout(context)
    private val previewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        scaleType = PreviewView.ScaleType.FILL_CENTER
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
    }

    private val executor = Executors.newSingleThreadExecutor()
    private var bound = false
    private var cameraProvider: ProcessCameraProvider? = null

    init {
        root.addView(previewView)
        val owner = activityProvider() as? LifecycleOwner
        if (owner != null) {
            val providerFuture = ProcessCameraProvider.getInstance(context)
            providerFuture.addListener({
                bindCamera(owner, providerFuture.get())
            }, ContextCompat.getMainExecutor(context))
        }
    }

    private fun bindCamera(owner: LifecycleOwner, provider: ProcessCameraProvider) {
        if (bound) return
        val selector = if (useFrontCamera) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }

        val preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .build()
        preview.setSurfaceProvider(previewView.surfaceProvider)

        val analysis = ImageAnalysis.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
            .also { it.setAnalyzer(executor, ::analyzeFrame) }

        cameraProvider = provider
        provider.unbindAll()
        provider.bindToLifecycle(owner, selector, preview, analysis)
        bound = true
    }

    private fun analyzeFrame(image: ImageProxy) {
        val ts = SystemClock.uptimeMillis()
        val w = image.width
        val h = image.height
        val rotation = image.imageInfo.rotationDegrees
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        try {
            bitmap.copyPixelsFromBuffer(image.planes[0].buffer)
            val matrix = Matrix().apply {
                postRotate(rotation.toFloat())
                // Keep frames unmirrored; Flutter mirrors landmark dots for front camera.
            }
            val upright = Bitmap.createBitmap(bitmap, 0, 0, w, h, matrix, true)
            engine.detect(upright, ts)
        } finally {
            image.close()
        }
    }

    override fun getView(): FrameLayout = root

    override fun dispose() {
        cameraProvider?.unbindAll()
        cameraProvider = null
        bound = false
        executor.shutdown()
    }
}