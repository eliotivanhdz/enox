import 'package:sqflite/sqflite.dart';
import '../models/photo_exif.dart';
import 'sqlite_service.dart';

class PhotoExifRepository {
  final SqliteService sqliteService;

  PhotoExifRepository({required this.sqliteService});

  Future<int> insertPhotoExif(PhotoExif photoExif) async {
    final Database db = await sqliteService.initializeDB();

    return db.insert(
      SqliteService.tableName,
      photoExif.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PhotoExif>> getAllPhotos() async {
    final Database db = await sqliteService.initializeDB();

    final List<Map<String, dynamic>> maps = await db.query(
      SqliteService.tableName,
      orderBy: 'id DESC',
    );

    return maps.map(PhotoExif.fromMap).toList();
  }

  Future<int> deletePhotoExif(int id) async {
    final Database db = await sqliteService.initializeDB();

    return db.delete(SqliteService.tableName, where: 'id = ?', whereArgs: [id]);
  }
}
