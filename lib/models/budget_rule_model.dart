class BudgetRuleModel {
  const BudgetRuleModel({
    this.id,
    required this.name,
    this.budgetType = BudgetType.category,
    this.categoryId,
    required this.amount,
    required this.currency,
    required this.recurrenceType,
    this.selectedWeekdays,
    this.unitsPerDay = 1,
    this.description,
    this.conditionText,
    this.startDate,
    this.endDate,
    this.iconKey,
    this.colorHex,
    this.isActive = true,
    required this.createdAt,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final int? id;
  final String name;
  final String budgetType;
  final int? categoryId;
  final double amount;
  final String currency;
  final String recurrenceType;
  final String? selectedWeekdays;
  final double unitsPerDay;
  final String? description;
  final String? conditionText;
  final String? startDate;
  final String? endDate;
  final String? iconKey;
  final String? colorHex;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory BudgetRuleModel.fromMap(Map<String, Object?> map) => BudgetRuleModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        budgetType: map['budget_type'] as String? ?? BudgetType.category,
        categoryId: map['category_id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        recurrenceType: map['recurrence_type'] as String,
        selectedWeekdays: map['selected_weekdays'] as String?,
        unitsPerDay: ((map['units_per_day'] as num?) ?? 1).toDouble(),
        description: map['description'] as String?,
        conditionText: map['condition_text'] as String?,
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
        iconKey: map['icon_key'] as String?,
        colorHex: map['color_hex'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'budget_type': budgetType,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'recurrence_type': recurrenceType,
        'selected_weekdays': selectedWeekdays,
        'units_per_day': unitsPerDay,
        'description': description,
        'condition_text': conditionText,
        'start_date': startDate,
        'end_date': endDate,
        'icon_key': iconKey,
        'color_hex': colorHex,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  BudgetRuleModel copyWith({
    int? id,
    String? name,
    String? budgetType,
    int? categoryId,
    double? amount,
    String? currency,
    String? recurrenceType,
    String? selectedWeekdays,
    double? unitsPerDay,
    String? description,
    String? conditionText,
    String? startDate,
    String? endDate,
    String? iconKey,
    String? colorHex,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return BudgetRuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      budgetType: budgetType ?? this.budgetType,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      description: description ?? this.description,
      conditionText: conditionText ?? this.conditionText,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BudgetType {
  const BudgetType._();

  static const category = 'category';
  static const recurrence = 'recurrence';
  static const customRule = 'custom_rule';
  static const savings = 'savings';

  static const values = [category, recurrence, customRule, savings];

  static String label(String value) => switch (value) {
        category => 'Categoría',
        recurrence => 'Repetición por fechas',
        customRule => 'Regla propia',
        savings => 'Ahorro',
        _ => value,
      };
}
