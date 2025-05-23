package com.unknown.engineer.unique.watermark.watermark_unique

import android.media.ExifInterface
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*
import android.graphics.*
import java.io.File
import java.io.FileOutputStream
class WatermarkImage : MethodChannel.MethodCallHandler {
    private var context: Context? = null
    companion object {
        fun registerWith(messenger: BinaryMessenger, context: Context): MethodChannel {
            val channel = MethodChannel(messenger, "WatermarkImage")
            val plugin = WatermarkImage()
            plugin.setContext(context)
            channel.setMethodCallHandler(plugin)
            return  channel
        }
    }

    private fun setContext(context: Context) {
        this.context = context
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addTextWatermark" -> {
                val filePath = call.argument<String?>("filePath")
                val text = call.argument<String?>("text")
                val x = call.argument<Int?>("x")
                val y = call.argument<Int?>("y")
                val textSize = call.argument<Int>("textSize")
                val color = call.argument<Number>("color")?.toInt()
                val backgroundTextColor = call.argument<Number>("backgroundTextColor")?.toInt()
                val quality = call.argument<Int>("quality")
                val imageFormat = call.argument<String>("imageFormat")
                val backgroundTextPaddingTop =
                    call.argument<Int?>("backgroundTextPaddingTop")?.toFloat()
                val backgroundTextPaddingBottom =
                    call.argument<Int?>("backgroundTextPaddingBottom")?.toFloat()
                val backgroundTextPaddingLeft =
                    call.argument<Int?>("backgroundTextPaddingLeft")?.toFloat()
                val backgroundTextPaddingRight =
                    call.argument<Int?>("backgroundTextPaddingRight")?.toFloat()
                val isNeedRotate = call.argument<Boolean?>("isNeedRotate") ?: true

                if (text != null && filePath != null && x != null && y != null && textSize != null && color != null && quality != null && imageFormat != null) {
                    addTextWatermark(
                        text,
                        filePath,
                        x.toFloat(),
                        y.toFloat(),
                        textSize!!.toFloat(),
                        color!!.toInt(),
                        backgroundTextColor?.toInt(),
                        quality!!,
                        backgroundTextPaddingTop,
                        backgroundTextPaddingBottom,
                        backgroundTextPaddingLeft,
                        backgroundTextPaddingRight,
                        imageFormat!!,
                        isNeedRotate,
                        result
                    )
                } else {
                    result.error("ARGUMENT_ERROR", "Missing arguments", null)
                }
            }

            "addImageWatermark" -> {
                val filePath = call.argument<String?>("filePath")
                val watermarkImagePath = call.argument<String?>("watermarkImagePath")
                val x = call.argument<Int?>("x")
                val y = call.argument<Int?>("y")
                val watermarkWidth = call.argument<Int?>("watermarkWidth")
                val watermarkHeight = call.argument<Int?>("watermarkHeight")
                val quality = call.argument<Int>("quality")
                val imageFormat = call.argument<String>("imageFormat")

                if (filePath != null && watermarkImagePath != null && x != null && y != null && quality != null && imageFormat != null && watermarkWidth != null && watermarkHeight != null) {
                    addImageWatermark(
                        filePath,
                        watermarkImagePath,
                        x.toFloat(),
                        y.toFloat(),
                        watermarkWidth,
                        watermarkHeight,
                        quality!!,
                        imageFormat!!,
                        result
                    )
                } else {
                    result.error("ARGUMENT_ERROR", "Missing arguments", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun addTextWatermark(
        text: String,
        filePath: String,
        x: Float,
        y: Float,
        textWatermarkSize: Float,
        colorWatermark: Int,
        backgroundTextColor: Int?,
        quality: Int,
        backgroundTextPaddingTop: Float?,
        backgroundTextPaddingBottom: Float?,
        backgroundTextPaddingLeft: Float?,
        backgroundTextPaddingRight: Float?,
        imageFormat: String,
        isNeedRotate: Boolean,
        result: MethodChannel.Result
    ) {
        var bitmap = BitmapFactory.decodeFile(filePath)
        if(isNeedRotate) {
            bitmap = rotateImageIfRequired(bitmap, filePath)
        }
        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(mutableBitmap)
        val finalFormat = if (imageFormat.uppercase() == Bitmap.CompressFormat.JPEG.name) {
            Bitmap.CompressFormat.JPEG
        } else {
            Bitmap.CompressFormat.PNG
        }

        val textPaint = Paint().apply {
            color = colorWatermark
            textSize = textWatermarkSize
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        val maxTextWidth = mutableBitmap.width - (backgroundTextPaddingLeft ?: 0F) - (backgroundTextPaddingRight ?: 0F)

        fun wrapText(text: String, maxWidth: Float): List<String> {
            val wrappedLines = mutableListOf<String>()
            val paragraphs = text.split("\n")

            for (paragraph in paragraphs) {
                val words = paragraph.split(" ")
                var line = ""

                for (word in words) {
                    val testLine = if (line.isEmpty()) word else "$line $word"
                    val textWidth = (textPaint.measureText(testLine) + 50)

                    if (textWidth > maxWidth) {
                        if (line.isNotEmpty()) {
                            wrappedLines.add(line)
                        }
                        line = word
                    } else {
                        line = testLine
                    }
                }

                if (line.isNotEmpty()) {
                    wrappedLines.add(line)
                }

                if (paragraph != paragraphs.last()) {
                    wrappedLines.add("")
                }
            }

            return wrappedLines
        }

        val lines = wrapText(text, maxTextWidth)
        val lineHeight = textPaint.descent() - textPaint.ascent()
        val baseY = y

        backgroundTextColor?.let { backgroundColor ->
            val backgroundPaint = Paint().apply {
                this.color = backgroundColor
                style = Paint.Style.FILL
            }
            val textWidth = lines.maxOfOrNull { textPaint.measureText(it) } ?: 0f
            val rect = RectF(
                x - (backgroundTextPaddingLeft ?: 0F),
                baseY + textPaint.ascent() - (backgroundTextPaddingTop ?: 0F),
                x + textWidth + (backgroundTextPaddingRight ?: 0F),
                baseY + (lineHeight * lines.size) + (backgroundTextPaddingBottom ?: 0F)
            )
            canvas.drawRect(rect, backgroundPaint)
        }

        var currentY = baseY
        for (line in lines) {
            canvas.drawText(line, x, currentY, textPaint)
            currentY += lineHeight
        }

        val file = File(filePath)

        try {
            val fileOutputStream = FileOutputStream(file)
            mutableBitmap.compress(finalFormat, quality, fileOutputStream)
            fileOutputStream.close()

            val fileName = file.name
            val fileNameWithoutExtension = fileName.substringBeforeLast('.')
            val newFileName = "$fileNameWithoutExtension.${finalFormat.name.lowercase()}"
            val newFilePath = file.parent!! + File.separator + newFileName

            val newFile = File(newFilePath)
            file.renameTo(newFile)

            result.success(newFile.absolutePath)
        } catch (e: Exception) {
            result.error("WRITE_ERROR", "Error writing file", null)
            e.printStackTrace()
        }
    }

    private fun addImageWatermark(
        filePath: String,
        watermarkImagePath: String,
        x: Float,
        y: Float,
        watermarkWidth: Int,
        watermarkHeight: Int,
        quality: Int,
        imageFormat: String,
        result: MethodChannel.Result
    ) {
        val bitmap = BitmapFactory.decodeFile(filePath)
        val watermarkBitmap = BitmapFactory.decodeFile(watermarkImagePath)

        val mutableBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(mutableBitmap)
        val finalFormat = if (imageFormat.uppercase() == Bitmap.CompressFormat.JPEG.name) {
            Bitmap.CompressFormat.JPEG
        } else {
            Bitmap.CompressFormat.PNG
        }

        val scaledWatermark =
            Bitmap.createScaledBitmap(watermarkBitmap, watermarkWidth, watermarkHeight, true)
        canvas.drawBitmap(scaledWatermark, x, y, null)

        val file = File(filePath)

        try {
            val fileOutputStream = FileOutputStream(file)
            mutableBitmap.compress(finalFormat, quality, fileOutputStream)
            fileOutputStream.close()

            val fileName = file.name
            val fileNameWithoutExtension = fileName.substringBeforeLast('.')
            val newFileName = "$fileNameWithoutExtension.${finalFormat.name.lowercase()}"
            val newFilePath = file.parent!! + File.separator + newFileName

            val newFile = File(newFilePath)
            file.renameTo(newFile)

            result.success(newFile.absolutePath)
        } catch (e: Exception) {
            result.error("WRITE_ERROR", "Error writing file", null)
            e.printStackTrace()
        }
    }

    private fun rotateImageIfRequired(img: Bitmap, filePath: String): Bitmap {
        val exif = ExifInterface(filePath)
        val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        exif.saveAttributes()

        return when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> rotateImage(img, 90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> rotateImage(img, 180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> rotateImage(img, 270f)
            else -> img
        }
    }

    private fun rotateImage(img: Bitmap, degree: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degree)
        return Bitmap.createBitmap(img, 0, 0, img.width, img.height, matrix, true)
    }
}