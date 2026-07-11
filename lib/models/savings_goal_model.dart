class SavingsGoalModel {
  const SavingsGoalModel({
    this.id,
    required this.name,
    required this.categoryId,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.currency,
    this.plannedMonthlyAmount,
    this.deadline,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final int categoryId;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final double? plannedMonthlyAmount;
  final String? deadline;
  final bool isActive;
  final String createdAt;

  factory SavingsGoalModel.fromMap(Map<String, Object?> map) =>
      SavingsGoalModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        categoryId: map['category_id'] as int,
        targetAmount: (map['target_amount'] as num).toDouble(),
        currentAmount: (map['current_amount'] as num).toDouble(),
        currency: map['currency'] as String,
        plannedMonthlyAmount:
            (map['planned_monthly_amount'] as num?)?.toDouble(),
        deadline: map['deadline'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'currency': currency,
        'planned_monthly_amount': plannedMonthlyAmount,
        'deadline': deadline,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  SavingsGoalModel copyWith({
    int? id,
    String? name,
    int? categoryId,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    double? plannedMonthlyAmount,
    String? deadline,
    bool? isActive,
    String? createdAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      plannedMonthlyAmount: plannedMonthlyAmount ?? this.plannedMonthlyAmount,
      deadline: deadline ?? this.deadline,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
