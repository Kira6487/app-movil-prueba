import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/financial_transaction_model.dart';
import '../models/transaction_history_item.dart';
import '../models/ledger_models.dart';
import '../utils/money_utils.dart';
import 'budget_service.dart';
import 'ledger_service.dart';

class TransactionService {
  TransactionService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> insertTransaction(FinancialTransactionModel transaction) async {
    _validateTransaction(transaction);
    await _validateRelatedItem(transaction);

    final db = await _database.database;
    return db.transaction((txn) async {
      final accountRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transaction.accountId],
        limit: 1,
      );
      if (accountRows.isEmpty) {
        throw StateError('Account ${transaction.accountId} does not exist.');
      }

      final categoryRows = await txn.query(
        'categories',
        columns: ['id', 'type'],
        where: 'id = ?',
        whereArgs: [transaction.categoryId],
        limit: 1,
      );
      if (categoryRows.isEmpty) {
        throw StateError('Category ${transaction.categoryId} does not exist.');
      }
      _validateCategoryScope(transaction, categoryRows.first['type'] as String);

      final currentBalance =
          (accountRows.first['current_balance'] as num).toDouble();
      final delta = _balanceDelta(transaction);
      final amountInBaseCurrency = transaction.amountInBaseCurrency ??
          MoneyUtils.amountInBaseCurrency(
            amount: transaction.amount,
            currency: transaction.currency,
            baseCurrency: 'SOL',
            exchangeRate: transaction.exchangeRate,
          );

      final data = transaction
          .copyWith(amountInBaseCurrency: amountInBaseCurrency)
          .toMap()
        ..remove('id');
      final transactionId = await txn.insert('financial_transactions', data);
      final journalId = await _postLedgerEntry(
        txn,
        transaction.copyWith(amountInBaseCurrency: amountInBaseCurrency),
        sourceType: 'transaction',
        sourceId: transactionId,
      );
      await txn.update(
          'financial_transactions', {'journal_entry_id': journalId},
          where: 'id = ?', whereArgs: [transactionId]);
      await txn.update('accounts', {'current_balance': currentBalance + delta},
          where: 'id = ?', whereArgs: [transaction.accountId]);
      return transactionId;
    });
  }

  Future<List<FinancialTransactionModel>> getAllTransactions() async {
    final db = await _database.database;
    final rows =
        await db.query('financial_transactions', orderBy: 'date DESC, id DESC');
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<FinancialTransactionModel?> getTransactionById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FinancialTransactionModel.fromMap(rows.first);
  }

  Future<List<TransactionHistoryItem>> getLatestTransactions({
    int limit = 10,
  }) async {
    return getTransactionHistory(limit: limit);
  }

  Future<List<TransactionHistoryItem>> getTransactionHistory({
    int? limit,
    int? accountId,
    int? categoryId,
    String? type,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (accountId != null) {
      where.add('t.account_id = ?');
      args.add(accountId);
    }
    if (categoryId != null) {
      where.add('t.category_id = ?');
      args.add(categoryId);
    }
    if (type != null && type.isNotEmpty) {
      where.add('t.type = ?');
      args.add(type);
    }
    if (currency != null && currency.isNotEmpty) {
      where.add('t.currency = ?');
      args.add(currency);
    }
    if (startDate != null) {
      where.add('t.date >= ?');
      args.add(DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String());
    }
    if (endDate != null) {
      where.add('t.date < ?');
      args.add(DateTime(endDate.year, endDate.month, endDate.day + 1)
          .toIso8601String());
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final limitClause = limit == null ? '' : 'LIMIT ?';
    if (limit != null) args.add(limit);

    final rows = await db.rawQuery(
      '''
SELECT
  t.id,
  t.type,
  t.amount,
  t.currency,
  t.exchange_rate,
  t.amount_in_base_currency,
  t.account_id,
  t.category_id,
  t.related_type,
  t.related_id,
  t.date,
  t.comment,
  t.created_at,
  a.name AS account_name,
  c.name AS category_name
FROM financial_transactions t
INNER JOIN accounts a ON a.id = t.account_id
INNER JOIN categories c ON c.id = t.category_id
$whereClause
ORDER BY t.date DESC, t.id DESC
$limitClause
''',
      args,
    );
    return rows.map(TransactionHistoryItem.fromMap).toList();
  }

  Future<List<TransactionHistoryItem>> getTransactionHistoryByAccount(
    int accountId,
  ) {
    return getTransactionHistory(accountId: accountId);
  }

  Future<List<FinancialTransactionModel>> getTransactionsByMonth(
      int year, int month) async {
    final start = DateTime(year, month).toIso8601String();
    final end = DateTime(year, month + 1).toIso8601String();
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<List<FinancialTransactionModel>> getTransactionsByAccount(
      int accountId) async {
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<List<FinancialTransactionModel>> getTransactionsByCategory(
      int categoryId) async {
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<int> updateTransaction(FinancialTransactionModel transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError('Transaction id is required for update.');
    }
    _validateTransaction(transaction);
    await _validateRelatedItem(transaction);

    final db = await _database.database;
    return db.transaction((txn) async {
      final oldRows = await txn.query(
        'financial_transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (oldRows.isEmpty) {
        throw StateError('Transaction $id does not exist.');
      }
      final oldTransaction = FinancialTransactionModel.fromMap(oldRows.first);
      final oldJournalId = oldRows.first['journal_entry_id'] as int?;

      final accountRows = await txn.query(
        'accounts',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [transaction.accountId],
        limit: 1,
      );
      if (accountRows.isEmpty) {
        throw StateError('Account ${transaction.accountId} does not exist.');
      }

      final categoryRows = await txn.query(
        'categories',
        columns: ['id', 'type'],
        where: 'id = ?',
        whereArgs: [transaction.categoryId],
        limit: 1,
      );
      if (categoryRows.isEmpty) {
        throw StateError('Category ${transaction.categoryId} does not exist.');
      }
      _validateCategoryScope(transaction, categoryRows.first['type'] as String);

      await _applyBalanceDelta(
        txn,
        oldTransaction.accountId,
        -_balanceDelta(oldTransaction),
      );
      await _applyBalanceDelta(
        txn,
        transaction.accountId,
        _balanceDelta(transaction),
      );

      final amountInBaseCurrency = transaction.amountInBaseCurrency ??
          MoneyUtils.amountInBaseCurrency(
            amount: transaction.amount,
            currency: transaction.currency,
            baseCurrency: 'SOL',
            exchangeRate: transaction.exchangeRate,
          );

      final data = transaction
          .copyWith(amountInBaseCurrency: amountInBaseCurrency)
          .toMap()
        ..remove('id');
      final updated = await txn.update(
        'financial_transactions',
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (oldJournalId != null) {
        await txn.update('journal_entries', {'status': 'void'},
            where: 'id = ?', whereArgs: [oldJournalId]);
      }
      final journalId = await _postLedgerEntry(
        txn,
        transaction.copyWith(amountInBaseCurrency: amountInBaseCurrency),
        sourceType: 'transaction_revision',
      );
      await txn.update(
          'financial_transactions', {'journal_entry_id': journalId},
          where: 'id = ?', whereArgs: [id]);
      return updated;
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'financial_transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return 0;
      }
      final transaction = FinancialTransactionModel.fromMap(rows.first);
      final journalId = rows.first['journal_entry_id'] as int?;
      await _applyBalanceDelta(
        txn,
        transaction.accountId,
        -_balanceDelta(transaction),
      );
      if (journalId != null) {
        await txn.update('journal_entries', {'status': 'void'},
            where: 'id = ?', whereArgs: [journalId]);
      }
      return txn.delete(
        'financial_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  void _validateTransaction(FinancialTransactionModel transaction) {
    if (transaction.type != 'income' &&
        transaction.type != 'expense' &&
        transaction.type != 'savings') {
      throw ArgumentError(
        'Financial transaction type must be income, expense or savings.',
      );
    }
    if (transaction.amount <= 0) {
      throw ArgumentError('Transaction amount must be greater than zero.');
    }
    if (transaction.accountId <= 0) {
      throw ArgumentError('A valid account is required.');
    }
    if (transaction.categoryId <= 0) {
      throw ArgumentError('A valid category is required.');
    }
    if (transaction.currency != 'SOL' && transaction.currency != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
    if (transaction.currency == 'USD' &&
        transaction.exchangeRate != null &&
        transaction.exchangeRate! <= 0) {
      throw ArgumentError('Exchange rate must be greater than zero.');
    }
    final relatedType = transaction.relatedType;
    if (relatedType != null &&
        !TransactionRelatedType.values.contains(relatedType)) {
      throw ArgumentError('Related type is not valid.');
    }
    if ((relatedType == null) != (transaction.relatedId == null)) {
      throw ArgumentError('Related type and id must be saved together.');
    }
  }

  double _balanceDelta(FinancialTransactionModel transaction) {
    return transaction.type == 'income'
        ? transaction.amount
        : -transaction.amount;
  }

  void _validateCategoryScope(
    FinancialTransactionModel transaction,
    String categoryType,
  ) {
    final systemComment = transaction.comment ?? '';
    final isSystemMovement = categoryType == CategoryScope.system ||
        systemComment.startsWith('Transferencia #') ||
        systemComment.startsWith('Ajuste Manual');
    if (isSystemMovement) return;

    final expectedScope = switch (transaction.type) {
      'expense' => CategoryScope.expense,
      'income' => CategoryScope.income,
      'savings' => CategoryScope.savings,
      _ => '',
    };
    if (categoryType != expectedScope) {
      throw ArgumentError('Category type does not match transaction type.');
    }
  }

  Future<void> _validateRelatedItem(
    FinancialTransactionModel transaction,
  ) async {
    final relatedType = transaction.relatedType;
    final relatedId = transaction.relatedId;
    if (relatedType == null || relatedId == null) return;

    if (relatedType == TransactionRelatedType.budget &&
        transaction.type != 'expense') {
      throw ArgumentError('Only expenses can be related to budgets.');
    }
    if (relatedType == TransactionRelatedType.savings &&
        transaction.type != 'savings') {
      throw ArgumentError('Only savings movements can be related to savings.');
    }

    final options = await BudgetService(database: _database).getRelatedOptions(
      categoryId: transaction.categoryId,
      date: DateTime.parse(transaction.date),
      operationType: transaction.type,
    );
    final valid = options.any(
      (option) => option.type == relatedType && option.id == relatedId,
    );
    if (!valid) {
      throw ArgumentError('Related item is not compatible with this movement.');
    }
  }

  Future<void> _applyBalanceDelta(
    dynamic txn,
    int accountId,
    double delta,
  ) async {
    final rows = await txn.query(
      'accounts',
      columns: ['current_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Account $accountId does not exist.');
    }
    final currentBalance = (rows.first['current_balance'] as num).toDouble();
    await txn.update(
      'accounts',
      {'current_balance': currentBalance + delta},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<int> _postLedgerEntry(
    DatabaseExecutor txn,
    FinancialTransactionModel transaction, {
    required String sourceType,
    int? sourceId,
  }) async {
    final assetId = await LedgerService.referenceAccountId(
        txn, 'account', transaction.accountId);
    final counterpartId = transaction.type == 'savings'
        ? await LedgerService.codeAccountId(txn, 'SYS-SAVINGS')
        : await LedgerService.referenceAccountId(
            txn, 'category', transaction.categoryId);
    final assetDebit = transaction.type == 'income';
    final base = transaction.amountInBaseCurrency ?? transaction.amount;
    return LedgerService.postEntryInTransaction(
      txn,
      JournalEntryDraft(
        date: transaction.date,
        description: transaction.comment ?? _description(transaction.type),
        sourceType: sourceType,
        sourceId: sourceId,
        budgetItemId: transaction.relatedType == TransactionRelatedType.budget
            ? transaction.relatedId
            : null,
        savingsItemId: transaction.relatedType == TransactionRelatedType.savings
            ? transaction.relatedId
            : null,
        createdAt: transaction.createdAt,
        lines: [
          JournalLineDraft(
            ledgerAccountId: assetDebit ? assetId : counterpartId,
            debit: transaction.amount,
            currency: transaction.currency,
            exchangeRate: transaction.exchangeRate,
            baseAmount: base,
          ),
          JournalLineDraft(
            ledgerAccountId: assetDebit ? counterpartId : assetId,
            credit: transaction.amount,
            currency: transaction.currency,
            exchangeRate: transaction.exchangeRate,
            baseAmount: base,
          ),
        ],
      ),
    );
  }

  String _description(String type) => switch (type) {
        'expense' => 'Gasto',
        'income' => 'Ingreso',
        _ => 'Ahorro',
      };
}
