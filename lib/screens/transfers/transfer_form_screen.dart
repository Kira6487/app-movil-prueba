import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/transfer_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/transfer_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key, this.initialFromAccount});

  final AccountModel? initialFromAccount;

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _commentController = TextEditingController();

  late Future<List<AccountModel>> _accountsFuture;
  AccountModel? _fromAccount;
  AccountModel? _toAccount;
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _needsExchangeRate =>
      _fromAccount != null &&
      _toAccount != null &&
      _fromAccount!.currency != _toAccount!.currency;

  @override
  void initState() {
    super.initState();
    _fromAccount = widget.initialFromAccount;
    _accountsFuture = _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<List<AccountModel>> _loadAccounts() async {
    final accounts = await AccountService().getAllAccounts();
    if (_fromAccount != null) {
      _fromAccount = _findAccount(accounts, _fromAccount!.id);
    }
    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transferencia',
      children: [
        const SectionHeader(
          title: 'Transferir entre cuentas',
          subtitle: 'Mueve dinero y conserva el historial en ambas cuentas.',
        ),
        FutureBuilder<List<AccountModel>>(
          future: _accountsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudo cargar cuentas',
                message: 'Revisa la base local e intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }
            final accounts = snapshot.data ?? const [];
            if (accounts.length < 2) {
              return const EmptyState(
                title: 'Necesitas dos cuentas',
                message: 'Crea otra cuenta para registrar transferencias.',
                icon: Icons.swap_horiz,
              );
            }
            return AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppDropdownField<AccountModel>(
                      label: 'Cuenta origen',
                      items: accounts,
                      itemLabel: _accountLabel,
                      value: _fromAccount,
                      prefixIcon: Icons.call_made,
                      onChanged: (value) {
                        setState(() {
                          _fromAccount = value;
                          if (_toAccount?.id == value?.id) _toAccount = null;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona cuenta origen' : null,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<AccountModel>(
                      label: 'Cuenta destino',
                      items: accounts
                          .where((account) => account.id != _fromAccount?.id)
                          .toList(),
                      itemLabel: _accountLabel,
                      value: _toAccount,
                      prefixIcon: Icons.call_received,
                      onChanged: (value) => setState(() => _toAccount = value),
                      validator: (value) =>
                          value == null ? 'Selecciona cuenta destino' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Monto origen',
                      hintText: '0.00',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.payments_outlined,
                      onChanged: (_) => setState(() {}),
                      validator: _validateAmount,
                    ),
                    if (_needsExchangeRate) ...[
                      const SizedBox(height: 14),
                      AppTextInput(
                        label: 'Tipo de cambio',
                        hintText: '3.75',
                        controller: _exchangeRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.currency_exchange,
                        onChanged: (_) => setState(() {}),
                        validator: _validateExchangeRate,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Monto destino',
                      controller:
                          TextEditingController(text: _destinationText()),
                      enabled: false,
                      prefixIcon: Icons.south_west,
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Fecha',
                      controller:
                          TextEditingController(text: _formatDate(_date)),
                      readOnly: true,
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.expand_more),
                      onTap: _pickDate,
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
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPrimaryButton(
                            label: _saving ? 'Guardando...' : 'Guardar',
                            icon: Icons.swap_horiz,
                            onPressed: _saving ? null : _save,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final from = _fromAccount;
    final to = _toAccount;
    if (from == null || to == null) return;

    setState(() => _saving = true);
    try {
      final amountFrom = _parseNumber(_amountController.text)!;
      final exchangeRate = _needsExchangeRate
          ? _parseNumber(_exchangeRateController.text)
          : null;
      final amountTo = _calculateDestinationAmount(
        amountFrom: amountFrom,
        fromCurrency: from.currency,
        toCurrency: to.currency,
        exchangeRate: exchangeRate,
      );
      final now = AppDateUtils.nowIso();
      await TransferService().insertTransfer(
        TransferModel(
          fromAccountId: from.id!,
          toAccountId: to.id!,
          amountFrom: amountFrom,
          currencyFrom: from.currency,
          amountTo: amountTo,
          currencyTo: to.currency,
          exchangeRate: exchangeRate,
          date: AppDateUtils.dateOnlyIso(_date),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          createdAt: now,
        ),
      );
      TransactionChangeNotifier.notifyChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transferencia registrada')),
      );
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  String? _validateAmount(String? value) {
    final amount = _parseNumber(value ?? '');
    if (amount == null || amount <= 0) return 'Ingresa un monto mayor a 0';
    return null;
  }

  String? _validateExchangeRate(String? value) {
    if (!_needsExchangeRate) return null;
    final rate = _parseNumber(value ?? '');
    if (rate == null || rate <= 0) return 'Ingresa un tipo de cambio valido';
    return null;
  }

  String _destinationText() {
    final from = _fromAccount;
    final to = _toAccount;
    final amount = _parseNumber(_amountController.text);
    final rate = _parseNumber(_exchangeRateController.text);
    if (from == null || to == null || amount == null || amount <= 0) return '';
    if (from.currency != to.currency && (rate == null || rate <= 0)) return '';
    final result = _calculateDestinationAmount(
      amountFrom: amount,
      fromCurrency: from.currency,
      toCurrency: to.currency,
      exchangeRate: rate,
    );
    return '${to.currency} ${result.toStringAsFixed(2)}';
  }

  double _calculateDestinationAmount({
    required double amountFrom,
    required String fromCurrency,
    required String toCurrency,
    required double? exchangeRate,
  }) {
    if (fromCurrency == toCurrency) return amountFrom;
    if (fromCurrency == 'SOL' && toCurrency == 'USD') {
      return amountFrom / exchangeRate!;
    }
    return amountFrom * exchangeRate!;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _accountLabel(AccountModel account) {
    return '${account.name} - ${account.currency}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  AccountModel? _findAccount(List<AccountModel> accounts, int? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }
}
