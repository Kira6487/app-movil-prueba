import '../database/app_database.dart';
import '../models/transfer_model.dart';
import '../utils/money_utils.dart';

class TransferService {
  TransferService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> insertTransfer(TransferModel transfer) async {
    _validateTransfer(transfer);
    final db = await _database.database;
    return db.transaction((txn) async {
      final fromRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transfer.fromAccountId],
        limit: 1,
      );
      final toRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transfer.toAccountId],
        limit: 1,
      );
      if (fromRows.isEmpty || toRows.isEmpty) {
        throw StateError('Transfer accounts must exist.');
      }

      final fromCategoryId = await _getOrCreateCategory(
        txn,
        name: 'Transferencia enviada',
        type: 'system',
      );
      final toCategoryId = await _getOrCreateCategory(
        txn,
        name: 'Transferencia recibida',
        type: 'system',
      );
      final transferId = await txn.insert(
        'transfers',
        transfer.toMap()..remove('id'),
      );
      final transferComment = [
        'Transferencia #$transferId',
        if (transfer.comment != null && transfer.comment!.trim().isNotEmpty)
          transfer.comment!.trim(),
      ].join(' - ');

      final fromBalance = (fromRows.first['current_balance'] as num).toDouble();
      final toBalance = (toRows.first['current_balance'] as num).toDouble();
      await txn.update(
        'accounts',
        {'current_balance': fromBalance - transfer.amountFrom},
        where: 'id = ?',
        whereArgs: [transfer.fromAccountId],
      );
      await txn.update(
        'accounts',
        {'current_balance': toBalance + transfer.amountTo},
        where: 'id = ?',
        whereArgs: [transfer.toAccountId],
      );

      await txn.insert('financial_transactions', {
        'type': 'expense',
        'amount': transfer.amountFrom,
        'currency': transfer.currencyFrom,
        'exchange_rate': transfer.exchangeRate,
        'amount_in_base_currency': MoneyUtils.amountInBaseCurrency(
          amount: transfer.amountFrom,
          currency: transfer.currencyFrom,
          baseCurrency: 'SOL',
          exchangeRate: transfer.exchangeRate,
        ),
        'account_id': transfer.fromAccountId,
        'category_id': fromCategoryId,
        'date': transfer.date,
        'comment': transferComment,
        'created_at': transfer.createdAt,
      });
      await txn.insert('financial_transactions', {
        'type': 'income',
        'amount': transfer.amountTo,
        'currency': transfer.currencyTo,
        'exchange_rate': transfer.exchangeRate,
        'amount_in_base_currency': MoneyUtils.amountInBaseCurrency(
          amount: transfer.amountTo,
          currency: transfer.currencyTo,
          baseCurrency: 'SOL',
          exchangeRate: transfer.exchangeRate,
        ),
        'account_id': transfer.toAccountId,
        'category_id': toCategoryId,
        'date': transfer.date,
        'comment': transferComment,
        'created_at': transfer.createdAt,
      });

      return transferId;
    });
  }

  Future<List<TransferModel>> getAllTransfers() async {
    final db = await _database.database;
    final rows = await db.query('transfers', orderBy: 'date DESC, id DESC');
    return rows.map(TransferModel.fromMap).toList();
  }

  Future<List<TransferModel>> getTransfersByAccount(int accountId) async {
    final db = await _database.database;
    final rows = await db.query(
      'transfers',
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransferModel.fromMap).toList();
  }

  void _validateTransfer(TransferModel transfer) {
    if (transfer.fromAccountId == transfer.toAccountId) {
      throw ArgumentError('Transfer accounts must be different.');
    }
    if (transfer.amountFrom <= 0 || transfer.amountTo <= 0) {
      throw ArgumentError('Transfer amounts must be greater than zero.');
    }
    if (transfer.currencyFrom != 'SOL' && transfer.currencyFrom != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
    if (transfer.currencyTo != 'SOL' && transfer.currencyTo != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
    if (transfer.currencyFrom != transfer.currencyTo &&
        (transfer.exchangeRate == null || transfer.exchangeRate! <= 0)) {
      throw ArgumentError('Exchange rate is required for mixed currencies.');
    }
  }

  Future<int> _getOrCreateCategory(
    dynamic txn, {
    required String name,
    required String type,
  }) async {
    final rows = await txn.query(
      'categories',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;

    return txn.insert('categories', {
      'name': name,
      'type': type,
      'icon': 'transfer',
      'color': '#005FD1',
      'icon_key': 'transfer',
      'color_hex': '#005FD1',
      'sort_order': 0,
      'is_active': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
