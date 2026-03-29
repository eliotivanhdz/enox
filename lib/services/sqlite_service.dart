import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteService {
  static const _dbName = 'database.db';
  static const _dbVersion = 1;
  static const tableName = 'photo_exif';

  Future<Database> initializeDB() async {
    final dbPath = await getDatabasesPath();

    return openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT NOT NULL,
            description TEXT,
            date_time_original TEXT,
            make TEXT,
            model TEXT,
            latitude REAL,
            longitude REAL,
            width INTEGER,
            height INTEGER,
            orientation TEXT,
            software TEXT
          )
        ''');
      },
    );
  }
}
