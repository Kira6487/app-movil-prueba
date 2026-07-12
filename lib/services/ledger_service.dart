import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/ledger_models.dart';

class LedgerService {
  LedgerService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  static const tolerance = 0.000001;

  Future<int> postEntry(JournalEntryDraft entry) async {
    final db = await _database.database;
    return db.transaction((txn) => postEntryInTransaction(txn, entry));
  }

  static Future<int> postEntryInTransaction(
    DatabaseExecutor txn,
    JournalEntryDraft entry,
  ) async {
    _validate(entry);
    if (entry.sourceId != null) {
      final existing = await txn.query('journal_entries',
          columns: ['id'],
          where: 'source_type = ? AND source_id = ?',
          whereArgs: [entry.sourceType, entry.sourceId],
          limit: 1);
      if (existing.isNotEmpty) return existing.first['id'] as int;
    }
    final id = await txn.insert('journal_entries', {
      'date': entry.date,
      'description': entry.description,
      'source_type': entry.sourceType,
      'source_id': entry.sourceId,
      'budget_item_id': entry.budgetItemId,
      'savings_item_id': entry.savingsItemId,
      'status': entry.status,
      'created_at': entry.createdAt,
    });
    for (final line in entry.lines) {
      await txn.insert('journal_lines', {
        'journal_entry_id': id,
        'ledger_account_id': line.ledgerAccountId,
        'debit': line.debit,
        'credit': line.credit,
        'currency': line.currency,
        'exchange_rate': line.exchangeRate,
        'base_amount': line.baseAmount ?? _baseValue(line),
      });
    }
    return id;
  }

  Future<List<LedgerAccountModel>> getAccounts() async {
    final db = await _database.database;
    final rows = await db.query('ledger_accounts', orderBy: 'code');
    return rows.map(LedgerAccountModel.fromMap).toList();
  }

  Future<double> getBalance(int ledgerAccountId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT COALESCE(SUM(l.debit - l.credit), 0) AS total
FROM journal_lines l
JOIN journal_entries e ON e.id = l.journal_entry_id
WHERE l.ledger_account_id = ? AND e.status = 'posted'
''', [ledgerAccountId]);
    return (rows.first['total'] as num).toDouble();
  }

  static Future<int> referenceAccountId(
    DatabaseExecutor txn,
    String referenceType,
    int referenceId,
  ) async {
    final rows = await txn.query('ledger_accounts',
        columns: ['id'],
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [referenceType, referenceId],
        limit: 1);
    if (rows.isEmpty) {
      throw StateError('No ledger account for $referenceType $referenceId.');
    }
    return rows.first['id'] as int;
  }

  static Future<int> codeAccountId(DatabaseExecutor txn, String code) async {
    final rows = await txn.query('ledger_accounts',
        columns: ['id'], where: 'code = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) throw StateError('No ledger account $code.');
    return rows.first['id'] as int;
  }

  static Future<int> ensureReferenceAccount(
    DatabaseExecutor txn, {
    required String code,
    required String name,
    required String type,
    required String currency,
    required String referenceType,
    required int referenceId,
    int? parentAccountId,
  }) async {
    final rows = await txn.query('ledger_accounts',
        columns: ['id'],
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [referenceType, referenceId],
        limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return txn.insert('ledger_accounts', {
      'code': code,
      'name': name,
      'account_type': type,
      'parent_account_id': parentAccountId,
      'currency': currency,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'is_active': 1,
    });
  }

  static void _validate(JournalEntryDraft entry) {
    if (entry.lines.length < 2) {
      throw ArgumentError('A journal entry requires at least two lines.');
    }
    var debitBase = 0.0;
    var creditBase = 0.0;
    for (final line in entry.lines) {
      if (line.debit < 0 ||
          line.credit < 0 ||
          (line.debit > 0) == (line.credit > 0)) {
        throw ArgumentError(
            'Each line must have one positive debit or credit.');
      }
      final base = line.baseAmount ?? _baseValue(line);
      if (line.debit > 0) debitBase += base;
      if (line.credit > 0) creditBase += base;
    }
    if ((debitBase - creditBase).abs() > tolerance) {
      throw ArgumentError('Journal entry is not balanced in base currency.');
    }
  }

  static double _baseValue(JournalLineDraft line) {
    final amount = line.debit > 0 ? line.debit : line.credit;
    if (line.currency == 'SOL') return amount;
    final rate = line.exchangeRate;
    if (rate == null || rate <= 0) {
      throw ArgumentError('Exchange rate is required for non-base currency.');
    }
    return amount * rate;
  }
}
