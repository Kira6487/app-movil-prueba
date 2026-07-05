class CreditCardInstallmentModel {
  const CreditCardInstallmentModel({
    this.id,
    required this.creditCardId,
    this.categoryId,
    this.description,
    required this.totalAmount,
    required this.currency,
    required this.installmentCount,
    required this.installmentAmount,
    this.firstPaymentDate,
    this.currentInstallment = 0,
    required this.status,
    required this.createdAt,
  });

  final int? id;
  final int creditCardId;
  final int? categoryId;
  final String? description;
  final double totalAmount;
  final String currency;
  final int installmentCount;
  final double installmentAmount;
  final String? firstPaymentDate;
  final int currentInstallment;
  final String status;
  final String createdAt;

  factory CreditCardInstallmentModel.fromMap(Map<String, Object?> map) {
    return CreditCardInstallmentModel(
      id: map['id'] as int?,
      creditCardId: map['credit_card_id'] as int,
      categoryId: map['category_id'] as int?,
      description: map['description'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      currency: map['currency'] as String,
      installmentCount: map['installment_count'] as int,
      installmentAmount: (map['installment_amount'] as num).toDouble(),
      firstPaymentDate: map['first_payment_date'] as String?,
      currentInstallment: map['current_installment'] as int,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'credit_card_id': creditCardId,
        'category_id': categoryId,
        'description': description,
        'total_amount': totalAmount,
        'currency': currency,
        'installment_count': installmentCount,
        'installment_amount': installmentAmount,
        'first_payment_date': firstPaymentDate,
        'current_installment': currentInstallment,
        'status': status,
        'created_at': createdAt,
      };

  CreditCardInstallmentModel copyWith({
    int? id,
    int? creditCardId,
    int? categoryId,
    String? description,
    double? totalAmount,
    String? currency,
    int? installmentCount,
    double? installmentAmount,
    String? firstPaymentDate,
    int? currentInstallment,
    String? status,
    String? createdAt,
  }) {
    return CreditCardInstallmentModel(
      id: id ?? this.id,
      creditCardId: creditCardId ?? this.creditCardId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
