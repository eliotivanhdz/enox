import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/photo_exif_repository.dart';
import '../../models/photo_exif.dart';
import '../../services/exif_service.dart';
import '../../services/location_service.dart';
import '../../services/sqlite_service.dart';
import '../controllers/photo_exif_controller.dart';
import '../widgets/photo_exif_card.dart';

class PhotoExifPage extends StatefulWidget {
  const PhotoExifPage({super.key});

  @override
  State<PhotoExifPage> createState() => _PhotoExifPageState();
}

class _PhotoExifPageState extends State<PhotoExifPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  final LocationService _locationService = LocationService();
  final ExifService _exifService = const ExifService();

  late final PhotoExifController _photoExifController;
  String _locationStatus = 'Ubicación desconocida';
  bool _canCapture = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_validateDescription);

    final repository = PhotoExifRepositoryImpl(sqliteService: SqliteService());
    _photoExifController = PhotoExifController(repository: repository);
    _photoExifController.addListener(() => setState(() {}));
    _photoExifController.loadPhotos();
    _updateLocationStatus();
  }

  void _validateDescription() {
    final canCaptureNow = _descriptionController.text.trim().isNotEmpty;
    if (_canCapture != canCaptureNow) {
      setState(() {
        _canCapture = canCaptureNow;
      });
    }
  }

  Future<void> _updateLocationStatus() async {
    final position = await _locationService.getCurrentPosition();
    setState(() {
      _locationStatus = position != null
          ? 'Ubicación activa: lat=${position.latitude.toStringAsFixed(6)}, lon=${position.longitude.toStringAsFixed(6)}'
          : 'No se pudo obtener ubicación activa';
    });
  }

  @override
  void dispose() {
    _photoExifController.dispose();
    _descriptionController.removeListener(_validateDescription);
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndSave() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, agrega una descripción antes de tomar la foto',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _locationStatus = position != null
            ? 'Ubicación activa: lat=${position.latitude.toStringAsFixed(6)}, lon=${position.longitude.toStringAsFixed(6)}'
            : 'No se pudo obtener ubicación activa';
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        requestFullMetadata: true,
      );

      if (pickedFile == null) {
        return;
      }

      final File imageFile = File(pickedFile.path);
      final photoExif = await _exifService.extractPhotoExif(
        imageFile: imageFile,
        description: _descriptionController.text.trim(),
        location: position,
      );

      await _photoExifController.savePhoto(photoExif);
      _descriptionController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto y EXIF guardados correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar la foto: $e')));
    }
  }

  Future<void> _deletePhoto(PhotoExif item) async {
    try {
      final imageFile = File(item.imagePath);
      if (imageFile.existsSync()) {
        await imageFile.delete();
      }
      await _photoExifController.deletePhoto(item);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar la foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Picker + EXIF + SQLite')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                hintText: 'Describe la foto',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Text(
              _locationStatus,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _photoExifController.isLoading || !_canCapture
                        ? null
                        : _pickImageAndSave,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      _photoExifController.isLoading
                          ? 'Capturando...'
                          : 'Tomar foto y guardar',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _photoExifController.items.isEmpty
                  ? const Center(child: Text('No hay registros guardados'))
                  : ListView.builder(
                      itemCount: _photoExifController.items.length,
                      itemBuilder: (context, index) {
                        return PhotoExifCard(
                          item: _photoExifController.items[index],
                          onDelete: _deletePhoto,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
