import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'closet.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE garments (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        name TEXT,
        dominant_hex TEXT NOT NULL,
        warmth INTEGER NOT NULL,
        formality INTEGER NOT NULL,
        waterproof INTEGER NOT NULL,
        original_path TEXT NOT NULL,
        cutout_path TEXT NOT NULL,
        thumb_path TEXT NOT NULL,
        status TEXT NOT NULL,
        sub_category TEXT,
        palette TEXT NOT NULL,
        season_tags TEXT NOT NULL,
        style_tags TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE outfits (
        id TEXT PRIMARY KEY,
        date_key TEXT NOT NULL,
        items TEXT NOT NULL,
        weather_snapshot TEXT NOT NULL,
        collage_path TEXT,
        reasoning TEXT,
        feedback TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
