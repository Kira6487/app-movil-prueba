import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/financial_transaction_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_text_input.dart';

class AccountBalanceAdjustmentScreen extends StatefulWidget {
  const AccountBalanceAdjustmentScreen({super.key, required this.account});

  final AccountModel account;

  @override
  State<AccountBalanceAdjustmentScreen> createState() =>
      _AccountBalanceAdjustmentScreenState();
}

class _AccountBalanceAdjustmentScreenState
    extends State<AccountBalanceAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newBalanceController = TextEditingController();
  final _commentController = TextEditingController();
  bool _saving = false;

  double? get _newBalance => _parseNumber(_newBalanceController.text);
  double get _difference =>
      (_newBalance ?? widget.account.currentBalance) -
      widget.account.currentBalance;

  @override
  void dispose() {
    _newBalanceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajuste de saldo',
      children: [
        const SectionHeader(
          title: 'Ajuste manual',
          subtitle: 'Corrige diferencias reales y conserva trazabilidad.',
        ),
        AppCard(
          backgroundColor: AppColors.orangeSoft,
          child: Text(
            'No es recomendable realizar ajustes manuales de saldo, ya que '
            'puede afectar la trazabilidad de tus movimientos. Usa esta '
            'opcion solo para corregir diferencias reales entre Duna y tu cuenta.',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextInput(
                  label: 'Saldo actual',
                  controller: TextEditingController(
                      text: _format(widget.account.currentBalance)),
                  enabled: false,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 14),
                AppTextInput(
                  label: 'Nuevo saldo',
                  controller: _newBalanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.edit_outlined,
                  onChanged: (_) => setState(() {}),
                  validator: _validateNewBalance,
                ),
                const SizedBox(height: 14),
                AppTextInput(
                  label: 'Diferencia',
                  controller: TextEditingController(text: _format(_difference)),
                  enabled: false,
                  prefixIcon: Icons.compare_arrows,
                ),
                const SizedBox(height: 14),
                AppTextInput(
                  label: 'Comentario opcional',
                  controller: _commentController,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Cancelar',
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: _saving ? 'Guardando...' : 'Guardar ajuste',
                        icon: Icons.save_outlined,
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final difference = _difference;
    if (difference == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios de saldo.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final type = difference > 0 ? 'income' : 'expense';
      final category = await CategoryService().getOrCreateCategory(
        name: 'Ajuste Manual',
        type: type,
        icon: 'wallet',
        color: type == 'income' ? '#20C982' : '#FF4D5E',
      );
      final extra = _commentController.text.trim();
      await TransactionService().insertTransaction(
        FinancialTransactionModel(
          type: type,
          amount: difference.abs(),
          currency: widget.account.currency,
          accountId: widget.account.id!,
          categoryId: category.id!,
          date: AppDateUtils.dateOnlyIso(DateTime.now()),
          comment: extra.isEmpty ? 'Ajuste Manual' : 'Ajuste Manual - $extra',
          createdAt: AppDateUtils.nowIso(),
        ),
      );
      TransactionChangeNotifier.notifyChanged();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateNewBalance(String? value) {
    final parsed = _parseNumber(value ?? '');
    if (parsed == null || parsed < 0) return 'Ingresa un saldo valido';
    return null;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _format(double amount) {
    if (widget.account.currency == 'USD') return formatUsd(amount);
    return formatSol(amount);
  }
}
