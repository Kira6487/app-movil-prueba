import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/ledger_models.dart';
import 'package:finanzas_personales/models/savings_goal_model.dart';
import 'package:finanzas_personales/models/transfer_model.dart';
import 'package:finanzas_personales/models/wallet_model.dart';
import 'package:finanzas_personales/services/account_service.dart';
import 'package:finanzas_personales/services/ledger_service.dart';
import 'package:finanzas_personales/services/savings_service.dart';
import 'package:finanzas_personales/services/transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_fixtures.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
      'una instalación nueva tiene datos iniciales sin transacciones ni presupuestos',
      () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    for (final table in [
      'financial_transactions',
      'budgets',
      'savings_goals',
      'wallets',
    ]) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
      final count = (rows.first['total'] as num?)?.toInt() ?? -1;
      expect(count, 0, reason: '$table debe iniciar vacío');
    }
    final accountRows =
        await db.rawQuery('SELECT COUNT(*) AS total FROM accounts');
    expect((accountRows.first['total'] as num).toInt(), 2);
    final categoryRows =
        await db.rawQuery('SELECT COUNT(*) AS total FROM categories');
    expect((categoryRows.first['total'] as num).toInt(), 13);
    final actionRows =
        await db.rawQuery('SELECT COUNT(*) AS total FROM quick_actions');
    expect((actionRows.first['total'] as num).toInt(), 3);
    await database.close();
  });

  test('rechaza asientos con una línea o descuadrados', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    final system = await db.query('ledger_accounts', columns: ['id'], limit: 2);
    final ledger = LedgerService(database: database);
    await expectLater(
      ledger.postEntry(JournalEntryDraft(
        date: '2026-07-11',
        description: 'Inválido',
        sourceType: 'test',
        createdAt: '2026-07-11',
        lines: [
          JournalLineDraft(
            ledgerAccountId: system.first['id'] as int,
            debit: 10,
            currency: 'SOL',
          ),
        ],
      )),
      throwsArgumentError,
    );
    await database.close();
  });

  test('depósito y retiro de alcancía conservan el total y su progreso',
      () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    await installTestFixtures(database);
    final accounts = AccountService(database: database);
    final parent = (await accounts.getVisibleAccounts())
        .firstWhere((account) => account.currency == 'SOL');
    final savings = SavingsService(database: database);
    final walletId = await savings.insertWallet(WalletModel(
      name: 'Emergencias',
      accountId: parent.id!,
      currency: 'SOL',
      savingsItemId: 77,
      createdAt: '2026-07-11',
    ));
    final transfer = TransferService(database: database);
    await transfer.insertTransfer(TransferModel(
      fromAccountId: parent.id!,
      toAccountId: parent.id!,
      toWalletId: walletId,
      savingsItemId: 77,
      amountFrom: 100,
      currencyFrom: 'SOL',
      amountTo: 100,
      currencyTo: 'SOL',
      date: '2026-07-11',
      createdAt: '2026-07-11',
    ));
    var refreshed = await accounts.getAccountById(parent.id!);
    var wallet = (await savings.getWalletsByAccount(parent.id!)).single;
    expect(refreshed!.currentBalance + wallet.amount, parent.currentBalance);
    expect(await savings.getGoalProgress(77), 100);
    expect(
      () => savings.deleteOrDeactivateWallet(walletId),
      throwsStateError,
    );

    await transfer.insertTransfer(TransferModel(
      fromAccountId: parent.id!,
      toAccountId: parent.id!,
      fromWalletId: walletId,
      savingsItemId: 77,
      amountFrom: 40,
      currencyFrom: 'SOL',
      amountTo: 40,
      currencyTo: 'SOL',
      date: '2026-07-12',
      createdAt: '2026-07-12',
    ));
    refreshed = await accounts.getAccountById(parent.id!);
    wallet = (await savings.getWalletsByAccount(parent.id!)).single;
    expect(wallet.amount, 60);
    expect(await savings.getGoalProgress(77), 60);
    expect(refreshed!.currentBalance + wallet.amount, parent.currentBalance);

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

  test('filtra objetivos por categoria, SOL/PEN, activo y vigencia', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    await installTestFixtures(database);
    final db = await database.database;
    final categories = await db.query('categories',
        columns: ['id', 'name'], where: "type = 'savings'");
    final emergencyId = categories
        .firstWhere((row) => row['name'] == 'Fondo de emergencia')['id'] as int;
    final otherId =
        categories.firstWhere((row) => row['id'] != emergencyId)['id'] as int;
    final service = SavingsService(database: database);

    Future<void> addGoal(String name, int categoryId, String currency,
        {bool active = true, String? deadline}) async {
      await service.insertSavingsGoal(SavingsGoalModel(
        name: name,
        categoryId: categoryId,
        targetAmount: 1000,
        currency: currency,
        deadline: deadline,
        isActive: active,
        createdAt: '2026-07-22',
      ));
    }

    await addGoal('Emergencia SOL', emergencyId, 'SOL');
    await addGoal('Emergencia PEN', emergencyId, 'PEN');
    await addGoal('Emergencia USD', emergencyId, 'USD');
    await addGoal('Emergencia inactiva', emergencyId, 'SOL', active: false);
    await addGoal('Otra categoria', otherId, 'SOL');
    await addGoal('Objetivo vencido', emergencyId, 'SOL',
        deadline: '2025-01-01');

    final sol = await service.getCompatibleSavingsGoals(
      savingsCategoryId: emergencyId,
      currency: 'SOL',
      onDate: DateTime(2026, 7, 22),
    );
    expect(sol.map((goal) => goal.name),
        containsAll(<String>['Emergencia SOL', 'Emergencia PEN']));
    expect(sol.map((goal) => goal.name), isNot(contains('Emergencia USD')));
    expect(
        sol.map((goal) => goal.name), isNot(contains('Emergencia inactiva')));
    expect(sol.map((goal) => goal.name), isNot(contains('Otra categoria')));
    expect(sol.map((goal) => goal.name), isNot(contains('Objetivo vencido')));

    final usd = await service.getCompatibleSavingsGoals(
      savingsCategoryId: emergencyId,
      currency: 'USD',
      onDate: DateTime(2026, 7, 22),
    );
    expect(usd.map((goal) => goal.name), ['Emergencia USD']);
    await database.close();
  });
}
