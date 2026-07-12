import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';
import 'ledger_migration.dart';

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
      await LedgerMigration.migrate(db);
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
      if (oldVersion < 3) {
        await _migrateToV3(db);
      }
      if (oldVersion < 4) {
        await LedgerMigration.migrate(db);
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

  static Future<void> _migrateToV3(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'categories',
      column: 'icon_key',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'categories',
      column: 'color_hex',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'categories',
      column: 'sort_order',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    if (await _tableExists(db, 'financial_transactions')) {
      await _addColumnIfMissing(
        db,
        table: 'financial_transactions',
        column: 'related_type',
        definition: 'TEXT',
      );
      await _addColumnIfMissing(
        db,
        table: 'financial_transactions',
        column: 'related_id',
        definition: 'INTEGER',
      );
    }

    if (await _tableExists(db, 'savings_goals')) {
      await _ensureSavingsGoalCategoryColumn(db);
    }
    await _normalizeCategories(db);
  }

  static Future<void> _ensureSavingsGoalCategoryColumn(Database db) async {
    if (!await _columnExists(db, 'savings_goals', 'category_id')) {
      await db.execute(
        'ALTER TABLE savings_goals ADD COLUMN category_id INTEGER',
      );
    }
    final categoryId = await _getOrCreateCategory(
      db,
      name: 'Ahorro general',
      type: 'savings',
      iconKey: 'savings',
      colorHex: '#7C3AED',
    );
    await db.update(
      'savings_goals',
      {'category_id': categoryId},
      where: 'category_id IS NULL',
    );
  }

  static Future<void> _normalizeCategories(Database db) async {
    await db.rawUpdate('''
UPDATE categories
SET icon_key = COALESCE(icon_key, icon),
    color_hex = COALESCE(color_hex, color, '#005FD1'),
    sort_order = CASE WHEN sort_order = 0 THEN id ELSE sort_order END
''');
    await db.rawUpdate('''
UPDATE categories
SET type = 'system', is_active = 0
WHERE name IN (
  'Transferencia enviada',
  'Transferencia recibida',
  'Ajuste Manual'
)
''');

    final initialIncome = [
      ('Sueldo', 'salary', '#22C55E'),
      ('Freelance', 'work', '#20C982'),
      ('Devolución', 'refund', '#38BDF8'),
      ('Otros ingresos', 'wallet', '#16A34A'),
    ];
    for (final item in initialIncome) {
      await _getOrCreateCategory(
        db,
        name: item.$1,
        type: 'income',
        iconKey: item.$2,
        colorHex: item.$3,
      );
    }

    final initialSavings = [
      ('Ahorro general', 'savings', '#7C3AED'),
      ('Fondo de emergencia', 'piggy', '#005FD1'),
      ('Meta personal', 'wallet', '#A78BFA'),
    ];
    for (final item in initialSavings) {
      await _getOrCreateCategory(
        db,
        name: item.$1,
        type: 'savings',
        iconKey: item.$2,
        colorHex: item.$3,
      );
    }

    final savingsRows = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: ['Ahorro general', 'savings'],
      limit: 1,
    );
    if (savingsRows.isNotEmpty && await _tableExists(db, 'budgets')) {
      await db.update(
        'budgets',
        {'category_id': savingsRows.first['id']},
        where: "budget_type = 'savings' AND category_id IS NULL",
      );
    }
  }

  static Future<int> _getOrCreateCategory(
    Database db, {
    required String name,
    required String type,
    required String iconKey,
    required String colorHex,
  }) async {
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;

    final maxOrder = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COALESCE(MAX(sort_order), 0) FROM categories WHERE type = ?',
            [type],
          ),
        ) ??
        0;
    return db.insert('categories', {
      'name': name,
      'type': type,
      'icon': iconKey,
      'color': colorHex,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'sort_order': maxOrder + 1,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    if (await _columnExists(db, table, column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name'] == column);
  }

  static Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table' AND name = ?",
      whereArgs: [table],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
