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

    Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(DatabaseSchema.createBudgets);
        await db.execute('''
INSERT INTO budgets (
  id, name, budget_type, category_id, amount, currency, recurrence_type,
  selected_weekdays, units_per_day, start_date, end_date, icon_key,
  color_hex, is_active, created_at, updated_at
)
SELECT
  id,
  name,
  CASE
    WHEN recurrence_type IN ('custom_weekdays', 'weekly_once')
      OR recurrence_type LIKE 'weekday_%' THEN 'recurrence'
    ELSE 'category'
  END,
  category_id, amount, currency, recurrence_type, selected_weekdays, 1,
  start_date, end_date, 'wallet', '#005FD1', is_active, created_at, created_at
FROM budget_rules
WHERE NOT EXISTS (SELECT 1 FROM budgets)
''');
      }
    }

    final options = OpenDatabaseOptions(
      version: DatabaseSchema.version,
      onConfigure: configure,
      onCreate: create,
      onUpgrade: upgrade,
    );

    if (factory != null) {
      return factory.openDatabase(path, options: options);
    }

    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: configure,
      onCreate: create,
      onUpgrade: upgrade,
    );
  }
}
