import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, this.initial});

  final AccountModel? initial;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  String _accountType = _accountTypes.first.value;
  String _currency = 'SOL';
  String _color = _accountColors.first.value;
  String _icon = _accountIcons.first.value;
  bool _hiddenFromBudget = false;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _initialBalanceController.text = _formatNumber(initial.initialBalance);
      _accountType = initial.accountType;
      _currency = initial.currency;
      _color = initial.color ?? _accountColors.first.value;
      _icon = initial.icon ?? _accountIcons.first.value;
      _hiddenFromBudget = initial.isHiddenFromBudget;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
      children: [
        SectionHeader(
          title: _isEditing ? 'Datos de la cuenta' : 'Crear cuenta',
          subtitle: 'Administra cuentas locales sin conexion bancaria.',
        ),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextInput(
                  label: 'Nombre',
                  controller: _nameController,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 14),
                const AppTextInput(
                  label: 'Banco',
                  hintText: 'Disponible cuando exista campo en SQLite',
                  enabled: false,
                  prefixIcon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 14),
                AppDropdownField<_AccountOption>(
                  label: 'Tipo de cuenta',
                  items: _accountTypes,
                  itemLabel: (item) => item.label,
                  value: _findOption(_accountTypes, _accountType),
                  prefixIcon: Icons.category_outlined,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _accountType = value.value);
                  },
                ),
                const SizedBox(height: 14),
                AppDropdownField<String>(
                  label: 'Moneda',
                  items: const ['SOL', 'USD'],
                  itemLabel: (currency) => currency,
                  value: _currency,
                  prefixIcon: Icons.currency_exchange,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currency = value);
                  },
                ),
                const SizedBox(height: 14),
                AppTextInput(
                  label: 'Saldo inicial',
                  hintText: '0.00',
                  controller: _initialBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.payments_outlined,
                  validator: _validateBalance,
                ),
                const SizedBox(height: 14),
                AppDropdownField<_AccountOption>(
                  label: 'Icono',
                  items: _accountIcons,
                  itemLabel: (item) => item.label,
                  value: _findOption(_accountIcons, _icon),
                  prefixIcon: Icons.insert_emoticon_outlined,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _icon = value.value);
                  },
                ),
                const SizedBox(height: 14),
                AppDropdownField<_AccountOption>(
                  label: 'Color',
                  items: _accountColors,
                  itemLabel: (item) => item.label,
                  value: _findOption(_accountColors, _color),
                  prefixIcon: Icons.palette_outlined,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _color = value.value);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ocultar del presupuesto'),
                  subtitle: const Text('Mantiene la cuenta fuera de calculos.'),
                  value: _hiddenFromBudget,
                  onChanged: (value) {
                    setState(() => _hiddenFromBudget = value);
                  },
                ),
                const SizedBox(height: 18),
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
                        label: _saving ? 'Guardando...' : 'Guardar',
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
        const AppCard(
          backgroundColor: AppColors.surfaceAlt,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.textMuted),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Integraciones futuras: banca movil y Google Wallet. '
                  'No disponible en demo.',
                  style: AppTextStyles.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      final initialBalance = _parseNumber(_initialBalanceController.text) ?? 0;
      final account = AccountModel(
        id: initial?.id,
        name: _nameController.text.trim(),
        accountType: _accountType,
        currency: _currency,
        initialBalance: initialBalance,
        currentBalance: initial?.currentBalance ?? initialBalance,
        isHiddenFromBudget: _hiddenFromBudget,
        color: _color,
        icon: _icon,
        createdAt: initial?.createdAt ?? AppDateUtils.nowIso(),
      );
      if (_isEditing) {
        await AccountService().updateAccount(account);
      } else {
        await AccountService().insertAccount(account);
      }
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

  String? _validateBalance(String? value) {
    final amount = _parseNumber(value ?? '');
    if (amount == null || amount < 0) return 'Ingresa un saldo valido';
    return null;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  _AccountOption _findOption(List<_AccountOption> options, String value) {
    return options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
  }
}

class _AccountOption {
  const _AccountOption(this.value, this.label);

  final String value;
  final String label;
}

const _accountTypes = [
  _AccountOption('ahorros', 'Ahorros'),
  _AccountOption('corriente', 'Corriente'),
  _AccountOption('sueldo', 'Sueldo'),
  _AccountOption('plazo_fijo', 'Plazo fijo'),
  _AccountOption('efectivo', 'Efectivo'),
  _AccountOption('billetera', 'Billetera digital'),
];

const _accountIcons = [
  _AccountOption('wallet', 'Billetera'),
  _AccountOption('bank', 'Banco'),
  _AccountOption('cash', 'Efectivo'),
  _AccountOption('card', 'Tarjeta'),
  _AccountOption('savings', 'Ahorro'),
];

const _accountColors = [
  _AccountOption('#2563EB', 'Azul'),
  _AccountOption('#16A34A', 'Verde'),
  _AccountOption('#DC2626', 'Rojo'),
  _AccountOption('#EA580C', 'Naranja'),
  _AccountOption('#7C3AED', 'Morado'),
];
