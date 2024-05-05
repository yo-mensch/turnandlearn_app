import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    try {
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          )
        ],
      );

      if (croppedImage != null) {
        final inputImage = InputImage.fromFilePath(croppedImage.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        // Splitting the recognized text into ingredients
        List<String> ingredients = recognizedText.text.split(',');
        final jsonIngredients = jsonEncode({'ingredients': ingredients});
        // Sending a POST request to the server
        var response = await http.post(
          Uri.parse('http://10.0.2.2:8000/ingredients/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonIngredients,
        );

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['results'] != null) {
            setState(() {
              _recognizedText = jsonResponse['results']
                  .map((res) => "${res['ingredient']}: ${res['potential_allergen']}")
                  .join('\n');
            });
          } else {
            setState(() {
              _recognizedText = 'No results found';
            });
          }
        } else {
          throw Exception('Failed to load analysis: ${response.statusCode}');
        }

      }
    } catch (e) {
      print('Error cropping image: $e');
    }
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
          child: Text('Open Camera'),
        ),
        ElevatedButton(
          onPressed: _openGallery,
          child: Text('Upload from Files'),
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
