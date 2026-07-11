import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';
import '../../widgets/inputs/color_palette_field.dart';
import '../../widgets/inputs/icon_palette_field.dart';
import 'account_balance_adjustment_screen.dart';

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
  String _color = appColorChoices.first.hex;
  String _icon = 'wallet';
  bool _hiddenFromBudget = false;
  bool _saving = false;
  AccountModel? _account;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _account = initial;
      _nameController.text = initial.name;
      _accountType = initial.accountType;
      _currency = initial.currency;
      _color = initial.color ?? _color;
      _icon = initial.icon ?? _icon;
      _hiddenFromBudget = initial.isHiddenFromBudget;
    } else {
      _initialBalanceController.text = '0';
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
    final account = _account;
    return AppScaffold(
      title: _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
      children: [
        SectionHeader(
          title: _isEditing ? 'Datos de la cuenta' : 'Crear cuenta',
          subtitle: _isEditing
              ? 'Administra la informacion de esta cuenta.'
              : 'Personaliza tus cuentas y organiza tus movimientos.',
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
                  onChanged: account == null
                      ? (value) {
                          if (value == null) return;
                          setState(() => _currency = value);
                        }
                      : null,
                ),
                const SizedBox(height: 14),
                if (_isEditing && account != null)
                  AppTextInput(
                    label: 'Saldo actual',
                    controller: TextEditingController(
                      text: _formatAccountBalance(account),
                    ),
                    enabled: false,
                    prefixIcon: Icons.payments_outlined,
                  )
                else
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
                if (_isEditing && account != null) ...[
                  const SizedBox(height: 14),
                  AppSecondaryButton(
                    label: 'Ajuste de saldo',
                    icon: Icons.tune,
                    onPressed: () async {
                      final adjusted = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              AccountBalanceAdjustmentScreen(account: account),
                        ),
                      );
                      if (adjusted == true) {
                        final refreshed = await AccountService().getAccountById(
                          account.id!,
                        );
                        if (mounted && refreshed != null) {
                          setState(() => _account = refreshed);
                        }
                      }
                      TransactionChangeNotifier.notifyChanged();
                    },
                  ),
                ],
                const SizedBox(height: 14),
                IconPaletteField(
                  label: 'Icono',
                  value: _icon,
                  color: colorFromHex(_color),
                  onChanged: (value) => setState(() => _icon = value),
                ),
                const SizedBox(height: 14),
                ColorPaletteField(
                  label: 'Color',
                  value: _color,
                  onChanged: (value) => setState(() => _color = value),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ocultar del presupuesto'),
                  subtitle: const Text(
                    'Mantiene esta cuenta fuera de calculos.',
                  ),
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: _saving
                            ? 'Guardando...'
                            : (_isEditing ? 'Guardar cambios' : 'Guardar'),
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
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      final current = _isEditing
          ? await AccountService().getAccountById(initial!.id!)
          : null;
      if (_isEditing && current == null) {
        throw StateError('La cuenta ya no existe.');
      }
      final initialBalance = _isEditing
          ? current!.initialBalance
          : (_parseNumber(_initialBalanceController.text) ?? 0);
      final account = AccountModel(
        id: initial?.id,
        name: _nameController.text.trim(),
        accountType: _accountType,
        currency: _currency,
        initialBalance: initialBalance,
        currentBalance: current?.currentBalance ?? initialBalance,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
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

  String _formatAccountBalance(AccountModel account) {
    final symbol = account.currency == 'USD' ? r'$' : 'S/';
    return '$symbol ${account.currentBalance.toStringAsFixed(2)}';
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
  _AccountOption('billetera', 'Cuenta digital'),
];
