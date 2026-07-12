class LedgerAccountModel {
  const LedgerAccountModel({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentAccountId,
    required this.currency,
    this.referenceType,
    this.referenceId,
    this.isActive = true,
  });

  final int? id;
  final String code;
  final String name;
  final String type;
  final int? parentAccountId;
  final String currency;
  final String? referenceType;
  final int? referenceId;
  final bool isActive;

  factory LedgerAccountModel.fromMap(Map<String, Object?> map) =>
      LedgerAccountModel(
        id: map['id'] as int?,
        code: map['code'] as String,
        name: map['name'] as String,
        type: map['account_type'] as String,
        parentAccountId: map['parent_account_id'] as int?,
        currency: map['currency'] as String,
        referenceType: map['reference_type'] as String?,
        referenceId: map['reference_id'] as int?,
        isActive: map['is_active'] == 1,
      );
}

class JournalLineDraft {
  const JournalLineDraft({
    required this.ledgerAccountId,
    this.debit = 0,
    this.credit = 0,
    required this.currency,
    this.exchangeRate,
    this.baseAmount,
  });

  final int ledgerAccountId;
  final double debit;
  final double credit;
  final String currency;
  final double? exchangeRate;
  final double? baseAmount;
}

class JournalEntryDraft {
  const JournalEntryDraft({
    required this.date,
    required this.description,
    required this.sourceType,
    this.sourceId,
    this.budgetItemId,
    this.savingsItemId,
    this.status = 'posted',
    required this.createdAt,
    required this.lines,
  });

  final String date;
  final String description;
  final String sourceType;
  final int? sourceId;
  final int? budgetItemId;
  final int? savingsItemId;
  final String status;
  final String createdAt;
  final List<JournalLineDraft> lines;
}
