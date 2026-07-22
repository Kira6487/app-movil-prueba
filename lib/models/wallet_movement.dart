class WalletMovement {
  const WalletMovement({
    required this.date,
    required this.type,
    required this.amount,
    required this.currency,
    required this.comment,
    this.savingsItemId,
  });

  final String date;
  final String type;
  final double amount;
  final String currency;
  final String comment;
  final int? savingsItemId;

  factory WalletMovement.fromMap(Map<String, Object?> map) => WalletMovement(
        date: map['date'] as String,
        type: map['movement_type'] as String? ?? 'Movimiento',
        amount: (map['movement_amount'] as num).toDouble(),
        currency: map['currency'] as String,
        comment: map['comment'] as String? ?? '',
        savingsItemId: map['savings_item_id'] as int?,
      );
}
