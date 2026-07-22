import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

/// Additive v4 migration. Legacy rows remain intact and are linked through
/// source_type/source_id so rerunning the migration cannot duplicate entries.
class LedgerMigration {
  const LedgerMigration._();

  static Future<void> migrate(Database db) async {
    await db.execute(DatabaseSchema.createLedgerAccounts);
    await db.execute(DatabaseSchema.createJournalEntries);
    await db.execute(DatabaseSchema.createJournalLines);
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS idx_journal_source
ON journal_entries(source_type, source_id) WHERE source_id IS NOT NULL''');
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_reference
ON ledger_accounts(reference_type, reference_id)
WHERE reference_type IS NOT NULL AND reference_id IS NOT NULL''');
    await db.execute('''CREATE INDEX IF NOT EXISTS idx_journal_budget
ON journal_entries(budget_item_id, date)''');
    await db.execute('''CREATE INDEX IF NOT EXISTS idx_journal_savings
ON journal_entries(savings_item_id, date)''');

    await _addColumn(
        db, 'financial_transactions', 'journal_entry_id', 'INTEGER');
    await _addColumn(db, 'transfers', 'journal_entry_id', 'INTEGER');
    await _addColumn(db, 'transfers', 'savings_item_id', 'INTEGER');
    await _addColumn(db, 'transfers', 'from_wallet_id', 'INTEGER');
    await _addColumn(db, 'transfers', 'to_wallet_id', 'INTEGER');
    await _addColumn(db, 'quick_actions', 'budget_item_id', 'INTEGER');
    await _addColumn(db, 'wallets', 'ledger_account_id', 'INTEGER');
    await _addColumn(
        db, 'wallets', 'wallet_type', "TEXT NOT NULL DEFAULT 'piggyBank'");
    await _addColumn(db, 'wallets', 'icon_key', 'TEXT');
    await _addColumn(db, 'wallets', 'color_hex', 'TEXT');
    await _addColumn(db, 'wallets', 'savings_category_id', 'INTEGER');
    await _addColumn(db, 'wallets', 'savings_item_id', 'INTEGER');
    await _addColumn(
        db, 'wallets', 'is_spendable', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumn(db, 'wallets', 'updated_at', 'TEXT');

    await _systemAccount(db, 'SYS-OPENING', 'Saldo inicial', 'equity');
    await _systemAccount(db, 'SYS-ADJUST', 'Ajustes de saldo', 'equity');
    await _systemAccount(db, 'SYS-FX', 'Diferencia de cambio', 'adjustment');
    await _systemAccount(db, 'SYS-SAVINGS', 'Ahorro histórico', 'equity');

    final accounts = await _tableExists(db, 'accounts')
        ? await db.query('accounts')
        : <Map<String, Object?>>[];
    for (final account in accounts) {
      await _referenceAccount(
        db,
        code: 'ASSET-A-${account['id']}',
        name: account['name'] as String,
        type: 'asset',
        currency: account['currency'] as String,
        referenceType: 'account',
        referenceId: account['id'] as int,
      );
    }
    final categories = await _tableExists(db, 'categories')
        ? await db.query('categories')
        : <Map<String, Object?>>[];
    for (final category in categories) {
      final type = category['type'] as String;
      if (type != 'expense' && type != 'income') continue;
      await _referenceAccount(
        db,
        code: '${type == 'expense' ? 'EXP' : 'INC'}-C-${category['id']}',
        name: category['name'] as String,
        type: type,
        currency: 'SOL',
        referenceType: 'category',
        referenceId: category['id'] as int,
      );
    }

    for (final account in accounts) {
      final initial = (account['initial_balance'] as num).toDouble();
      if (initial == 0) continue;
      await _simpleEntry(
        db,
        date: account['created_at'] as String,
        description: 'Saldo inicial - ${account['name']}',
        sourceType: 'opening_balance',
        sourceId: account['id'] as int,
        debitId: await _referenceId(db, 'account', account['id'] as int),
        creditId: await _codeId(db, 'SYS-OPENING'),
        amount: initial.abs(),
        currency: account['currency'] as String,
        reverse: initial < 0,
      );
    }

    final transfers = await _tableExists(db, 'transfers')
        ? await db.query('transfers', orderBy: 'id')
        : <Map<String, Object?>>[];
    for (final transfer in transfers) {
      await _migrateTransfer(db, transfer);
    }
    final transactions = await _tableExists(db, 'financial_transactions')
        ? await db.query('financial_transactions', orderBy: 'id')
        : <Map<String, Object?>>[];
    for (final transaction in transactions) {
      final comment = transaction['comment'] as String?;
      if (comment?.startsWith('Transferencia #') == true) continue;
      await _migrateTransaction(db, transaction);
    }

    // Preserve balances even if an older version changed the cached balance
    // without leaving a complete transaction trail.
    for (final account in accounts) {
      final expected = (account['current_balance'] as num).toDouble();
      final ledgerId = await _referenceId(db, 'account', account['id'] as int);
      final actual = await _assetBalance(db, ledgerId);
      final difference = expected - actual;
      if (difference.abs() < 0.000001) continue;
      await _simpleEntry(
        db,
        date: DateTime.now().toIso8601String(),
        description: 'Ajuste de migración verificable',
        sourceType: 'migration_adjustment',
        sourceId: account['id'] as int,
        debitId: ledgerId,
        creditId: await _codeId(db, 'SYS-ADJUST'),
        amount: difference.abs(),
        currency: account['currency'] as String,
        reverse: difference < 0,
      );
    }
  }

  static Future<void> migrateSavingsWalletFields(Database db) async {
    await _addColumn(db, 'wallets', 'savings_category_id', 'INTEGER');
    await _addColumn(db, 'wallets', 'savings_item_id', 'INTEGER');
    await _addColumn(db, 'wallets', 'is_active', 'INTEGER NOT NULL DEFAULT 1');
    await _addColumn(db, 'wallets', 'icon_key', 'TEXT');
    await _addColumn(db, 'wallets', 'color_hex', 'TEXT');
    await _addColumn(db, 'wallets', 'updated_at', 'TEXT');
  }

  static Future<void> migrateSavingsGoalVisualFields(Database db) async {
    await _addColumn(db, 'savings_goals', 'icon_key', 'TEXT');
    await _addColumn(db, 'savings_goals', 'color_hex', 'TEXT');
  }

  static Future<void> _migrateTransaction(
    Database db,
    Map<String, Object?> row,
  ) async {
    if (await _sourceExists(db, 'legacy_transaction', row['id'] as int)) return;
    final type = row['type'] as String;
    final asset = await _referenceId(db, 'account', row['account_id'] as int);
    int counterpart;
    if (type == 'expense' || type == 'income') {
      counterpart =
          await _referenceId(db, 'category', row['category_id'] as int);
    } else {
      counterpart = await _codeId(db, 'SYS-SAVINGS');
    }
    final isDebitAsset = type == 'income';
    final entryId = await _simpleEntry(
      db,
      date: row['date'] as String,
      description: (row['comment'] as String?) ?? 'Movimiento migrado',
      sourceType: 'legacy_transaction',
      sourceId: row['id'] as int,
      debitId: isDebitAsset ? asset : counterpart,
      creditId: isDebitAsset ? counterpart : asset,
      amount: (row['amount'] as num).toDouble(),
      currency: row['currency'] as String,
      exchangeRate: (row['exchange_rate'] as num?)?.toDouble(),
      baseAmount: (row['amount_in_base_currency'] as num?)?.toDouble(),
      budgetItemId:
          row['related_type'] == 'budget' ? row['related_id'] as int? : null,
      savingsItemId:
          row['related_type'] == 'savings' ? row['related_id'] as int? : null,
    );
    await db.update('financial_transactions', {'journal_entry_id': entryId},
        where: 'id = ?', whereArgs: [row['id']]);
  }

  static Future<void> _migrateTransfer(
    Database db,
    Map<String, Object?> row,
  ) async {
    if (await _sourceExists(db, 'legacy_transfer', row['id'] as int)) return;
    final from =
        await _referenceId(db, 'account', row['from_account_id'] as int);
    final to = await _referenceId(db, 'account', row['to_account_id'] as int);
    final fromAmount = (row['amount_from'] as num).toDouble();
    final toAmount = (row['amount_to'] as num).toDouble();
    final rate = (row['exchange_rate'] as num?)?.toDouble();
    final fromCurrency = row['currency_from'] as String;
    final toCurrency = row['currency_to'] as String;
    final fromBase =
        fromCurrency == 'SOL' ? fromAmount : fromAmount * (rate ?? 1);
    final toBase = toCurrency == 'SOL' ? toAmount : toAmount * (rate ?? 1);
    final entryId = await db.insert('journal_entries', {
      'date': row['date'],
      'description': (row['comment'] as String?) ?? 'Transferencia migrada',
      'source_type': 'legacy_transfer',
      'source_id': row['id'],
      'status': 'posted',
      'created_at': row['created_at'],
    });
    await _line(db, entryId, to, toAmount, 0, toCurrency, rate, toBase);
    await _line(db, entryId, from, 0, fromAmount, fromCurrency, rate, fromBase);
    final difference = fromBase - toBase;
    if (difference.abs() >= 0.000001) {
      final fx = await _codeId(db, 'SYS-FX');
      await _line(db, entryId, fx, difference < 0 ? -difference : 0,
          difference > 0 ? difference : 0, 'SOL', null, difference.abs());
    }
    await db.update('transfers', {'journal_entry_id': entryId},
        where: 'id = ?', whereArgs: [row['id']]);
  }

  static Future<int> _simpleEntry(
    Database db, {
    required String date,
    required String description,
    required String sourceType,
    required int sourceId,
    required int debitId,
    required int creditId,
    required double amount,
    required String currency,
    bool reverse = false,
    double? exchangeRate,
    double? baseAmount,
    int? budgetItemId,
    int? savingsItemId,
  }) async {
    final existing = await db.query('journal_entries',
        columns: ['id'],
        where: 'source_type = ? AND source_id = ?',
        whereArgs: [sourceType, sourceId],
        limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    final entryId = await db.insert('journal_entries', {
      'date': date,
      'description': description,
      'source_type': sourceType,
      'source_id': sourceId,
      'budget_item_id': budgetItemId,
      'savings_item_id': savingsItemId,
      'status': 'posted',
      'created_at': DateTime.now().toIso8601String(),
    });
    final base = baseAmount ??
        (currency == 'SOL' ? amount : amount * (exchangeRate ?? 1));
    await _line(db, entryId, reverse ? creditId : debitId, amount, 0, currency,
        exchangeRate, base);
    await _line(db, entryId, reverse ? debitId : creditId, 0, amount, currency,
        exchangeRate, base);
    return entryId;
  }

  static Future<void> _line(Database db, int entryId, int accountId,
      double debit, double credit, String currency, double? rate, double base) {
    return db.insert('journal_lines', {
      'journal_entry_id': entryId,
      'ledger_account_id': accountId,
      'debit': debit,
      'credit': credit,
      'currency': currency,
      'exchange_rate': rate,
      'base_amount': base,
    }).then((_) {});
  }

  static Future<int> _systemAccount(
      Database db, String code, String name, String type) async {
    final rows = await db.query('ledger_accounts',
        columns: ['id'], where: 'code = ?', whereArgs: [code], limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return db.insert('ledger_accounts', {
      'code': code,
      'name': name,
      'account_type': type,
      'currency': 'SOL',
      'is_active': 1,
    });
  }

  static Future<int> _referenceAccount(Database db,
      {required String code,
      required String name,
      required String type,
      required String currency,
      required String referenceType,
      required int referenceId}) async {
    final rows = await db.query('ledger_accounts',
        columns: ['id'],
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [referenceType, referenceId],
        limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return db.insert('ledger_accounts', {
      'code': code,
      'name': name,
      'account_type': type,
      'currency': currency,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'is_active': 1,
    });
  }

  static Future<int> _referenceId(Database db, String type, int id) async {
    final rows = await db.query('ledger_accounts',
        columns: ['id'],
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [type, id],
        limit: 1);
    if (rows.isEmpty) throw StateError('No ledger account for $type $id.');
    return rows.first['id'] as int;
  }

  static Future<int> _codeId(Database db, String code) async {
    final rows = await db.query('ledger_accounts',
        columns: ['id'], where: 'code = ?', whereArgs: [code], limit: 1);
    return rows.first['id'] as int;
  }

  static Future<bool> _sourceExists(Database db, String type, int id) async {
    final rows = await db.query('journal_entries',
        columns: ['id'],
        where: 'source_type = ? AND source_id = ?',
        whereArgs: [type, id],
        limit: 1);
    return rows.isNotEmpty;
  }

  static Future<double> _assetBalance(Database db, int ledgerId) async {
    final rows =
        await db.rawQuery('''SELECT COALESCE(SUM(l.debit - l.credit), 0) total
FROM journal_lines l JOIN journal_entries e ON e.id = l.journal_entry_id
WHERE l.ledger_account_id = ? AND e.status = 'posted' ''', [ledgerId]);
    return (rows.first['total'] as num).toDouble();
  }

  static Future<void> _addColumn(
      Database db, String table, String column, String definition) async {
    if (!await _tableExists(db, table)) return;
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
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
