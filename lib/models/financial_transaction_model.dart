class FinancialTransactionModel {
  const FinancialTransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.currency,
    this.exchangeRate,
    this.amountInBaseCurrency,
    required this.accountId,
    required this.categoryId,
    required this.date,
    this.comment,
    required this.createdAt,
  });

  final int? id;
  final String type;
  final double amount;
  final String currency;
  final double? exchangeRate;
  final double? amountInBaseCurrency;
  final int accountId;
  final int categoryId;
  final String date;
  final String? comment;
  final String createdAt;

  factory FinancialTransactionModel.fromMap(Map<String, Object?> map) {
    return FinancialTransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble(),
      amountInBaseCurrency:
          (map['amount_in_base_currency'] as num?)?.toDouble(),
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int,
      date: map['date'] as String,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'amount_in_base_currency': amountInBaseCurrency,
      'account_id': accountId,
      'category_id': categoryId,
      'date': date,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  FinancialTransactionModel copyWith({
    int? id,
    String? type,
    double? amount,
    String? currency,
    double? exchangeRate,
    double? amountInBaseCurrency,
    int? accountId,
    int? categoryId,
    String? date,
    String? comment,
    String? createdAt,
  }) {
    return FinancialTransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      amountInBaseCurrency: amountInBaseCurrency ?? this.amountInBaseCurrency,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
