import 'dart:typed_data';
import 'package:watermark_unique/watermark_bridge.dart';
import 'image_format.dart';

/// Class for adding watermarks to images.
///
/// This class provides high-level methods for adding watermarks to images,
/// abstracting the implementation details.
class WatermarkUnique {
  Future<String?> addTextWatermark({
    required String filePath,
    required String text,
    required int x,
    required int y,
    required int textSize,
    required int color,
    int? backgroundTextColor,
    required int quality,
    int? backgroundTextPaddingTop,
    int? backgroundTextPaddingBottom,
    int? backgroundTextPaddingLeft,
    int? backgroundTextPaddingRight,
    required ImageFormat imageFormat,
  }) {
    return WatermarkBridge.instance.addTextWatermark(
      filePath,
      text,
      x,
      y,
      textSize,
      color,
      backgroundTextColor,
      quality,
      backgroundTextPaddingTop,
      backgroundTextPaddingBottom,
      backgroundTextPaddingLeft,
      backgroundTextPaddingRight,
      imageFormat,
    );
  }

  Future<String?> addImageWatermark({
    required String filePath,
    required String watermarkImagePath,
    required int x,
    required int y,
    required int watermarkWidth,
    required int watermarkHeight,
    required int quality,
    required ImageFormat imageFormat,
  }) {
    return WatermarkBridge.instance.addImageWatermark(
      filePath,
      watermarkImagePath,
      x,
      y,
      watermarkWidth,
      watermarkHeight,
      quality,
      imageFormat,
    );
  }

  Future<Uint8List?> addTextWatermarkUint8List({
    required Uint8List filePath,
    required String text,
    required int x,
    required int y,
    required int textSize,
    required int color,
    int? backgroundTextColor,
    int? backgroundTextPaddingTop,
    int? backgroundTextPaddingBottom,
    int? backgroundTextPaddingLeft,
    int? backgroundTextPaddingRight,
  }) {
    return WatermarkBridge.instance.addTextWatermarkUint8List(
      filePath,
      text,
      x,
      y,
      textSize,
      color,
      backgroundTextColor,
      backgroundTextPaddingTop,
      backgroundTextPaddingBottom,
      backgroundTextPaddingLeft,
      backgroundTextPaddingRight,
    );
  }

  Future<Uint8List?> addImageWatermarkUint8List({
    required Uint8List filePath,
    required Uint8List watermarkImagePath,
    required int x,
    required int y,
    required int watermarkWidth,
    required int watermarkHeight,
  }) {
    return WatermarkBridge.instance.addImageWatermarkUint8List(
      filePath,
      watermarkImagePath,
      x,
      y,
      watermarkWidth,
      watermarkHeight,
    );
  }
}
