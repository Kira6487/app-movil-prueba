enum TransactionType { income, expense, transfer }

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    this.category,
    this.comment,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final DateTime date;
  final String? category;
  final String? comment;
}
