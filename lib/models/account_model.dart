class AccountModel {
  const AccountModel({
    this.id,
    required this.name,
    required this.accountType,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance,
    this.isHiddenFromBudget = false,
    this.color,
    this.icon,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String accountType;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final bool isHiddenFromBudget;
  final String? color;
  final String? icon;
  final String createdAt;

  factory AccountModel.fromMap(Map<String, Object?> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      currency: map['currency'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      currentBalance: (map['current_balance'] as num).toDouble(),
      isHiddenFromBudget: (map['is_hidden_from_budget'] as int) == 1,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'account_type': accountType,
      'currency': currency,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'is_hidden_from_budget': isHiddenFromBudget ? 1 : 0,
      'color': color,
      'icon': icon,
      'created_at': createdAt,
    };
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? accountType,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    bool? isHiddenFromBudget,
    String? color,
    String? icon,
    String? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isHiddenFromBudget: isHiddenFromBudget ?? this.isHiddenFromBudget,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
