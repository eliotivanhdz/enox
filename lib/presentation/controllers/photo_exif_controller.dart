import 'package:flutter/material.dart';

import '../../domain/repositories/photo_exif_repository.dart';
import '../../models/photo_exif.dart';

class PhotoExifController extends ChangeNotifier {
  final PhotoExifRepository repository;

  PhotoExifController({required this.repository});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PhotoExif> _items = [];
  List<PhotoExif> get items => List.unmodifiable(_items);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadPhotos() async {
    _setLoading(true);
    try {
      _items = await repository.getAllPhotos();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> savePhoto(PhotoExif photoExif) async {
    _setLoading(true);
    try {
      await repository.insertPhotoExif(photoExif);
      await loadPhotos();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePhoto(PhotoExif item) async {
    _setLoading(true);
    try {
      await repository.deletePhotoExif(item.id!);
      _items.removeWhere((element) => element.id == item.id);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
