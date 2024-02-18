import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Camera App Opener'),
        ),
        body: Center(
          child: OpenCameraButton(),
        ),
      ),
    );
  }
}

class OpenCameraButton extends StatefulWidget {
  @override
  _OpenCameraButtonState createState() => _OpenCameraButtonState();
}

class _OpenCameraButtonState extends State<OpenCameraButton> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    // Capture a photo
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    // Optionally, you can do something with the photo here, like displaying it in the UI
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _openCamera,
      child: Text('Open Camera'),
    );
  }
}
