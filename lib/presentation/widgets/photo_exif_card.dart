import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/photo_exif.dart';

class PhotoExifCard extends StatelessWidget {
  final PhotoExif item;
  final Future<void> Function(PhotoExif item) onDelete;

  const PhotoExifCard({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        showDialog<void>(
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
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await onDelete(item);
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

                _buildInfoSection(
                  icon: Icons.phone_android,
                  title: 'Dispositivo',
                  items: [
                    ('Marca', item.make ?? 'N/A'),
                    ('Modelo', item.model ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 12),

                _buildInfoSection(
                  icon: Icons.image,
                  title: 'Imagen',
                  items: [
                    (
                      'Resolución',
                      '${item.width ?? "N/A"} x ${item.height ?? "N/A"}',
                    ),
                    ('Orientación', item.orientation ?? 'N/A'),
                  ],
                ),

                const SizedBox(height: 12),

                _buildInfoSection(
                  icon: Icons.access_time,
                  title: 'EXIF',
                  items: [
                    ('Fecha', item.dateTimeOriginal ?? 'N/A'),
                    ('Path', item.imagePath.split('/').last),
                  ],
                ),

                const SizedBox(height: 12),

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
        }),
      ],
    );
  }
}
