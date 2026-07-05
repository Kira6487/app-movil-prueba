class CreditCardModel {
  const CreditCardModel({
    this.id,
    required this.name,
    this.bankName,
    required this.currency,
    required this.creditLimit,
    this.consumedBalance = 0,
    required this.availableBalance,
    this.cutDay,
    this.paymentDueDay,
    this.tea,
    this.trea,
    this.color,
    this.icon,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? bankName;
  final String currency;
  final double creditLimit;
  final double consumedBalance;
  final double availableBalance;
  final int? cutDay;
  final int? paymentDueDay;
  final double? tea;
  final double? trea;
  final String? color;
  final String? icon;
  final bool isActive;
  final String createdAt;

  factory CreditCardModel.fromMap(Map<String, Object?> map) => CreditCardModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        bankName: map['bank_name'] as String?,
        currency: map['currency'] as String,
        creditLimit: (map['credit_limit'] as num).toDouble(),
        consumedBalance: (map['consumed_balance'] as num).toDouble(),
        availableBalance: (map['available_balance'] as num).toDouble(),
        cutDay: map['cut_day'] as int?,
        paymentDueDay: map['payment_due_day'] as int?,
        tea: (map['tea'] as num?)?.toDouble(),
        trea: (map['trea'] as num?)?.toDouble(),
        color: map['color'] as String?,
        icon: map['icon'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: map['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'bank_name': bankName,
        'currency': currency,
        'credit_limit': creditLimit,
        'consumed_balance': consumedBalance,
        'available_balance': availableBalance,
        'cut_day': cutDay,
        'payment_due_day': paymentDueDay,
        'tea': tea,
        'trea': trea,
        'color': color,
        'icon': icon,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  CreditCardModel copyWith({
    int? id,
    String? name,
    String? bankName,
    String? currency,
    double? creditLimit,
    double? consumedBalance,
    double? availableBalance,
    int? cutDay,
    int? paymentDueDay,
    double? tea,
    double? trea,
    String? color,
    String? icon,
    bool? isActive,
    String? createdAt,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      currency: currency ?? this.currency,
      creditLimit: creditLimit ?? this.creditLimit,
      consumedBalance: consumedBalance ?? this.consumedBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      cutDay: cutDay ?? this.cutDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      tea: tea ?? this.tea,
      trea: trea ?? this.trea,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
