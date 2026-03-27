import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:exif/exif.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eNox',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PhotoApp(),
    );
  }
}

class PhotoApp extends StatefulWidget {
  const PhotoApp({super.key});

  @override
  State<PhotoApp> createState() => _PhotoAppState();
}

class _PhotoAppState extends State<PhotoApp> {
  XFile? _image;
  Map<String, IfdTag>? _exifData;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = image;
      });
      _extractExif(image);
    }
  }

  Future<void> _extractExif(XFile image) async {
    final file = File(image.path);
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);
    setState(() {
      _exifData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eNox')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_image != null)
            Expanded(
              child: Center(
                child: Image.file(File(_image!.path), fit: BoxFit.contain),
              ),
            ),
          if (_exifData != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _exifData!.entries.map((entry) {
                    return Text(
                      '${entry.key}: ${entry.value}',
                      textAlign: TextAlign.center,
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Select from Gallery'),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Take Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
