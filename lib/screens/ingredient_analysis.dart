import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isLoading = false;
  List<dynamic> _allergens = [];
  List<String> _fullIngredients = [];
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        this.user = user;
      });
    });
  }

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

  void _saveProduct() {
    print('Product saved: ${_fullIngredients.join(', ')}');
    // Implement actual save logic here
  }
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : buildContent(),
    );
  }

  Widget buildContent() {
    if (_recognizedText.isEmpty && _allergens.isEmpty && _fullIngredients.isEmpty) {
      return buildInitialContent();
    } else {
      return buildAnalysisContent();
    }
  }

  Widget buildInitialContent() {
    return Center(
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
    );
  }

  Widget buildAnalysisContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 30.0, left: 10.0, right: 10.0),
      child: ListView(
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text('Potential Allergens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: _allergens.isEmpty
                  ? Text('There are no potential allergens in this product')
                  : Text(_allergens.map((a) => a['ingredient']).join(', ')),
            ),
          ),
          if (_fullIngredients.isNotEmpty)
            Card(
              child: ListTile(
                title: Text('Full Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text(_fullIngredients.join(', ')),
              ),
            ),
          if (user != null)
            ElevatedButton(
              onPressed: _saveProduct,
              child: Text('Save Product'),
              style: ElevatedButton.styleFrom(primary: Colors.blue),
            ),
          OutlinedButton(
            onPressed: _openCamera,
            child: Text('Open Camera'),
            style: ElevatedButton.styleFrom(primary: Colors.white),
          ),
          OutlinedButton(
            onPressed: _openGallery,
            child: Text('Upload from Files'),
            style: ElevatedButton.styleFrom(primary: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //_emailController.dispose();
    //_passwordController.dispose();
    super.dispose();
  }

}
