class TransferModel {
  const TransferModel({
    this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountFrom,
    required this.currencyFrom,
    required this.amountTo,
    required this.currencyTo,
    this.exchangeRate,
    required this.date,
    this.comment,
    required this.createdAt,
  });

  final int? id;
  final int fromAccountId;
  final int toAccountId;
  final double amountFrom;
  final String currencyFrom;
  final double amountTo;
  final String currencyTo;
  final double? exchangeRate;
  final String date;
  final String? comment;
  final String createdAt;

  factory TransferModel.fromMap(Map<String, Object?> map) {
    return TransferModel(
      id: map['id'] as int?,
      fromAccountId: map['from_account_id'] as int,
      toAccountId: map['to_account_id'] as int,
      amountFrom: (map['amount_from'] as num).toDouble(),
      currencyFrom: map['currency_from'] as String,
      amountTo: (map['amount_to'] as num).toDouble(),
      currencyTo: map['currency_to'] as String,
      exchangeRate: (map['exchange_rate'] as num?)?.toDouble(),
      date: map['date'] as String,
      comment: map['comment'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount_from': amountFrom,
      'currency_from': currencyFrom,
      'amount_to': amountTo,
      'currency_to': currencyTo,
      'exchange_rate': exchangeRate,
      'date': date,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  TransferModel copyWith({
    int? id,
    int? fromAccountId,
    int? toAccountId,
    double? amountFrom,
    String? currencyFrom,
    double? amountTo,
    String? currencyTo,
    double? exchangeRate,
    String? date,
    String? comment,
    String? createdAt,
  }) {
    return TransferModel(
      id: id ?? this.id,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amountFrom: amountFrom ?? this.amountFrom,
      currencyFrom: currencyFrom ?? this.currencyFrom,
      amountTo: amountTo ?? this.amountTo,
      currencyTo: currencyTo ?? this.currencyTo,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
