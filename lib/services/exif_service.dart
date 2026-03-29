import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';

import '../models/photo_exif.dart';

class ExifService {
  const ExifService();

  Future<PhotoExif> extractPhotoExif({
    required File imageFile,
    required String description,
    Position? location,
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final Map<String, IfdTag> exifData = await readExifFromBytes(bytes);

    final double? gpsLatitude = _extractGpsCoordinate(
      exifData,
      isLatitude: true,
    );
    final double? gpsLongitude = _extractGpsCoordinate(
      exifData,
      isLatitude: false,
    );

    return PhotoExif(
      imagePath: imageFile.path,
      description: description,
      dateTimeOriginal: _readStringTag(exifData, 'EXIF DateTimeOriginal'),
      make: _readStringTag(exifData, 'Image Make'),
      model: _readStringTag(exifData, 'Image Model'),
      latitude: gpsLatitude ?? location?.latitude,
      longitude: gpsLongitude ?? location?.longitude,
      width:
          _readIntTag(exifData, 'EXIF ExifImageWidth') ??
          _readIntTag(exifData, 'Image ImageWidth'),
      height:
          _readIntTag(exifData, 'EXIF ExifImageLength') ??
          _readIntTag(exifData, 'Image ImageLength'),
      orientation: _readStringTag(exifData, 'Image Orientation'),
      software: _readStringTag(exifData, 'Image Software'),
    );
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

    final degrees = _ratioToDouble(rawList[0].toString());
    final minutes = _ratioToDouble(rawList[1].toString());
    final seconds = _ratioToDouble(rawList[2].toString());

    if (degrees == null || minutes == null || seconds == null) return null;

    double result = degrees + (minutes / 60.0) + (seconds / 3600.0);

    if (ref == 'S' || ref == 'W') {
      result = -result;
    }

    return result;
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
}
