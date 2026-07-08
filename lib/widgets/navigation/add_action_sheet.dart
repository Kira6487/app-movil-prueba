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
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/empty_state.dart';

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
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 24,
      shadowColor: AppColors.blue.withValues(alpha: 0.20),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
        ),
        child: FutureBuilder<_QuickExpenseData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.activeBorder.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SheetHeader(onClose: () => Navigator.of(context).pop()),
                  const SizedBox(height: 22),
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
          _AmountField(
            controller: _amountController,
            currency: _currency,
            validator: _validateAmount,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final accountField = _ExpenseDropdownCard<AccountModel>(
                label: 'Cuenta',
                placeholder: 'Seleccionar cuenta',
                icon: Icons.account_balance_outlined,
                color: AppColors.blue,
                items: data.accounts,
                itemLabel: (account) => account.name,
                value: _selectedAccount,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedAccount = value;
                    _currency = value.currency;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecciona una cuenta' : null,
              );
              final categoryField = _ExpenseDropdownCard<CategoryModel>(
                label: 'Categoria',
                placeholder: 'Seleccionar categoria',
                icon: Icons.local_offer_outlined,
                color: AppColors.purple,
                items: data.categories,
                itemLabel: (category) => category.name,
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? 'Selecciona una categoria' : null,
              );

              if (compact) {
                return Column(
                  children: [
                    accountField,
                    const SizedBox(height: 12),
                    categoryField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: accountField),
                  const SizedBox(width: 12),
                  Expanded(child: categoryField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _CommentField(controller: _commentController),
          const SizedBox(height: 16),
          _SaveExpenseButton(
            saving: _saving,
            onPressed: _saving ? null : _saveExpense,
          ),
          if (data.quickActions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Botones rapidos', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: data.quickActions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final action = data.quickActions[index];
                  return _QuickExpenseChip(
                    icon: _iconForQuickAction(action.name),
                    title: action.name,
                    amount: _formatQuickAmount(action),
                    color: _colorFromHex(action.color),
                    onTap: () => _applyQuickAction(action, data),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toca para registrar. Puedes editar el monto despues.',
                    style: AppTextStyles.muted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text('Mas acciones', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return GridView.count(
                crossAxisCount: compact ? 1 : 2,
                mainAxisExtent: 118,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _SecondaryActionTile(
                    icon: Icons.arrow_upward,
                    title: 'Registrar ingreso',
                    color: AppColors.green,
                    onTap: () => _openIncome(context),
                  ),
                  _SecondaryActionTile(
                    icon: Icons.sync_alt,
                    title: 'Transferencia',
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
                  _SecondaryActionTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'Pago programado',
                    color: AppColors.orange,
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'Pago programado',
                      description: 'No disponible en demo.',
                      icon: Icons.event_available_outlined,
                      color: AppColors.orange,
                    ),
                  ),
                  _SecondaryActionTile(
                    icon: Icons.savings_outlined,
                    title: 'Ahorro',
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
              );
            },
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

  String _formatQuickAmount(QuickActionModel action) {
    final amount = action.amount == action.amount.roundToDouble()
        ? action.amount.toStringAsFixed(0)
        : action.amount.toStringAsFixed(2);
    return action.currency == 'USD' ? '\$$amount' : 'S/ $amount';
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.cyan, AppColors.blueOtter],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar gasto', style: AppTextStyles.title),
              SizedBox(height: 3),
              Text('Registro rapido', style: AppTextStyles.muted),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceAlt.withValues(alpha: 0.88),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.close, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.validator,
  });

  final TextEditingController controller;
  final String currency;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final prefix = currency == 'USD' ? r'$' : 'S/';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monto', style: AppTextStyles.muted.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                prefix,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.green,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validator,
                  style: AppTextStyles.display.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.75),
                  ),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: AppColors.blue,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseDropdownCard<T> extends StatelessWidget {
  const _ExpenseDropdownCard({
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.color,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    required this.validator,
  });

  final String label;
  final String placeholder;
  final IconData icon;
  final Color color;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T> validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey<T?>(value),
      initialValue: value,
      validator: validator,
      builder: (field) {
        final selected = field.value ?? value;
        final text = selected == null ? placeholder : itemLabel(selected);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupMenuButton<T>(
              tooltip: label,
              color: AppColors.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (selectedValue) {
                field.didChange(selectedValue);
                onChanged(selectedValue);
              },
              itemBuilder: (context) => [
                for (final item in items)
                  PopupMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 86),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: field.hasError
                        ? AppColors.red
                        : AppColors.border.withValues(alpha: 0.85),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: color.withValues(alpha: 0.14),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTextStyles.muted),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: AppTextStyles.label.copyWith(color: AppColors.red),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: _panelDecoration(),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          labelText: 'Comentario (opcional)',
          hintText: 'En que lo gastaste?',
          suffixIcon: Icon(
            Icons.chat_bubble_outline,
            color: AppColors.blue.withValues(alpha: 0.82),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _SaveExpenseButton extends StatelessWidget {
  const _SaveExpenseButton({
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.cyan, AppColors.blueOtter],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  saving ? 'Guardando...' : 'Guardar gasto',
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickExpenseChip extends StatelessWidget {
  const _QuickExpenseChip({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String amount;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 126,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      amount,
                      style: AppTextStyles.body.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  const _SecondaryActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.80),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
  );
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
