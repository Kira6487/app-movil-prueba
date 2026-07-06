import 'financial_transaction_model.dart';

class TransactionHistoryItem {
  const TransactionHistoryItem({
    required this.transaction,
    required this.accountName,
    required this.categoryName,
  });

  final FinancialTransactionModel transaction;
  final String accountName;
  final String categoryName;

  factory TransactionHistoryItem.fromMap(Map<String, Object?> map) {
    return TransactionHistoryItem(
      transaction: FinancialTransactionModel.fromMap(map),
      accountName: map['account_name'] as String? ?? 'Cuenta',
      categoryName: map['category_name'] as String? ?? 'Categoría',
    );
  }
}
