import 'package:sqflite/sqflite.dart';

import '../utils/date_utils.dart';

class SeedData {
  const SeedData._();

  static Future<void> insertIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories')) ??
        0;
    if (count > 0) {
      return;
    }

    final now = AppDateUtils.nowIso();
    final categoryIds = <String, int>{};
    final accountIds = <String, int>{};

    Future<void> insertCategory(
      String name,
      String type,
      String color, {
      String? icon,
      required int sortOrder,
    }) async {
      final id = await db.insert('categories', {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'icon_key': icon,
        'color_hex': color,
        'sort_order': sortOrder,
        'is_active': 1,
        'created_at': now,
      });
      categoryIds[name] = id;
    }

    var sortOrder = 0;
    for (final name in [
      'Comida',
      'Pasaje',
      'Servicios',
      'Ocio',
      'Salud',
      'Estudios',
      'Taxi',
      'Postre',
      'Café',
      'Otros',
    ]) {
      sortOrder += 1;
      await insertCategory(
        name,
        'expense',
        '#EF4444',
        icon: name == 'Pasaje' ? 'transport' : 'food',
        sortOrder: sortOrder,
      );
    }

    sortOrder = 0;
    for (final item in [
      ('Sueldo', 'salary', '#22C55E'),
      ('Freelance', 'work', '#20C982'),
      ('Devolución', 'refund', '#38BDF8'),
      ('Otros ingresos', 'wallet', '#16A34A'),
    ]) {
      sortOrder += 1;
      await insertCategory(
        item.$1,
        'income',
        item.$3,
        icon: item.$2,
        sortOrder: sortOrder,
      );
    }

    sortOrder = 0;
    for (final item in [
      ('Ahorro general', 'savings', '#7C3AED'),
      ('Fondo de emergencia', 'piggy', '#005FD1'),
      ('Meta personal', 'wallet', '#A78BFA'),
    ]) {
      sortOrder += 1;
      await insertCategory(
        item.$1,
        'savings',
        item.$3,
        icon: item.$2,
        sortOrder: sortOrder,
      );
    }

    Future<void> insertAccount({
      required String name,
      required String accountType,
      required String currency,
      required double balance,
      required bool hiddenFromBudget,
      required String color,
    }) async {
      final id = await db.insert('accounts', {
        'name': name,
        'account_type': accountType,
        'currency': currency,
        'initial_balance': balance,
        'current_balance': balance,
        'is_hidden_from_budget': hiddenFromBudget ? 1 : 0,
        'color': color,
        'icon': null,
        'created_at': now,
      });
      accountIds[name] = id;
    }

    await insertAccount(
      name: 'BCP Ahorros',
      accountType: 'ahorros',
      currency: 'SOL',
      balance: 850,
      hiddenFromBudget: false,
      color: '#38BDF8',
    );
    await insertAccount(
      name: 'Yape',
      accountType: 'billetera',
      currency: 'SOL',
      balance: 120,
      hiddenFromBudget: false,
      color: '#A78BFA',
    );
    await insertAccount(
      name: 'Cuenta USD',
      accountType: 'ahorros',
      currency: 'USD',
      balance: 200,
      hiddenFromBudget: false,
      color: '#22C55E',
    );
    await insertAccount(
      name: 'Plazo Fijo',
      accountType: 'plazo_fijo',
      currency: 'SOL',
      balance: 3000,
      hiddenFromBudget: true,
      color: '#F59E0B',
    );

    await db.insert('exchange_rates', {
      'from_currency': 'USD',
      'to_currency': 'SOL',
      'rate': 3.80,
      'date': now,
      'created_at': now,
    });

    Future<void> insertQuickAction({
      required String name,
      required double amount,
      required String categoryName,
      required String accountName,
      required int sortOrder,
      required String color,
    }) async {
      await db.insert('quick_actions', {
        'name': name,
        'amount': amount,
        'currency': 'SOL',
        'category_id': categoryIds[categoryName],
        'account_id': accountIds[accountName],
        'comment': null,
        'icon': null,
        'color': color,
        'is_active': 1,
        'sort_order': sortOrder,
        'created_at': now,
      });
    }

    await insertQuickAction(
      name: 'Menú',
      amount: 12,
      categoryName: 'Comida',
      accountName: 'BCP Ahorros',
      sortOrder: 1,
      color: '#EF4444',
    );
    await insertQuickAction(
      name: 'Pasaje',
      amount: 4,
      categoryName: 'Pasaje',
      accountName: 'Yape',
      sortOrder: 2,
      color: '#38BDF8',
    );
    await insertQuickAction(
      name: 'Café',
      amount: 6,
      categoryName: 'Café',
      accountName: 'BCP Ahorros',
      sortOrder: 3,
      color: '#A78BFA',
    );
    await insertQuickAction(
      name: 'Postre',
      amount: 8,
      categoryName: 'Postre',
      accountName: 'BCP Ahorros',
      sortOrder: 4,
      color: '#F59E0B',
    );
    await insertQuickAction(
      name: 'Taxi',
      amount: 15,
      categoryName: 'Taxi',
      accountName: 'BCP Ahorros',
      sortOrder: 5,
      color: '#22C55E',
    );
  }
}
