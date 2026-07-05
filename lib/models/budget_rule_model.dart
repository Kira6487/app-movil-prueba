class BudgetRuleModel {
  const BudgetRuleModel({
    this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.recurrenceType,
    this.selectedWeekdays,
    this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final int categoryId;
  final double amount;
  final String currency;
  final String recurrenceType;
  final String? selectedWeekdays;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;

  factory BudgetRuleModel.fromMap(Map<String, Object?> map) => BudgetRuleModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        categoryId: map['category_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        recurrenceType: map['recurrence_type'] as String,
        selectedWeekdays: map['selected_weekdays'] as String?,
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'recurrence_type': recurrenceType,
        'selected_weekdays': selectedWeekdays,
        'start_date': startDate,
        'end_date': endDate,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  BudgetRuleModel copyWith({
    int? id,
    String? name,
    int? categoryId,
    double? amount,
    String? currency,
    String? recurrenceType,
    String? selectedWeekdays,
    String? startDate,
    String? endDate,
    bool? isActive,
    String? createdAt,
  }) {
    return BudgetRuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
