package com.educer.pose

import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream

/** Converts Flutter [camera] YUV420_888 planes to an upright ARGB bitmap. */
object CameraImageConverter {

    fun yuv420ToBitmap(
        width: Int,
        height: Int,
        yBytes: ByteArray,
        uBytes: ByteArray,
        vBytes: ByteArray,
        yRowStride: Int,
        uRowStride: Int,
        vRowStride: Int,
        yPixelStride: Int,
        uPixelStride: Int,
        vPixelStride: Int,
        rotationDegrees: Int,
    ): Bitmap {
        val nv21 = yuv420ToNv21(
            width, height,
            yBytes, uBytes, vBytes,
            yRowStride, uRowStride, vRowStride,
            yPixelStride, uPixelStride, vPixelStride,
        )
        val yuv = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val jpeg = ByteArrayOutputStream()
        yuv.compressToJpeg(Rect(0, 0, width, height), 92, jpeg)
        val raw = jpeg.toByteArray()
        var bitmap = android.graphics.BitmapFactory.decodeByteArray(raw, 0, raw.size)
            ?: throw IllegalStateException("YUV decode failed")

        if (rotationDegrees != 0) {
            val matrix = android.graphics.Matrix().apply {
                postRotate(rotationDegrees.toFloat())
            }
            bitmap = Bitmap.createBitmap(bitmap, 0,  0, bitmap.width, bitmap.height, matrix, true)
        }
        return bitmap
    }

  fun bgraToBitmap(
      width: Int,
      height: Int,
      bytes: ByteArray,
      rotationDegrees: Int,
  ): Bitmap {
      val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
      bitmap.copyPixelsFromBuffer(java.nio.ByteBuffer.wrap(bytes))
      if (rotationDegrees == 0) return bitmap
      val matrix = android.graphics.Matrix().apply {
          postRotate(rotationDegrees.toFloat())
      }
      return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
  }

    private fun yuv420ToNv21(
        width: Int,
        height: Int,
        yBytes: ByteArray,
        uBytes: ByteArray,
        vBytes: ByteArray,
        yRowStride: Int,
        uRowStride: Int,
        vRowStride: Int,
        yPixelStride: Int,
        uPixelStride: Int,
        vPixelStride: Int,
    ): ByteArray {
        val nv21 = ByteArray(width * height + width * height / 2)
        var yIndex = 0
        for (row in 0 until height) {
            var col = 0
            while (col < width) {
                nv21[yIndex++] = yBytes[row * yRowStride + col * yPixelStride]
                col++
            }
        }
        val chromaHeight = height / 2
        val chromaWidth = width / 2
        var uvIndex = width * height
        for (row in 0 until chromaHeight) {
            var col = 0
            while (col < chromaWidth) {
                val u = uBytes[row * uRowStride + col * uPixelStride]
                val v = vBytes[row * vRowStride + col * vPixelStride]
                nv21[uvIndex++] = v
                nv21[uvIndex++] = u
                col++
            }
        }
        return nv21
    }
}