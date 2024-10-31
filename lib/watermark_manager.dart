import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:watermark_unique/watermark_bridge.dart';
import 'image_format.dart';

/// Class responsible for managing watermarks.
///
/// This class implements the [WatermarkBridge] interface and provides methods
/// for adding watermarks to images.
class WatermarkManager extends WatermarkBridge {
  @visibleForTesting
  final watermarkImageChannel = const MethodChannel('WatermarkImage');

  @override
  Future<String?> addTextWatermark(
    String filePath,
    String text,
    int x,
    int y,
    int textSize,
    Color color,
    bool isNeedRotateToPortrait,
    Color? backgroundTextColor,
    int quality,
    int? backgroundTextPaddingTop,
    int? backgroundTextPaddingBottom,
    int? backgroundTextPaddingLeft,
    int? backgroundTextPaddingRight,
    ImageFormat imageFormat,
  ) async {
    final result = await watermarkImageChannel.invokeMethod<String?>(
      'addTextWatermark',
      {
        'text': text,
        'filePath': filePath,
        'x': x,
        'y': y,
        'textSize': textSize,
        'color': color.value.toInt(),
        'backgroundTextColor': backgroundTextColor?.value.toInt(),
        'quality': quality,
        'backgroundTextPaddingTop': backgroundTextPaddingTop,
        'backgroundTextPaddingBottom': backgroundTextPaddingBottom,
        'backgroundTextPaddingLeft': backgroundTextPaddingLeft,
        'backgroundTextPaddingRight': backgroundTextPaddingRight,
        'isNeedRotate': isNeedRotateToPortrait,
        'imageFormat': imageFormat.name,
      },
    );
    return result;
  }

  @override
  Future<String?> addImageWatermark(
    String filePath,
    String watermarkImagePath,
    int x,
    int y,
    int watermarkWidth,
    int watermarkHeight,
    int quality,
    ImageFormat imageFormat,
  ) async {
    final result = await watermarkImageChannel.invokeMethod<String?>(
      'addImageWatermark',
      {
        'filePath': filePath,
        'watermarkImagePath': watermarkImagePath,
        'x': x,
        'y': y,
        'watermarkWidth': watermarkWidth,
        'watermarkHeight': watermarkHeight,
        'quality': quality,
        'imageFormat': imageFormat.name,
      },
    );
    return result;
  }

  @override
  Future<Uint8List?> addTextWatermarkUint8List(
    String filePath,
    Uint8List? bytes,
    String text,
    int x,
    int y,
    int textSize,
    bool isNeedRotateToPortrait,
    Color color,
    Color? backgroundTextColor,
    int? backgroundTextPaddingTop,
    int? backgroundTextPaddingBottom,
    int? backgroundTextPaddingLeft,
    int? backgroundTextPaddingRight,
  ) async {
    final result = await watermarkImageChannel.invokeMethod<String?>(
      'addTextWatermark',
      {
        'text': text,
        'filePath': filePath,
        'x': x,
        'y': y,
        'textSize': textSize,
        'color': color.value.toInt(),
        'backgroundTextColor': backgroundTextColor?.value.toInt(),
        'quality': 100,
        'backgroundTextPaddingTop': backgroundTextPaddingTop,
        'backgroundTextPaddingBottom': backgroundTextPaddingBottom,
        'backgroundTextPaddingLeft': backgroundTextPaddingLeft,
        'backgroundTextPaddingRight': backgroundTextPaddingRight,
        'isNeedRotate': isNeedRotateToPortrait,
        'imageFormat': ImageFormat.png.name,
      },
    );
    if (result != null) {
      final resultBytes = await File(result).readAsBytes();
      return resultBytes;
    } else {
      return null;
    }
  }

  @override
  Future<Uint8List?> addImageWatermarkUint8List(
    String filePath,
    Uint8List? bytes,
    Uint8List watermarkImagePath,
    int x,
    int y,
    int watermarkWidth,
    int watermarkHeight,
  ) async {
    final result = await watermarkImageChannel.invokeMethod<String?>(
      'addImageWatermark',
      {
        'filePath': filePath,
        'watermarkImagePath': watermarkImagePath,
        'x': x,
        'y': y,
        'watermarkWidth': watermarkWidth,
        'watermarkHeight': watermarkHeight,
        'quality': 100,
        'imageFormat': ImageFormat.png.name,
      },
    );
    if (result != null) {
      final resultBytes = await File(result).readAsBytes();
      return resultBytes;
    } else {
      return null;
    }
  }
}
