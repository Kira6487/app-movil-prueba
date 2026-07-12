class WalletModel {
  const WalletModel({
    this.id,
    required this.name,
    required this.accountId,
    this.ledgerAccountId,
    this.amount = 0,
    required this.currency,
    this.type = 'piggyBank',
    this.iconKey,
    this.colorHex,
    this.savingsCategoryId,
    this.savingsItemId,
    this.isSpendable = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final int accountId;
  final int? ledgerAccountId;
  final double amount;
  final String currency;
  final String type;
  final String? iconKey;
  final String? colorHex;
  final int? savingsCategoryId;
  final int? savingsItemId;
  final bool isSpendable;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  factory WalletModel.fromMap(Map<String, Object?> map) => WalletModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        accountId: map['account_id'] as int,
        ledgerAccountId: map['ledger_account_id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        type: (map['wallet_type'] as String?) ?? 'piggyBank',
        iconKey: map['icon_key'] as String?,
        colorHex: map['color_hex'] as String?,
        savingsCategoryId: map['savings_category_id'] as int?,
        savingsItemId: map['savings_item_id'] as int?,
        isSpendable: (map['is_spendable'] as int? ?? 0) == 1,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'account_id': accountId,
        'ledger_account_id': ledgerAccountId,
        'amount': amount,
        'currency': currency,
        'wallet_type': type,
        'icon_key': iconKey,
        'color_hex': colorHex,
        'savings_category_id': savingsCategoryId,
        'savings_item_id': savingsItemId,
        'is_spendable': isSpendable ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  WalletModel copyWith({
    int? id,
    String? name,
    int? accountId,
    int? ledgerAccountId,
    double? amount,
    String? currency,
    String? type,
    String? iconKey,
    String? colorHex,
    int? savingsCategoryId,
    int? savingsItemId,
    bool? isSpendable,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      ledgerAccountId: ledgerAccountId ?? this.ledgerAccountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      savingsCategoryId: savingsCategoryId ?? this.savingsCategoryId,
      savingsItemId: savingsItemId ?? this.savingsItemId,
      isSpendable: isSpendable ?? this.isSpendable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
