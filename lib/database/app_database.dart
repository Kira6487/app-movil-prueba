import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';
import 'seed_data.dart';

class AppDatabase {
  AppDatabase._({DatabaseFactory? databaseFactory, String? databasePath})
      : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  static final AppDatabase instance = AppDatabase._();

  factory AppDatabase.test({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) {
    return AppDatabase._(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
  }

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    final cached = _database;
    if (cached != null) {
      return cached;
    }

    final db = await _open();
    _database = db;
    return db;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _open() async {
    final path = _databasePath ??
        p.join(
          await getDatabasesPath(),
          DatabaseSchema.databaseName,
        );
    final factory = _databaseFactory;
    Future<void> configure(Database db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }

    Future<void> create(Database db, int version) async {
      for (final statement in DatabaseSchema.statements) {
        await db.execute(statement);
      }
      await SeedData.insertIfEmpty(db);
    }

    final options = OpenDatabaseOptions(
      version: DatabaseSchema.version,
      onConfigure: configure,
      onCreate: create,
    );

    if (factory != null) {
      return factory.openDatabase(path, options: options);
    }

    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: configure,
      onCreate: create,
    );
  }
}
