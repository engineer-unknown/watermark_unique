import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watermark_unique/image_format.dart';
import 'package:watermark_unique/watermark_unique.dart';

class ExampleWidget extends StatefulWidget {
  const ExampleWidget({
    super.key,
  });

  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  final _watermarkPlugin = WatermarkUnique();
  File? photo;
  String? photoUint8List;
  Uint8List? watermarkUint8List;
  File? watermark;
  File? finalFile;
  Uint8List? finalUint8List;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
          top: 24,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _takeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 4,
                  ),
                  child: const Text(
                    'Take image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    'Image path: ${photo?.path}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _takeWatermarkImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 4,
                  ),
                  child: const Text(
                    'Take watermark image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    'Watermark image path: ${watermark?.path}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addImageTextWatermark,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 4,
                  ),
                  child: const Text(
                    'Add text watermark to photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addTextWatermarkUint8List,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 4,
                  ),
                  child: const Text(
                    'Add text watermark to photo Uint8List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _addWatermarkImageToPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 4,
                    ),
                    child: const Text(
                      'Add watermark image to photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _addImageWatermarkUint8List,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 4,
                    ),
                    child: const Text(
                      'Add watermark image to photo Uint8List',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (finalFile != null)
                  Image.file(
                    finalFile!,
                    width: 400,
                  ),
                if (finalUint8List != null)
                  Image.memory(
                    finalUint8List!,
                    width: 400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final savedFile = File(image.path);
      setState(() {
        photo = savedFile;
        photoUint8List = image.path;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image from gallery: $e');
    }
    return;
  }

  Future<void> _takeWatermarkImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageBytes = await image.readAsBytes();
      final savedFile = File(image.path);
      setState(() {
        watermark = savedFile;
        watermarkUint8List = imageBytes;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image from gallery: $e');
    }
    return;
  }

  Future<void> _addImageTextWatermark() async {
    final image = await _watermarkPlugin.addTextWatermark(
      filePath: photo!.path,
      text: 'Test watermark text Test watermark text Test watermark 7',
      x: 100,
      y: 500,
      textSize: 100,
      color: Colors.black,
      backgroundTextColor: Colors.orange,
      quality: 50,
      backgroundTextPaddingBottom: 100,
      backgroundTextPaddingLeft: 100,
      backgroundTextPaddingRight: 300,
      backgroundTextPaddingTop: 500,
      imageFormat: ImageFormat.jpeg,
    );
    if (image != null) {
      setState(() {
        finalFile = File(image);
      });
    }
  }

  Future<void> _addWatermarkImageToPhoto() async {
    final image = await _watermarkPlugin.addImageWatermark(
      filePath: photo!.path,
      watermarkImagePath: watermark!.path,
      x: 100,
      y: 200,
      quality: 100,
      imageFormat: ImageFormat.jpeg,
      watermarkWidth: 500,
      watermarkHeight: 500,
    );
    if (image != null) {
      setState(() {
        finalFile = File(image);
      });
    }
  }

  Future<void> _addTextWatermarkUint8List() async {
    final image = await _watermarkPlugin.addTextWatermarkUint8List(
      filePath: photoUint8List!,
      text: 'Test watermark text\nTest watermark text Test watermark 7 Test watermark text Test watermark 1 Test watermark text Test watermark 2 Test watermark text Test watermark 3 Test watermark text Test watermark\n77777',
      x: 50,
      y: 100,
      textSize: 24,
      color: Colors.black.withOpacity(0.5),
      backgroundTextColor: Colors.orange,
      backgroundTextPaddingBottom: 50,
      backgroundTextPaddingLeft: 10,
      backgroundTextPaddingRight: 10,
      backgroundTextPaddingTop: 50,
    );
    if (image != null) {
      setState(() {
        finalUint8List = image;
      });
    }
  }

  Future<void> _addImageWatermarkUint8List() async {
    final image = await _watermarkPlugin.addImageWatermarkUint8List(
      filePath: photoUint8List!,
      watermarkImagePath: watermarkUint8List!,
      x: 100,
      y: 200,
      watermarkWidth: 500,
      watermarkHeight: 500,
    );
    if (image != null) {
      setState(() {
        finalUint8List = image;
      });
    }
  }
}
