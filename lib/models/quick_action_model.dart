class QuickActionModel {
  const QuickActionModel({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.accountId,
    this.budgetItemId,
    this.comment,
    this.icon,
    this.color,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double amount;
  final String currency;
  final int? categoryId;
  final int? accountId;
  final int? budgetItemId;
  final String? comment;
  final String? icon;
  final String? color;
  final bool isActive;
  final int sortOrder;
  final String createdAt;

  factory QuickActionModel.fromMap(Map<String, Object?> map) =>
      QuickActionModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        categoryId: map['category_id'] as int?,
        accountId: map['account_id'] as int?,
        budgetItemId: map['budget_item_id'] as int?,
        comment: map['comment'] as String?,
        icon: map['icon'] as String?,
        color: map['color'] as String?,
        isActive: (map['is_active'] as int) == 1,
        sortOrder: map['sort_order'] as int,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currency,
        'category_id': categoryId,
        'account_id': accountId,
        'budget_item_id': budgetItemId,
        'comment': comment,
        'icon': icon,
        'color': color,
        'is_active': isActive ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  QuickActionModel copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    int? categoryId,
    int? accountId,
    int? budgetItemId,
    String? comment,
    String? icon,
    String? color,
    bool? isActive,
    int? sortOrder,
    String? createdAt,
  }) {
    return QuickActionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      budgetItemId: budgetItemId ?? this.budgetItemId,
      comment: comment ?? this.comment,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
