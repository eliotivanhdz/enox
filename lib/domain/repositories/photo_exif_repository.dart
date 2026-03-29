import 'package:enox/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/photo_exif.dart';

abstract class PhotoExifRepository {
  Future<int> insertPhotoExif(PhotoExif photoExif);
  Future<List<PhotoExif>> getAllPhotos();
  Future<int> deletePhotoExif(int id);
}

class PhotoExifRepositoryImpl implements PhotoExifRepository {
  final SqliteService sqliteService;

  PhotoExifRepositoryImpl({required this.sqliteService});

  @override
  Future<int> insertPhotoExif(PhotoExif photoExif) async {
    final Database db = await sqliteService.initializeDB();

    return db.insert(
      SqliteService.tableName,
      photoExif.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PhotoExif>> getAllPhotos() async {
    final Database db = await sqliteService.initializeDB();

    final List<Map<String, dynamic>> maps = await db.query(
      SqliteService.tableName,
      orderBy: 'id DESC',
    );

    return maps.map(PhotoExif.fromMap).toList();
  }

  @override
  Future<int> deletePhotoExif(int id) async {
    final Database db = await sqliteService.initializeDB();

    return db.delete(SqliteService.tableName, where: 'id = ?', whereArgs: [id]);
  }
}
