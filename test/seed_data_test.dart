import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/category_model.dart';
import 'package:finanzas_personales/services/account_service.dart';
import 'package:finanzas_personales/services/category_service.dart';
import 'package:finanzas_personales/services/quick_action_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_fixtures.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('base nueva crea categorías básicas', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    final categories = CategoryService(database: database);
    final all = await categories.getAllCategories();
    expect(all.length, 13);

    final expenses =
        await categories.getCategoriesByType(CategoryScope.expense);
    final incomes = await categories.getCategoriesByType(CategoryScope.income);
    final savings = await categories.getCategoriesByType(CategoryScope.savings);

    expect(expenses, hasLength(6));
    expect(incomes, hasLength(4));
    expect(savings, hasLength(3));

    expect(
        expenses.map((c) => c.name),
        containsAll([
          'Alimentación',
          'Transporte',
          'Café y snacks',
          'Salud',
          'Educación',
          'Ocio'
        ]));
    expect(incomes.map((c) => c.name),
        containsAll(['Sueldo', 'Ventas', 'Devoluciones', 'Otros ingresos']));
    expect(savings.map((c) => c.name),
        containsAll(['Fondo de emergencia', 'Meta personal', 'Viajes']));
    await database.close();
  });

  test('base nueva crea exactamente dos cuentas con saldo cero', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    final accounts = AccountService(database: database);
    final all = await accounts.getAllAccounts();
    expect(all, hasLength(2));

    final soles = all.firstWhere((a) => a.currency == 'SOL');
    final usd = all.firstWhere((a) => a.currency == 'USD');
    expect(soles.name, 'BCP Soles');
    expect(usd.name, 'BCP Dólares');
    expect(soles.currentBalance, 0.0);
    expect(usd.currentBalance, 0.0);
    expect(soles.initialBalance, 0.0);
    expect(usd.initialBalance, 0.0);
    await database.close();
  });

  test('no existen transacciones iniciales', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    final rows = await db
        .rawQuery('SELECT COUNT(*) AS total FROM financial_transactions');
    expect((rows.first['total'] as num).toInt(), 0);
    await database.close();
  });

  test('no existen presupuestos iniciales', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM budgets');
    expect((rows.first['total'] as num).toInt(), 0);
    await database.close();
  });

  test('no existen alcancías iniciales', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    final wallets = await db.rawQuery('SELECT COUNT(*) AS total FROM wallets');
    expect((wallets.first['total'] as num).toInt(), 0);
    final goals =
        await db.rawQuery('SELECT COUNT(*) AS total FROM savings_goals');
    expect((goals.first['total'] as num).toInt(), 0);
    await database.close();
  });

  test('se crean exactamente tres botones rápidos', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    final quickActions = QuickActionService(database: database);
    final all = await quickActions.getAllQuickActions();
    expect(all, hasLength(3));
    expect(all.map((a) => a.name), containsAll(['Menú', 'Pasaje', 'Café']));
    await database.close();
  });

  test('no se duplican seeds al abrir la base nuevamente', () async {
    final path = '/tmp/duna_seed_${DateTime.now().microsecondsSinceEpoch}.db';
    var database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    await database.initialize();
    await database.close();

    database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    await database.initialize();
    final db = await database.database;
    final categories =
        await db.rawQuery('SELECT COUNT(*) AS total FROM categories');
    expect((categories.first['total'] as num).toInt(), 13);
    final accounts =
        await db.rawQuery('SELECT COUNT(*) AS total FROM accounts');
    expect((accounts.first['total'] as num).toInt(), 2);
    final actions =
        await db.rawQuery('SELECT COUNT(*) AS total FROM quick_actions');
    expect((actions.first['total'] as num).toInt(), 3);
    await database.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });

  test('no se duplican seeds al abrir con fixtures instalados', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    await installTestFixtures(database);
    final db = await database.database;
    final accounts =
        await db.rawQuery('SELECT COUNT(*) AS total FROM accounts');
    expect((accounts.first['total'] as num).toInt(), 6);
    await database.close();
  });

  test('botones rápidos muestran montos sin overflow', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    final quickActions = QuickActionService(database: database);
    final all = await quickActions.getAllQuickActions();
    for (final action in all) {
      expect(action.amount, greaterThan(0));
      expect(action.amount.toStringAsFixed(2), isNotEmpty);
    }
    final menu = all.firstWhere((a) => a.name == 'Menú');
    expect(menu.amount, 12.0);
    final pasaje = all.firstWhere((a) => a.name == 'Pasaje');
    expect(pasaje.amount, 4.0);
    final cafe = all.firstWhere((a) => a.name == 'Café');
    expect(cafe.amount, 5.5);
    await database.close();
  });

  test('los asientos contables están balanceados', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    final invalidEntries = await db.rawQuery('''
SELECT e.id
FROM journal_entries e
LEFT JOIN journal_lines l ON l.journal_entry_id = e.id
GROUP BY e.id
HAVING COUNT(l.id) < 2
   OR ABS(SUM(CASE WHEN l.debit > 0 THEN l.base_amount ELSE -l.base_amount END)) > 0.000001
''');
    expect(invalidEntries, isEmpty);
    await database.close();
  });
}
