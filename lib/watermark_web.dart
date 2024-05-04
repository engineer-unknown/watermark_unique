import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:watermark_unique/watermark_bridge.dart';
import 'dart:ui' as ui;

/// A web implementation of the for adding watermarks to images.
///
/// This class provides high-level methods for adding watermarks to images,
/// abstracting the implementation details.
class WatermarkWeb extends WatermarkBridge {
  /// Constructs a WatermarkWeb
  WatermarkWeb();

  static void registerWith(Registrar registrar) {
    WatermarkBridge.instance = WatermarkWeb();
  }

  @override
  Future<Uint8List?> addTextWatermarkUint8List(
    Uint8List filePath,
    String text,
    int x,
    int y,
    int textSize,
    int color,
    int? backgroundTextColor,
    int? backgroundTextPaddingTop,
    int? backgroundTextPaddingBottom,
    int? backgroundTextPaddingLeft,
    int? backgroundTextPaddingRight,
  ) async {
    final ui.Image image = await decodeImageFromList(filePath);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create a transparent background
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bgPaint,
    );

    canvas.drawImage(image, Offset.zero, Paint());

    final textStyle = ui.TextStyle(
      color: Color(color),
      fontSize: textSize.toDouble(),
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.start,
      fontSize: textSize.toDouble(),
    ))
      ..pushStyle(textStyle)
      ..addText(
        text,
      );

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: image.width.toDouble()));

    if (backgroundTextColor != null) {
      final bgPaintText = Paint()..color = Color(backgroundTextColor);
      final backgroundRect = Rect.fromLTRB(
        x.toDouble() - (backgroundTextPaddingLeft ?? 0),
        y.toDouble() - (backgroundTextPaddingTop ?? 0),
        x + paragraph.width + (backgroundTextPaddingRight ?? 0),
        y + paragraph.height + (backgroundTextPaddingBottom ?? 0),
      );
      canvas.drawRect(backgroundRect, bgPaintText);
    }

    canvas.drawParagraph(
      paragraph,
      Offset(x.toDouble(), y.toDouble()),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Future<Uint8List?> addImageWatermarkUint8List(
    Uint8List filePath,
    Uint8List watermarkImagePath,
    int x,
    int y,
    int watermarkWidth,
    int watermarkHeight,
  ) async {
    // Decode the original image
    final originalImage = await ui
        .instantiateImageCodec(filePath)
        .then((codec) => codec.getNextFrame())
        .then((frame) => frame.image);

    // Decode the watermark image
    final watermarkImage = await ui
        .instantiateImageCodec(watermarkImagePath)
        .then((codec) => codec.getNextFrame())
        .then((frame) => frame.image);

    // Create a recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Draw the watermark image
    canvas.drawImageRect(
      watermarkImage,
      Rect.fromLTRB(0, 0, watermarkImage.width.toDouble(),
          watermarkImage.height.toDouble()),
      Rect.fromLTRB(x.toDouble(), y.toDouble(), (x + watermarkWidth).toDouble(),
          (y + watermarkHeight).toDouble()),
      Paint(),
    );

    // Convert the canvas to image
    final picture = recorder.endRecording();
    final img =
        await picture.toImage(originalImage.width, originalImage.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
