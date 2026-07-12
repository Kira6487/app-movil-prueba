import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_rule_model.dart';
import '../../models/quick_action_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/category_service.dart';
import '../../services/budget_service.dart';
import '../../services/quick_action_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';
import '../../widgets/inputs/color_palette_field.dart';
import '../../widgets/inputs/icon_palette_field.dart';

class QuickActionFormScreen extends StatefulWidget {
  const QuickActionFormScreen({super.key, this.initial});

  final QuickActionModel? initial;

  @override
  State<QuickActionFormScreen> createState() => _QuickActionFormScreenState();
}

class _QuickActionFormScreenState extends State<QuickActionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  final _sortOrderController = TextEditingController();

  late Future<_QuickActionFormData> _dataFuture;
  String _currency = 'SOL';
  String _icon = 'food';
  String _color = '#FF4D5E';
  bool _isActive = true;
  AccountModel? _account;
  CategoryModel? _category;
  BudgetRuleModel? _budget;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _amountController.text = _formatNumber(initial.amount);
      _commentController.text = initial.comment ?? '';
      _sortOrderController.text = initial.sortOrder.toString();
      _currency = initial.currency;
      _icon = initial.icon ?? _icon;
      _color = initial.color ?? _color;
      _isActive = initial.isActive;
    }
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<_QuickActionFormData> _loadData() async {
    final accounts = await AccountService().getAllAccounts();
    final categories = (await CategoryService().getAllCategories())
        .where((category) => category.type == 'expense')
        .toList();
    final budgets = (await BudgetService().getAllBudgetRules())
        .where((item) => item.budgetType != BudgetType.savings)
        .toList();
    final initial = widget.initial;
    if (initial != null) {
      _account = _findById(accounts, initial.accountId);
      _category = _findById(categories, initial.categoryId);
      for (final item in budgets) {
        if (item.id == initial.budgetItemId) _budget = item;
      }
    }
    return _QuickActionFormData(
      accounts: accounts,
      categories: categories,
      budgets: budgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar boton' : 'Nuevo boton',
      children: [
        FutureBuilder<_QuickActionFormData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudo cargar el formulario',
                message: 'Intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }
            final data = snapshot.data!;
            return AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextInput(
                      label: 'Nombre',
                      controller: _nameController,
                      prefixIcon: Icons.edit_outlined,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Ingresa un nombre'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Monto',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.payments_outlined,
                      validator: _validateAmount,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<String>(
                      label: 'Moneda',
                      items: const ['SOL', 'USD'],
                      itemLabel: (item) => item,
                      value: _currency,
                      prefixIcon: Icons.currency_exchange,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _currency = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<AccountModel>(
                      label: 'Cuenta predeterminada',
                      items: data.accounts,
                      itemLabel: (account) =>
                          '${account.name} - ${account.currency}',
                      value: _account,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      onChanged: (value) => setState(() => _account = value),
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<CategoryModel>(
                      label: 'Categoria',
                      items: data.categories,
                      itemLabel: (category) => category.name,
                      value: _category,
                      prefixIcon: Icons.category_outlined,
                      onChanged: (value) => setState(() {
                        _category = value;
                        if (_budget?.categoryId != value?.id) _budget = null;
                      }),
                      validator: (value) => value == null
                          ? 'Selecciona una categoría de gasto'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<BudgetRuleModel>(
                      label: 'Contrapartida',
                      items: data.budgets
                          .where((item) => item.categoryId == _category?.id)
                          .toList(),
                      itemLabel: (item) => item.name,
                      value: _budget,
                      prefixIcon: Icons.link_outlined,
                      onChanged: (value) => setState(() => _budget = value),
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Comentario sugerido',
                      controller: _commentController,
                      prefixIcon: Icons.notes_outlined,
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Orden',
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.sort,
                    ),
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
                      title: const Text('Activo'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
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
            );
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      final quickAction = QuickActionModel(
        id: initial?.id,
        name: _nameController.text.trim(),
        amount: _parseNumber(_amountController.text)!,
        currency: _currency,
        categoryId: _category?.id,
        accountId: _account?.id,
        budgetItemId: _budget?.id,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        icon: _icon,
        color: _color,
        isActive: _isActive,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
        createdAt: initial?.createdAt ?? AppDateUtils.nowIso(),
      );
      if (_isEditing) {
        await QuickActionService().updateQuickAction(quickAction);
      } else {
        await QuickActionService().insertQuickAction(quickAction);
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

  String? _validateAmount(String? value) {
    final amount = _parseNumber(value ?? '');
    if (amount == null || amount <= 0) return 'Ingresa un monto mayor a 0';
    return null;
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  T? _findById<T>(List<T> items, int? id) {
    if (id == null) return null;
    for (final item in items) {
      final itemId = switch (item) {
        AccountModel account => account.id,
        CategoryModel category => category.id,
        _ => null,
      };
      if (itemId == id) return item;
    }
    return null;
  }
}

class _QuickActionFormData {
  const _QuickActionFormData({
    required this.accounts,
    required this.categories,
    required this.budgets,
  });

  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final List<BudgetRuleModel> budgets;
}
