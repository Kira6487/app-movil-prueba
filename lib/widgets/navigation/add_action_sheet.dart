import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/financial_transaction_model.dart';
import '../../models/quick_action_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../screens/placeholders/action_placeholder_screen.dart';
import '../../screens/transactions/transaction_form_screen.dart';
import '../../services/account_service.dart';
import '../../services/category_service.dart';
import '../../services/quick_action_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/quick_action_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';

class AddActionSheet extends StatefulWidget {
  const AddActionSheet({super.key});

  @override
  State<AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<AddActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  late Future<_QuickExpenseData> _dataFuture;
  AccountModel? _selectedAccount;
  CategoryModel? _selectedCategory;
  String _currency = 'SOL';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<_QuickExpenseData> _loadData() async {
    final accounts = await AccountService().getAllAccounts();
    final categories = (await CategoryService().getAllCategories())
        .where((category) => category.type == 'expense')
        .toList();
    final quickActions = await QuickActionService().getAllQuickActions();
    if (accounts.isNotEmpty) {
      _selectedAccount = accounts.first;
      _currency = accounts.first.currency;
    }
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
    return _QuickExpenseData(
      accounts: accounts,
      categories: categories,
      quickActions: quickActions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.sm,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
        ),
        child: FutureBuilder<_QuickExpenseData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Registrar gasto', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  const Text('Registro rapido', style: AppTextStyles.muted),
                  const SizedBox(height: AppSpacing.lg),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError)
                    const EmptyState(
                      title: 'No se pudo cargar el registro rapido',
                      message: 'Revisa la base local e intenta nuevamente.',
                      icon: Icons.error_outline,
                    )
                  else
                    _buildForm(context, snapshot.data!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, _QuickExpenseData data) {
    if (data.accounts.isEmpty || data.categories.isEmpty) {
      return const EmptyState(
        title: 'Faltan datos locales',
        message: 'Crea una cuenta y una categoria de gasto primero.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            backgroundColor: AppColors.surfaceAlt,
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
                const SizedBox(height: 12),
                AppDropdownField<AccountModel>(
                  label: 'Cuenta',
                  items: data.accounts,
                  itemLabel: (account) =>
                      '${account.name} - ${account.currency}',
                  value: _selectedAccount,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedAccount = value;
                      _currency = value.currency;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una cuenta' : null,
                ),
                const SizedBox(height: 12),
                AppDropdownField<CategoryModel>(
                  label: 'Categoria',
                  items: data.categories,
                  itemLabel: (category) => category.name,
                  value: _selectedCategory,
                  prefixIcon: Icons.category_outlined,
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una categoria' : null,
                ),
                const SizedBox(height: 12),
                AppTextInput(
                  label: 'Comentario opcional',
                  controller: _commentController,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: _saving ? 'Guardando...' : 'Guardar gasto',
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : _saveExpense,
                ),
              ],
            ),
          ),
          if (data.quickActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Text('Botones rapidos', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            for (final action in data.quickActions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: QuickActionButton(
                  icon: _iconForQuickAction(action.name),
                  title: action.name,
                  description:
                      '${action.currency} ${action.amount.toStringAsFixed(2)}',
                  color: _colorFromHex(action.color),
                  onTap: () => _applyQuickAction(action, data),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text('Mas acciones', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          QuickActionButton(
            icon: Icons.add_circle_outline,
            title: 'Registrar ingreso',
            description: 'Abrir flujo real de ingreso',
            color: AppColors.green,
            onTap: () => _openIncome(context),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.swap_horiz,
            title: 'Transferencia',
            description: 'Flujo pendiente',
            color: AppColors.blue,
            onTap: () => _openPlaceholder(
              context,
              title: 'Transferencia',
              description:
                  'La transferencia funcional se implementara mas adelante.',
              icon: Icons.swap_horiz,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.event_available_outlined,
            title: 'Pago programado',
            description: 'Proximamente',
            color: AppColors.orange,
            onTap: () => _openPlaceholder(
              context,
              title: 'Pago programado',
              description: 'No disponible en demo.',
              icon: Icons.event_available_outlined,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 8),
          QuickActionButton(
            icon: Icons.savings_outlined,
            title: 'Ahorro',
            description: 'Proximamente',
            color: AppColors.purple,
            onTap: () => _openPlaceholder(
              context,
              title: 'Ahorro',
              description: 'No disponible en demo.',
              icon: Icons.savings_outlined,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _applyQuickAction(QuickActionModel action, _QuickExpenseData data) {
    setState(() {
      _amountController.text = _formatNumber(action.amount);
      _currency = action.currency;
      _commentController.text = action.comment ?? action.name;
      _selectedAccount = _findById(data.accounts, action.accountId) ??
          _selectedAccount ??
          data.accounts.first;
      _selectedCategory = _findById(data.categories, action.categoryId) ??
          _selectedCategory ??
          data.categories.first;
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final account = _selectedAccount;
    final category = _selectedCategory;
    if (account == null || category == null) return;

    setState(() => _saving = true);
    try {
      final now = AppDateUtils.nowIso();
      await TransactionService().insertTransaction(
        FinancialTransactionModel(
          type: 'expense',
          amount: _parseNumber(_amountController.text)!,
          currency: _currency,
          accountId: account.id!,
          categoryId: category.id!,
          date: AppDateUtils.dateOnlyIso(DateTime.now()),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          createdAt: now,
        ),
      );
      TransactionChangeNotifier.notifyChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto registrado')),
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

  void _openIncome(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const TransactionFormScreen(type: 'income'),
      ),
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ActionPlaceholderScreen(
          title: title,
          description: description,
          icon: icon,
          color: color,
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final amount = _parseNumber(value ?? '');
    if (amount == null || amount <= 0) {
      return 'Ingresa un monto mayor a 0';
    }
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

  IconData _iconForQuickAction(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('pasaje')) return Icons.directions_bus;
    if (normalized.contains('cafe')) return Icons.local_cafe;
    if (normalized.contains('postre')) return Icons.cake_outlined;
    if (normalized.contains('taxi')) return Icons.local_taxi;
    return Icons.restaurant;
  }

  Color _colorFromHex(String? value) {
    if (value == null || value.length != 7 || !value.startsWith('#')) {
      return AppColors.red;
    }
    return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
  }
}

class _QuickExpenseData {
  const _QuickExpenseData({
    required this.accounts,
    required this.categories,
    required this.quickActions,
  });

  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final List<QuickActionModel> quickActions;
}
