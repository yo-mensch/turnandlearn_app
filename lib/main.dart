import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Text Recognition App'),
        ),
        body: Center(
          child: OpenCameraAndGalleryButton(),
        ),
      ),
    );
  }
}

class OpenCameraAndGalleryButton extends StatefulWidget {
  @override
  _OpenCameraAndGalleryButtonState createState() => _OpenCameraAndGalleryButtonState();
}

class _OpenCameraAndGalleryButtonState extends State<OpenCameraAndGalleryButton> {
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';

  Future<void> _processImage(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      _recognizedText = recognizedText.text;
    });
  }

  Future<void> _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processImage(image);
    }
  }

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _processImage(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ElevatedButton(
          onPressed: _openCamera,
          child: Text('Open Camera & Scan Text'),
        ),
        ElevatedButton(
          onPressed: _openGallery,
          child: Text('Upload from Files & Scan Text'),
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Text(_recognizedText, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
