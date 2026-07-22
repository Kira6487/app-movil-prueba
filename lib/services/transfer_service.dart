import '../database/app_database.dart';
import '../models/transfer_model.dart';
import '../models/ledger_models.dart';
import '../utils/money_utils.dart';
import 'ledger_service.dart';

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
      await _validateWalletEndpoint(
          txn, transfer.fromWalletId, transfer.fromAccountId, 'origin');
      await _validateWalletEndpoint(
          txn, transfer.toWalletId, transfer.toAccountId, 'destination');
      await _validateSavingsItem(txn, transfer);

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
      if (transfer.fromWalletId == null) {
        await txn.update(
            'accounts', {'current_balance': fromBalance - transfer.amountFrom},
            where: 'id = ?', whereArgs: [transfer.fromAccountId]);
      }
      if (transfer.toWalletId == null) {
        await txn.update(
            'accounts', {'current_balance': toBalance + transfer.amountTo},
            where: 'id = ?', whereArgs: [transfer.toAccountId]);
      }

      final fromLedgerId = transfer.fromWalletId == null
          ? await LedgerService.referenceAccountId(
              txn, 'account', transfer.fromAccountId)
          : await LedgerService.referenceAccountId(
              txn, 'wallet', transfer.fromWalletId!);
      final toLedgerId = transfer.toWalletId == null
          ? await LedgerService.referenceAccountId(
              txn, 'account', transfer.toAccountId)
          : await LedgerService.referenceAccountId(
              txn, 'wallet', transfer.toWalletId!);
      final effectiveRate = transfer.exchangeRate ?? 1;
      final fromBase = transfer.currencyFrom == 'SOL'
          ? transfer.amountFrom
          : transfer.amountFrom * effectiveRate;
      final toBase = transfer.currencyTo == 'SOL'
          ? transfer.amountTo
          : transfer.amountTo * effectiveRate;
      final lines = <JournalLineDraft>[
        JournalLineDraft(
            ledgerAccountId: toLedgerId,
            debit: transfer.amountTo,
            currency: transfer.currencyTo,
            exchangeRate: transfer.exchangeRate,
            baseAmount: toBase),
        JournalLineDraft(
            ledgerAccountId: fromLedgerId,
            credit: transfer.amountFrom,
            currency: transfer.currencyFrom,
            exchangeRate: transfer.exchangeRate,
            baseAmount: fromBase),
      ];
      final difference = fromBase - toBase;
      if (difference.abs() >= LedgerService.tolerance) {
        final fxId = await LedgerService.codeAccountId(txn, 'SYS-FX');
        lines.add(JournalLineDraft(
          ledgerAccountId: fxId,
          debit: difference > 0 ? difference : 0,
          credit: difference < 0 ? -difference : 0,
          currency: 'SOL',
          baseAmount: difference.abs(),
        ));
      }
      final journalId = await LedgerService.postEntryInTransaction(
        txn,
        JournalEntryDraft(
          date: transfer.date,
          description: transferComment,
          sourceType: 'transfer',
          sourceId: transferId,
          savingsItemId: transfer.savingsItemId,
          createdAt: transfer.createdAt,
          lines: lines,
        ),
      );
      await txn.update('transfers', {'journal_entry_id': journalId},
          where: 'id = ?', whereArgs: [transferId]);

      if (transfer.fromWalletId == null && transfer.toWalletId == null) {
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
      }

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
    if (transfer.fromAccountId == transfer.toAccountId &&
        transfer.fromWalletId == transfer.toWalletId) {
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

  Future<void> _validateWalletEndpoint(
    dynamic txn,
    int? walletId,
    int accountId,
    String label,
  ) async {
    if (walletId == null) return;
    final rows = await txn.query('wallets',
        columns: ['account_id', 'is_active'],
        where: 'id = ?',
        whereArgs: [walletId],
        limit: 1);
    if (rows.isEmpty ||
        rows.first['account_id'] != accountId ||
        rows.first['is_active'] != 1) {
      throw StateError('The $label wallet is not active for this account.');
    }
  }

  Future<void> _validateSavingsItem(
    dynamic txn,
    TransferModel transfer,
  ) async {
    final walletId = transfer.toWalletId ?? transfer.fromWalletId;
    if (walletId == null) return;
    final rows = await txn.query('wallets',
        columns: ['savings_category_id', 'savings_item_id', 'currency'],
        where: 'id = ?',
        whereArgs: [walletId],
        limit: 1);
    if (rows.isEmpty) throw StateError('Savings wallet does not exist.');
    // Legacy wallets without category metadata keep their historical flow.
    if (rows.first['savings_category_id'] == null) return;
    final itemId =
        transfer.savingsItemId ?? rows.first['savings_item_id'] as int?;
    if (itemId == null) {
      throw ArgumentError('La alcancía necesita una contrapartida de ahorro.');
    }
    final item = await txn.rawQuery('''
SELECT g.id FROM savings_goals g
JOIN categories c ON c.id = g.category_id
WHERE g.id = ? AND g.is_active = 1 AND c.type = 'savings'
  AND g.category_id = ? AND g.currency = ?
''', [itemId, rows.first['savings_category_id'], rows.first['currency']]);
    if (item.isEmpty) {
      throw ArgumentError(
          'La contrapartida debe ser un objetivo de ahorro compatible.');
    }
  }
}
