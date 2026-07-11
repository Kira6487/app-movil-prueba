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
    this.relatedType,
    this.relatedId,
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
  final String? relatedType;
  final int? relatedId;
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
      relatedType: _readString(map, 'related_type'),
      relatedId: (map['related_id'] as num?)?.toInt(),
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
      'related_type': relatedType,
      'related_id': relatedId,
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
    String? relatedType,
    int? relatedId,
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
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String? _readString(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) return null;
    return map[key] as String?;
  }
}

class TransactionRelatedType {
  const TransactionRelatedType._();

  static const budget = 'budget';
  static const savings = 'savings';

  static const values = [budget, savings];
}
