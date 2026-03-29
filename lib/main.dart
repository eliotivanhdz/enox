import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/photo_exif.dart';
import 'services/photo_exif_repository.dart';
import 'services/sqlite_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo EXIF Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const PhotoExifPage(),
    );
  }
}

class PhotoExifPage extends StatefulWidget {
  const PhotoExifPage({super.key});

  @override
  State<PhotoExifPage> createState() => _PhotoExifPageState();
}

class _PhotoExifPageState extends State<PhotoExifPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  late final PhotoExifRepository _repository;

  List<PhotoExif> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = PhotoExifRepository(sqliteService: SqliteService());
    _loadPhotos();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    final data = await _repository.getAllPhotos();
    setState(() {
      _items = data;
    });
  }

  Future<void> _pickImageAndSave() async {
    // Validar que la descripción no esté vacía
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
      setState(() {
        _isLoading = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        requestFullMetadata: true,
      );

      if (pickedFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final File imageFile = File(pickedFile.path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final Map<String, IfdTag> exifData = await readExifFromBytes(bytes);

      print('🔍 DEBUG - EXIF data: $exifData');

      final photoExif = PhotoExif(
        imagePath: imageFile.path,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dateTimeOriginal: _readStringTag(exifData, 'EXIF DateTimeOriginal'),
        make: _readStringTag(exifData, 'Image Make'),
        model: _readStringTag(exifData, 'Image Model'),
        latitude: _extractGpsCoordinate(exifData, isLatitude: true),
        longitude: _extractGpsCoordinate(exifData, isLatitude: false),
        width:
            _readIntTag(exifData, 'EXIF ExifImageWidth') ??
            _readIntTag(exifData, 'Image ImageWidth'),
        height:
            _readIntTag(exifData, 'EXIF ExifImageLength') ??
            _readIntTag(exifData, 'Image ImageLength'),
        orientation: _readStringTag(exifData, 'Image Orientation'),
        software: _readStringTag(exifData, 'Image Software'),
      );

      await _repository.insertPhotoExif(photoExif);
      _descriptionController.clear();
      await _loadPhotos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto y EXIF guardados correctamente')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar la foto: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _readStringTag(Map<String, IfdTag> tags, String key) {
    final value = tags[key]?.printable.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int? _readIntTag(Map<String, IfdTag> tags, String key) {
    final value = tags[key]?.printable.trim();
    if (value == null || value.isEmpty) return null;

    return int.tryParse(value);
  }

  double? _extractGpsCoordinate(
    Map<String, IfdTag> tags, {
    required bool isLatitude,
  }) {
    final gpsKey = isLatitude ? 'GPS GPSLatitude' : 'GPS GPSLongitude';
    final refKey = isLatitude ? 'GPS GPSLatitudeRef' : 'GPS GPSLongitudeRef';

    final raw = tags[gpsKey]?.values;
    final ref = tags[refKey]?.printable;

    if (raw == null) return null;
    final rawList = raw.toList();
    if (rawList.length < 3) return null;

    try {
      print('🔍 DEBUG - rawList: $rawList');
      print('🔍 DEBUG - rawList[0]: ${rawList[0].toString()}');
      print('🔍 DEBUG - rawList[1]: ${rawList[1].toString()}');
      print('🔍 DEBUG - rawList[2]: ${rawList[2].toString()}');

      final degrees = _ratioToDouble(rawList[0].toString());
      final minutes = _ratioToDouble(rawList[1].toString());
      final seconds = _ratioToDouble(rawList[2].toString());

      print('🔍 DEBUG - degrees: $degrees');
      print('🔍 DEBUG - minutes: $minutes');
      print('🔍 DEBUG - seconds: $seconds');

      if (degrees == null || minutes == null || seconds == null) return null;

      double result = degrees + (minutes / 60.0) + (seconds / 3600.0);

      print(
        '🔍 DEBUG - Cálculo: $degrees + ($minutes/60) + ($seconds/3600) = $result',
      );

      if (ref == 'S' || ref == 'W') {
        result = -result;
        print('🔍 DEBUG - Dirección: $ref -> resultado negativo: $result');
      } else {
        print('🔍 DEBUG - Dirección: $ref -> resultado positivo: $result');
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  double? _ratioToDouble(String value) {
    if (value.contains('/')) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]);
        final denominator = double.tryParse(parts[1]);
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    }

    return double.tryParse(value);
  }

  Future<void> _deletePhoto(PhotoExif item) async {
    try {
      // Borrar archivo físico
      final imageFile = File(item.imagePath);
      if (imageFile.existsSync()) {
        await imageFile.delete();
        print('✅ Archivo eliminado: ${item.imagePath}');
      }

      // Borrar de la BD
      await _repository.deletePhotoExif(item.id!);
      print('✅ Registro eliminado de la BD');

      // Recargar lista
      await _loadPhotos();

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

  Widget _buildPhotoCard(PhotoExif item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          if (File(item.imagePath).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.file(
                File(item.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Icon(Icons.image_not_supported, size: 48),
            ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y botón eliminar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.description ?? 'Sin descripción',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar foto',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Eliminar foto'),
                              content: const Text(
                                '¿Estás seguro de que deseas eliminar esta foto?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deletePhoto(item);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Información de la cámara
                _buildInfoSection(
                  icon: Icons.camera_alt,
                  title: 'Cámara',
                  items: [
                    ('Marca', item.make ?? 'N/A'),
                    ('Modelo', item.model ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 12),

                // Información de la imagen
                _buildInfoSection(
                  icon: Icons.image,
                  title: 'Imagen',
                  items: [
                    (
                      'Resolución',
                      '${item.width ?? "N/A"} x ${item.height ?? "N/A"}',
                    ),
                    ('Orientación', item.orientation?.toString() ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 12),

                // Información EXIF
                _buildInfoSection(
                  icon: Icons.access_time,
                  title: 'EXIF',
                  items: [
                    ('Fecha', item.dateTimeOriginal ?? 'N/A'),
                    ('Software', item.software ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 12),

                // Información GPS
                if (item.latitude != null || item.longitude != null)
                  _buildInfoSection(
                    icon: Icons.location_on,
                    title: 'Ubicación GPS',
                    items: [
                      ('Latitud', item.latitude?.toStringAsFixed(6) ?? 'N/A'),
                      ('Longitud', item.longitude?.toStringAsFixed(6) ?? 'N/A'),
                    ],
                  ),

                const SizedBox(height: 12),

                // Ruta del archivo (comprimida)
                Text(
                  'Archive: ${item.imagePath.split('/').last}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<(String, String)> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    item.$1,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isLoading && _descriptionController.text.trim().isNotEmpty
                    ? null
                    : _pickImageAndSave,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  _isLoading ? 'Capturando...' : 'Tomar foto y guardar',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No hay registros guardados'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return _buildPhotoCard(_items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
