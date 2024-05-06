import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IngredientAnalysis extends StatefulWidget {
  @override
  _IngredientAnalysisState createState() => _IngredientAnalysisState();
}

class _IngredientAnalysisState extends State<IngredientAnalysis> {
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';
  bool _isLoading = false; // Loading state
  List<dynamic> _allergens = []; // List of allergens
  List<String> _fullIngredients = []; // Full ingredient list

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
        setState(() {
          _isLoading = true; // Show loading indicator
        });

        final inputImage = InputImage.fromFilePath(croppedImage.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        List<String> ingredients = recognizedText.text.split(',');
        final jsonIngredients = jsonEncode({'ingredients': ingredients});

        var response = await http.post(
          Uri.parse('http://10.0.2.2:8000/ingredients/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonIngredients,
        );

        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          setState(() {
            _isLoading = false; // Hide loading indicator
            _allergens = jsonResponse['results'].where((res) => res['potential_allergen'] == 'Potential allergen').toList();
            _fullIngredients = ingredients;
            _recognizedText = ''; // Clear the old text if needed
          });
        } else {
          setState(() {
            _isLoading = false; // Hide loading indicator
            _recognizedText = 'Failed to load analysis';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _recognizedText = 'Error processing image: $e';
      });
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
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_recognizedText.isEmpty && _allergens.isEmpty && _fullIngredients.isEmpty)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Select an image to analyze the ingredients.'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _openCamera,
                  child: Text('Open Camera'),
                  style: ElevatedButton.styleFrom(primary: Colors.blue),
                ),
                ElevatedButton(
                  onPressed: _openGallery,
                  child: Text('Upload from Files'),
                  style: ElevatedButton.styleFrom(primary: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: ListView(
          children: <Widget>[
            // Check for empty allergens list
            Card(
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                title: Text('Potential Allergens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: _allergens.isEmpty
                    ? Text('There are no potential allergens in this product')
                    : Text(_allergens.map((a) => a['ingredient']).join(', ')),
              ),
            ),
            if (_fullIngredients.isNotEmpty)
              Card(
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  title: Text('Full Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(_fullIngredients.join(', ')),
                ),
              ),
          ],
        ),
      ),
    );
  }



}
