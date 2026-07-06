class ScheduledExpenseModel {
  const ScheduledExpenseModel({
    this.id,
    required this.name,
    required this.categoryId,
    this.accountId,
    required this.amount,
    required this.currency,
    this.dueDay,
    this.dueDate,
    required this.recurrenceType,
    this.alertDaysBefore = 1,
    required this.status,
    this.comment,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final int categoryId;
  final int? accountId;
  final double amount;
  final String currency;
  final int? dueDay;
  final String? dueDate;
  final String recurrenceType;
  final int alertDaysBefore;
  final String status;
  final String? comment;
  final bool isActive;
  final String createdAt;

  factory ScheduledExpenseModel.fromMap(Map<String, Object?> map) =>
      ScheduledExpenseModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        categoryId: map['category_id'] as int,
        accountId: map['account_id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        dueDay: map['due_day'] as int?,
        dueDate: map['due_date'] as String?,
        recurrenceType: map['recurrence_type'] as String,
        alertDaysBefore: map['alert_days_before'] as int,
        status: map['status'] as String,
        comment: map['comment'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'account_id': accountId,
        'amount': amount,
        'currency': currency,
        'due_day': dueDay,
        'due_date': dueDate,
        'recurrence_type': recurrenceType,
        'alert_days_before': alertDaysBefore,
        'status': status,
        'comment': comment,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  ScheduledExpenseModel copyWith({
    int? id,
    String? name,
    int? categoryId,
    int? accountId,
    double? amount,
    String? currency,
    int? dueDay,
    String? dueDate,
    String? recurrenceType,
    int? alertDaysBefore,
    String? status,
    String? comment,
    bool? isActive,
    String? createdAt,
  }) {
    return ScheduledExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDay: dueDay ?? this.dueDay,
      dueDate: dueDate ?? this.dueDate,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      alertDaysBefore: alertDaysBefore ?? this.alertDaysBefore,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
