class WalletModel {
  const WalletModel({
    this.id,
    required this.name,
    required this.accountId,
    this.amount = 0,
    required this.currency,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final int accountId;
  final double amount;
  final String currency;
  final bool isActive;
  final String createdAt;

  factory WalletModel.fromMap(Map<String, Object?> map) => WalletModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        accountId: map['account_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'account_id': accountId,
        'amount': amount,
        'currency': currency,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  WalletModel copyWith({
    int? id,
    String? name,
    int? accountId,
    double? amount,
    String? currency,
    bool? isActive,
    String? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
