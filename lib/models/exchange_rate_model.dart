class ExchangeRateModel {
  const ExchangeRateModel({
    this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.date,
    required this.createdAt,
  });

  final int? id;
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final String date;
  final String createdAt;

  factory ExchangeRateModel.fromMap(Map<String, Object?> map) =>
      ExchangeRateModel(
        id: map['id'] as int?,
        fromCurrency: map['from_currency'] as String,
        toCurrency: map['to_currency'] as String,
        rate: (map['rate'] as num).toDouble(),
        date: map['date'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'rate': rate,
        'date': date,
        'created_at': createdAt,
      };

  ExchangeRateModel copyWith({
    int? id,
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    String? date,
    String? createdAt,
  }) {
    return ExchangeRateModel(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
