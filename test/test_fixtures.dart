import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/account_model.dart';
import 'package:finanzas_personales/models/category_model.dart';
import 'package:finanzas_personales/models/quick_action_model.dart';
import 'package:finanzas_personales/services/account_service.dart';
import 'package:finanzas_personales/services/category_service.dart';
import 'package:finanzas_personales/services/quick_action_service.dart';

Future<void> installTestFixtures(AppDatabase database) async {
  final db = await database.database;
  final existing = await db.rawQuery('SELECT COUNT(*) total FROM accounts');
  if ((existing.first['total'] as num).toInt() > 0) return;
  const createdAt = '2026-07-01T00:00:00.000';
  final categories = CategoryService(database: database);
  final ids = <String, int>{};
  var order = 0;
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
    'Otros'
  ]) {
    ids[name] = await categories.insertCategory(CategoryModel(
        name: name,
        type: 'expense',
        icon: name == 'Pasaje' ? 'transport' : 'food',
        color: '#EF4444',
        sortOrder: ++order,
        createdAt: createdAt));
  }
  order = 0;
  for (final item in [
    ('Sueldo', 'salary', '#22C55E'),
    ('Freelance', 'work', '#20C982'),
    ('Devolución', 'refund', '#38BDF8'),
    ('Otros ingresos', 'wallet', '#16A34A')
  ]) {
    ids[item.$1] = await categories.insertCategory(CategoryModel(
        name: item.$1,
        type: 'income',
        icon: item.$2,
        color: item.$3,
        sortOrder: ++order,
        createdAt: createdAt));
  }
  order = 0;
  for (final item in [
    ('Ahorro general', 'savings', '#7C3AED'),
    ('Fondo de emergencia', 'piggy', '#005FD1'),
    ('Meta personal', 'wallet', '#A78BFA')
  ]) {
    ids[item.$1] = await categories.insertCategory(CategoryModel(
        name: item.$1,
        type: 'savings',
        icon: item.$2,
        color: item.$3,
        sortOrder: ++order,
        createdAt: createdAt));
  }
  final accounts = AccountService(database: database);
  final accountIds = <String, int>{};
  Future<void> addAccount(
      String name, String type, String currency, double balance, String color,
      {bool hidden = false}) async {
    accountIds[name] = await accounts.insertAccount(AccountModel(
        name: name,
        accountType: type,
        currency: currency,
        initialBalance: balance,
        currentBalance: balance,
        isHiddenFromBudget: hidden,
        color: color,
        createdAt: createdAt));
  }

  await addAccount('BCP Ahorros', 'ahorros', 'SOL', 850, '#38BDF8');
  await addAccount('Yape', 'billetera', 'SOL', 120, '#A78BFA');
  await addAccount('Cuenta USD', 'ahorros', 'USD', 200, '#22C55E');
  await addAccount('Plazo Fijo', 'plazo_fijo', 'SOL', 3000, '#F59E0B',
      hidden: true);
  await db.insert('exchange_rates', {
    'from_currency': 'USD',
    'to_currency': 'SOL',
    'rate': 3.8,
    'date': createdAt,
    'created_at': createdAt
  });
  final quickActions = QuickActionService(database: database);
  var actionOrder = 0;
  for (final item in [
    ('Menú', 12.0, 'Comida', 'BCP Ahorros', '#EF4444'),
    ('Pasaje', 4.0, 'Pasaje', 'Yape', '#38BDF8'),
    ('Café', 6.0, 'Café', 'BCP Ahorros', '#A78BFA'),
    ('Postre', 8.0, 'Postre', 'BCP Ahorros', '#F59E0B'),
    ('Taxi', 15.0, 'Taxi', 'BCP Ahorros', '#22C55E')
  ]) {
    await quickActions.insertQuickAction(QuickActionModel(
        name: item.$1,
        amount: item.$2,
        currency: 'SOL',
        categoryId: ids[item.$3],
        accountId: accountIds[item.$4],
        color: item.$5,
        sortOrder: ++actionOrder,
        createdAt: createdAt));
  }
}
