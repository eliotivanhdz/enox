class PhotoExif {
  final int? id;
  final String imagePath;
  final String? description;
  final String? dateTimeOriginal;
  final String? make;
  final String? model;
  final double? latitude;
  final double? longitude;
  final int? width;
  final int? height;
  final String? orientation;
  final String? software;

  PhotoExif({
    this.id,
    required this.imagePath,
    this.description,
    this.dateTimeOriginal,
    this.make,
    this.model,
    this.latitude,
    this.longitude,
    this.width,
    this.height,
    this.orientation,
    this.software,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'description': description,
      'date_time_original': dateTimeOriginal,
      'make': make,
      'model': model,
      'latitude': latitude,
      'longitude': longitude,
      'width': width,
      'height': height,
      'orientation': orientation,
      'software': software,
    };
  }

  factory PhotoExif.fromMap(Map<String, dynamic> map) {
    return PhotoExif(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      description: map['description'] as String?,
      dateTimeOriginal: map['date_time_original'] as String?,
      make: map['make'] as String?,
      model: map['model'] as String?,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      width: map['width'] as int?,
      height: map['height'] as int?,
      orientation: map['orientation'] as String?,
      software: map['software'] as String?,
    );
  }
}
