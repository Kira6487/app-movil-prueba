import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/financial_transaction_model.dart';
import '../../models/quick_action_model.dart';
import '../../models/related_item_option.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../services/quick_action_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/buttons/quick_action_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.type,
    this.initialQuickAction,
    this.initialAccount,
    this.initialTransaction,
    this.lockAccount = false,
  });

  final String type;
  final QuickActionModel? initialQuickAction;
  final AccountModel? initialAccount;
  final FinancialTransactionModel? initialTransaction;
  final bool lockAccount;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _commentController = TextEditingController();

  late Future<_TransactionFormData> _dataFuture;
  String _currency = 'SOL';
  AccountModel? _selectedAccount;
  CategoryModel? _selectedCategory;
  RelatedItemOption? _selectedRelated;
  List<RelatedItemOption> _relatedOptions = const [];
  bool _loadingRelated = false;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  bool get _isExpense => widget.type == 'expense';
  bool get _isSavings => widget.type == 'savings';
  bool get _isEditing => widget.initialTransaction != null;
  String get _categoryScope => switch (widget.type) {
        'income' => CategoryScope.income,
        'savings' => CategoryScope.savings,
        _ => CategoryScope.expense,
      };

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
    final initialTransaction = widget.initialTransaction;
    if (initialTransaction == null) {
      _selectedAccount = widget.initialAccount;
      _applyQuickAction(widget.initialQuickAction);
    } else {
      _amountController.text = _formatNumber(initialTransaction.amount);
      _currency = initialTransaction.currency;
      if (initialTransaction.exchangeRate != null) {
        _exchangeRateController.text =
            _formatNumber(initialTransaction.exchangeRate!);
      }
      _selectedDate =
          DateTime.tryParse(initialTransaction.date) ?? DateTime.now();
      _commentController.text = initialTransaction.comment ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _exchangeRateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<_TransactionFormData> _loadData() async {
    final accounts = await AccountService().getAllAccounts();
    final categories = await CategoryService().getCategoriesByType(
      _categoryScope,
    );
    final quickActions = _isExpense && !widget.lockAccount
        ? await QuickActionService().getAllQuickActions()
        : <QuickActionModel>[];

    final initial = widget.initialQuickAction;
    if (initial != null) {
      _selectedAccount = _findById(accounts, initial.accountId);
      _selectedCategory = _findById(categories, initial.categoryId);
    }
    final initialAccount = widget.initialAccount;
    if (initialAccount != null) {
      _selectedAccount = _findById(accounts, initialAccount.id);
    }
    final initialTransaction = widget.initialTransaction;
    if (initialTransaction != null) {
      _selectedAccount = _findById(accounts, initialTransaction.accountId);
      _selectedCategory = _findById(categories, initialTransaction.categoryId);
    }
    _relatedOptions = await _loadRelatedOptions();
    final relatedType = initialTransaction?.relatedType;
    final relatedId = initialTransaction?.relatedId;
    if (relatedType != null && relatedId != null) {
      _selectedRelated = _findRelated(_relatedOptions, relatedType, relatedId);
    }

    return _TransactionFormData(
      accounts: accounts,
      categories: categories,
      quickActions: quickActions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _title;
    final color = _isExpense
        ? AppColors.red
        : (_isSavings ? AppColors.purple : AppColors.green);

    return AppScaffold(
      title: title,
      children: [
        SectionHeader(
          title: title,
          subtitle: _isExpense
              ? 'Guarda un gasto real y descuenta el saldo de la cuenta.'
              : (_isSavings
                  ? 'Registra un ahorro real y relaciona su objetivo.'
                  : 'Guarda un ingreso real y suma el saldo de la cuenta.'),
        ),
        FutureBuilder<_TransactionFormData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudo cargar el formulario',
                message: 'Revisa la base local e intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }

            final data = snapshot.data!;
            if (data.accounts.isEmpty || data.categories.isEmpty) {
              return EmptyState(
                title: 'Faltan datos locales',
                message: data.accounts.isEmpty
                    ? 'Registra una cuenta antes de crear movimientos.'
                    : 'Registra categorias para este tipo de movimiento.',
                icon: Icons.inventory_2_outlined,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isExpense &&
                    !_isEditing &&
                    !widget.lockAccount &&
                    data.quickActions.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'Botones rapidos',
                    subtitle:
                        'Precargan el formulario; puedes editar antes de guardar.',
                  ),
                  const SizedBox(height: 12),
                  _QuickActionList(
                    actions: data.quickActions,
                    onSelected: (action) => _selectQuickAction(action, data),
                  ),
                  const SizedBox(height: 16),
                ],
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextInput(
                          label: 'Monto',
                          hintText: '0.00',
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
                          itemLabel: (currency) => currency,
                          value: _currency,
                          prefixIcon: Icons.currency_exchange,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _currency = value);
                          },
                        ),
                        if (_currency == 'USD') ...[
                          const SizedBox(height: 14),
                          AppTextInput(
                            label: 'Tipo de cambio a SOL',
                            hintText: '3.80',
                            controller: _exchangeRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Icons.swap_vert,
                            validator: _validateExchangeRate,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (widget.lockAccount)
                          AppTextInput(
                            label: 'Cuenta',
                            controller: TextEditingController(
                              text: _selectedAccount == null
                                  ? ''
                                  : '${_selectedAccount!.name} - ${_selectedAccount!.currency}',
                            ),
                            enabled: false,
                            prefixIcon: Icons.account_balance_wallet_outlined,
                            validator: (_) => _selectedAccount == null
                                ? 'Selecciona una cuenta'
                                : null,
                          )
                        else
                          AppDropdownField<AccountModel>(
                            label: 'Cuenta',
                            items: data.accounts,
                            itemLabel: (account) =>
                                '${account.name} - ${account.currency}',
                            value: _selectedAccount,
                            prefixIcon: Icons.account_balance_wallet_outlined,
                            onChanged: (value) {
                              setState(() => _selectedAccount = value);
                            },
                            validator: (value) =>
                                value == null ? 'Selecciona una cuenta' : null,
                          ),
                        const SizedBox(height: 14),
                        AppDropdownField<CategoryModel>(
                          label: 'Categoria',
                          items: data.categories,
                          itemLabel: (category) => category.name,
                          value: _selectedCategory,
                          prefixIcon: Icons.category_outlined,
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                            _refreshRelatedOptions();
                          },
                          validator: (value) =>
                              value == null ? 'Selecciona una categoria' : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextInput(
                          label: 'Fecha',
                          controller: TextEditingController(
                            text: _formatDate(_selectedDate),
                          ),
                          readOnly: true,
                          prefixIcon: Icons.calendar_today_outlined,
                          suffixIcon: const Icon(Icons.expand_more),
                          onTap: _pickDate,
                          validator: (_) => _selectedDate.year <= 0
                              ? 'Selecciona una fecha'
                              : null,
                        ),
                        if (_isExpense || _isSavings) ...[
                          const SizedBox(height: 14),
                          _RelatedField(
                            loading: _loadingRelated,
                            options: _relatedOptions,
                            value: _relatedOptions.contains(_selectedRelated)
                                ? _selectedRelated
                                : null,
                            onChanged: (value) =>
                                setState(() => _selectedRelated = value),
                            required: _relatedOptions.isNotEmpty,
                          ),
                        ],
                        const SizedBox(height: 14),
                        AppTextInput(
                          label: 'Comentario opcional',
                          controller: _commentController,
                          maxLines: 3,
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
                                    : () => Navigator.of(context).pop(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppPrimaryButton(
                                label: _saving ? 'Guardando...' : 'Guardar',
                                icon: Icons.save_outlined,
                                onPressed: _saving ? null : () => _save(color),
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
          },
        ),
      ],
    );
  }

  void _selectQuickAction(
    QuickActionModel action,
    _TransactionFormData data,
  ) {
    setState(() {
      _applyQuickAction(action);
      _selectedAccount = _findById(data.accounts, action.accountId);
      _selectedCategory = _findById(data.categories, action.categoryId);
    });
    _refreshRelatedOptions();
  }

  void _applyQuickAction(QuickActionModel? action) {
    if (action == null) return;
    _amountController.text = _formatNumber(action.amount);
    _currency = action.currency;
    _commentController.text = action.comment ?? action.name;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _refreshRelatedOptions();
  }

  Future<void> _save(Color color) async {
    if (!_formKey.currentState!.validate()) return;

    final account = _selectedAccount;
    final category = _selectedCategory;
    if (account == null || category == null) return;

    setState(() => _saving = true);
    try {
      final amount = _parseNumber(_amountController.text)!;
      final exchangeRate = _currency == 'USD'
          ? _parseNumber(_exchangeRateController.text)
          : null;
      final now = AppDateUtils.nowIso();
      final transaction = FinancialTransactionModel(
        id: widget.initialTransaction?.id,
        type: widget.type,
        amount: amount,
        currency: _currency,
        exchangeRate: exchangeRate,
        accountId: account.id!,
        categoryId: category.id!,
        relatedType: _selectedRelated?.type,
        relatedId: _selectedRelated?.id,
        date: AppDateUtils.dateOnlyIso(_selectedDate),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: widget.initialTransaction?.createdAt ?? now,
      );
      if (_isEditing) {
        await TransactionService().updateTransaction(transaction);
      } else {
        await TransactionService().insertTransaction(transaction);
      }
      TransactionChangeNotifier.notifyChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Movimiento actualizado'
                : (_isExpense
                    ? 'Gasto registrado'
                    : (_isSavings
                        ? 'Ahorro registrado'
                        : 'Ingreso registrado')),
          ),
          backgroundColor: color,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _validateAmount(String? value) {
    final amount = _parseNumber(value ?? '');
    if (amount == null || amount <= 0) {
      return 'Ingresa un monto mayor a 0';
    }
    return null;
  }

  String? _validateExchangeRate(String? value) {
    final rate = _parseNumber(value ?? '');
    if (rate == null || rate <= 0) {
      return 'Ingresa un tipo de cambio mayor a 0';
    }
    return null;
  }

  String get _title {
    if (_isEditing) {
      if (_isSavings) return 'Editar ahorro';
      return _isExpense ? 'Editar gasto' : 'Editar ingreso';
    }
    if (_isSavings) return 'Registrar ahorro';
    return _isExpense ? 'Registrar gasto' : 'Registrar ingreso';
  }

  Future<List<RelatedItemOption>> _loadRelatedOptions() async {
    final category = _selectedCategory;
    if (category?.id == null || (!_isExpense && !_isSavings)) {
      return const [];
    }
    return BudgetService().getRelatedOptions(
      categoryId: category!.id!,
      date: _selectedDate,
      operationType: widget.type,
    );
  }

  Future<void> _refreshRelatedOptions() async {
    if (!_isExpense && !_isSavings) return;
    setState(() => _loadingRelated = true);
    final options = await _loadRelatedOptions();
    if (!mounted) return;
    setState(() {
      _relatedOptions = options;
      if (!_relatedOptions
          .any((option) => option.key == _selectedRelated?.key)) {
        _selectedRelated = null;
      }
      _loadingRelated = false;
    });
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
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

  RelatedItemOption? _findRelated(
    List<RelatedItemOption> items,
    String type,
    int id,
  ) {
    for (final item in items) {
      if (item.type == type && item.id == id) return item;
    }
    return null;
  }
}

class _RelatedField extends StatelessWidget {
  const _RelatedField({
    required this.loading,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.required,
  });

  final bool loading;
  final List<RelatedItemOption> options;
  final RelatedItemOption? value;
  final ValueChanged<RelatedItemOption?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppTextInput(
        label: 'Relacionado',
        enabled: false,
        prefixIcon: Icons.link_outlined,
        hintText: 'Buscando opciones compatibles...',
      );
    }
    if (options.isEmpty) {
      return const AppTextInput(
        label: 'Relacionado',
        enabled: false,
        prefixIcon: Icons.link_off_outlined,
        hintText: 'Sin relación disponible',
      );
    }
    return AppDropdownField<RelatedItemOption>(
      label: 'Relacionado',
      items: options,
      itemLabel: (option) => '${option.name} · ${option.subtitle}',
      value: value,
      prefixIcon: Icons.link_outlined,
      onChanged: onChanged,
      validator: (option) =>
          required && option == null ? 'Selecciona una relación' : null,
    );
  }
}

class _QuickActionList extends StatelessWidget {
  const _QuickActionList({
    required this.actions,
    required this.onSelected,
  });

  final List<QuickActionModel> actions;
  final ValueChanged<QuickActionModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gastos frecuentes', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          for (final action in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuickActionButton(
                icon: iconDataForId(action.icon),
                title: action.name,
                description:
                    '${action.currency} ${action.amount.toStringAsFixed(2)}',
                color: _colorFromHex(action.color),
                onTap: () => onSelected(action),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorFromHex(String? value) {
    if (value == null || value.length != 7 || !value.startsWith('#')) {
      return AppColors.red;
    }
    return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
  }
}

class _TransactionFormData {
  const _TransactionFormData({
    required this.accounts,
    required this.categories,
    required this.quickActions,
  });

  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final List<QuickActionModel> quickActions;
}
