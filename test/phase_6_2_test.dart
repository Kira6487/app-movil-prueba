import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/ledger_models.dart';
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

  test('una instalación nueva no contiene datos demo', () async {
    final database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final db = await database.database;
    for (final table in [
      'accounts',
      'categories',
      'financial_transactions',
      'budgets',
      'quick_actions',
      'savings_goals',
      'wallets',
    ]) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
      final count = (rows.first['total'] as num?)?.toInt() ?? -1;
      expect(count, 0, reason: '$table debe iniciar vacío');
    }
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
}
