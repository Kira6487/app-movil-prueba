import 'package:sqflite/sqflite.dart';

class SeedData {
  const SeedData._();

  static Future<void> insertIfEmpty(Database db) async {
    await _insertCategories(db);
    await _insertAccounts(db);
    await _insertQuickActions(db);
  }

  static Future<void> _insertCategories(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();
    final expenseCategories = [
      ('Alimentación', 'restaurant', '#FF6B6B', 1),
      ('Transporte', 'directions_bus', '#38BDF8', 2),
      ('Café y snacks', 'local_cafe', '#8B5CF6', 3),
      ('Salud', 'health_and_safety', '#22C55E', 4),
      ('Educación', 'school', '#2563EB', 5),
      ('Ocio', 'sports_esports', '#F59E0B', 6),
    ];
    for (final item in expenseCategories) {
      await db.insert('categories', {
        'name': item.$1,
        'type': 'expense',
        'icon': item.$2,
        'color': item.$3,
        'icon_key': item.$2,
        'color_hex': item.$3,
        'sort_order': item.$4,
        'is_active': 1,
        'created_at': now,
      });
    }

    final incomeCategories = [
      ('Sueldo', 'payments', '#22C55E', 1),
      ('Ventas', 'storefront', '#0EA5E9', 2),
      ('Devoluciones', 'replay', '#8B5CF6', 3),
      ('Otros ingresos', 'add_card', '#64748B', 4),
    ];
    for (final item in incomeCategories) {
      await db.insert('categories', {
        'name': item.$1,
        'type': 'income',
        'icon': item.$2,
        'color': item.$3,
        'icon_key': item.$2,
        'color_hex': item.$3,
        'sort_order': item.$4,
        'is_active': 1,
        'created_at': now,
      });
    }

    final savingsCategories = [
      ('Fondo de emergencia', 'shield', '#14B8A6', 1),
      ('Meta personal', 'flag', '#6366F1', 2),
      ('Viajes', 'flight', '#38BDF8', 3),
    ];
    for (final item in savingsCategories) {
      await db.insert('categories', {
        'name': item.$1,
        'type': 'savings',
        'icon': item.$2,
        'color': item.$3,
        'icon_key': item.$2,
        'color_hex': item.$3,
        'sort_order': item.$4,
        'is_active': 1,
        'created_at': now,
      });
    }
  }

  static Future<void> _insertAccounts(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM accounts'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();
    await db.insert('accounts', {
      'name': 'BCP Soles',
      'account_type': 'Ahorros',
      'currency': 'SOL',
      'initial_balance': 0.0,
      'current_balance': 0.0,
      'is_hidden_from_budget': 0,
      'icon': 'account_balance',
      'color': '#005FD1',
      'created_at': now,
    });
    await db.insert('accounts', {
      'name': 'BCP Dólares',
      'account_type': 'Ahorros',
      'currency': 'USD',
      'initial_balance': 0.0,
      'current_balance': 0.0,
      'is_hidden_from_budget': 0,
      'icon': 'account_balance_wallet',
      'color': '#38C7E8',
      'created_at': now,
    });
  }

  static Future<void> _insertQuickActions(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quick_actions'),
        ) ??
        0;
    if (count > 0) return;

    final bcpSolesId = (await db.rawQuery(
      "SELECT id FROM accounts WHERE name = 'BCP Soles' LIMIT 1",
    ))
        .first['id'] as int;

    final now = DateTime.now().toIso8601String();
    final actions = [
      ('Menú', 12.0, 'Alimentación', 'restaurant', '#FF6B6B', 1),
      ('Pasaje', 4.0, 'Transporte', 'directions_bus', '#38BDF8', 2),
      ('Café', 5.5, 'Café y snacks', 'local_cafe', '#8B5CF6', 3),
    ];
    for (final item in actions) {
      final catRow = await db.rawQuery(
        "SELECT id FROM categories WHERE name = ? AND type = 'expense' LIMIT 1",
        [item.$3],
      );
      if (catRow.isEmpty) continue;

      await db.insert('quick_actions', {
        'name': item.$1,
        'amount': item.$2,
        'currency': 'SOL',
        'category_id': catRow.first['id'] as int,
        'account_id': bcpSolesId,
        'budget_item_id': null,
        'icon': item.$4,
        'color': item.$5,
        'sort_order': item.$6,
        'is_active': 1,
        'comment': item.$1,
        'created_at': now,
      });
    }
  }
}
