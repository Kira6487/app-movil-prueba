import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/wallet_model.dart';
import '../../services/category_service.dart';
import '../../services/savings_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import '../../widgets/inputs/app_text_input.dart';

class WalletFormScreen extends StatefulWidget {
  const WalletFormScreen({super.key, required this.account, this.initial});

  final AccountModel account;
  final WalletModel? initial;

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _nameController = TextEditingController();
  late Future<_WalletData> _dataFuture;
  CategoryModel? _category;
  SavingsGoalModel? _goal;
  String _icon = 'piggy';
  String _color = '#7C3AED';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController.text = initial?.name ?? '';
    _icon = initial?.iconKey ?? _icon;
    _color = initial?.colorHex ?? _color;
    _dataFuture = _load();
  }

  Future<_WalletData> _load() async {
    final categories = await CategoryService().getCategoriesByType('savings');
    final goals = await SavingsService().getAllSavingsGoals();
    if (widget.initial != null) {
      _category = _findCategory(categories, widget.initial!.savingsCategoryId);
      _goal = _findGoal(goals, widget.initial!.savingsItemId);
    }
    return _WalletData(categories, goals);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.initial == null ? 'Nueva alcancía' : 'Editar alcancía',
      children: [
        FutureBuilder<_WalletData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final goals = data.goals
                .where((goal) =>
                    goal.categoryId == _category?.id &&
                    goal.currency == widget.account.currency)
                .toList();
            return AppCard(
              child: Column(
                children: [
                  AppTextInput(label: 'Nombre', controller: _nameController),
                  const SizedBox(height: 14),
                  AppTextInput(
                    label: 'Cuenta padre',
                    controller: TextEditingController(
                        text:
                            '${widget.account.name} · ${widget.account.currency}'),
                    enabled: false,
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<CategoryModel>(
                    label: 'Categoría de ahorro',
                    items: data.categories,
                    itemLabel: (item) => item.name,
                    value: _category,
                    onChanged: (value) => setState(() {
                      _category = value;
                      _goal = null;
                    }),
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 14),
                  if (goals.isEmpty)
                    const Text(
                        'No hay objetivos de ahorro activos compatibles.')
                  else
                    AppDropdownField<SavingsGoalModel>(
                      label: 'Contrapartida de ahorro',
                      items: goals,
                      itemLabel: (item) => '${item.name} · ${item.currency}',
                      selectedItemLabel: (item) => item.name,
                      value: _goal,
                      onChanged: (value) => setState(() => _goal = value),
                      validator: (value) =>
                          value == null ? 'Selecciona un objetivo' : null,
                    ),
                  const SizedBox(height: 14),
                  AppDropdownField<String>(
                    label: 'Icono',
                    items: const ['piggy', 'savings', 'wallet'],
                    itemLabel: (item) => item,
                    value: _icon,
                    onChanged: (value) =>
                        setState(() => _icon = value ?? _icon),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<String>(
                    label: 'Color',
                    items: const ['#7C3AED', '#005FD1', '#22C55E', '#F97316'],
                    itemLabel: (item) => item,
                    value: _color,
                    onChanged: (value) =>
                        setState(() => _color = value ?? _color),
                  ),
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar alcancía',
                    icon: Icons.save_outlined,
                    onPressed: _saving || _goal == null || _category == null
                        ? null
                        : _save,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _category == null || _goal == null) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      final now = AppDateUtils.nowIso();
      final wallet = WalletModel(
        id: initial?.id,
        name: name,
        accountId: widget.account.id!,
        ledgerAccountId: initial?.ledgerAccountId,
        amount: initial?.amount ?? 0,
        currency: widget.account.currency,
        type: initial?.type ?? 'piggyBank',
        iconKey: _icon,
        colorHex: _color,
        savingsCategoryId: _category!.id,
        savingsItemId: _goal!.id,
        isActive: initial?.isActive ?? true,
        createdAt: initial?.createdAt ?? now,
        updatedAt: now,
      );
      if (initial == null) {
        await SavingsService().insertWallet(wallet);
      } else {
        await SavingsService().updateWallet(wallet);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  CategoryModel? _findCategory(List<CategoryModel> items, int? id) =>
      items.where((item) => item.id == id).firstOrNull;
  SavingsGoalModel? _findGoal(List<SavingsGoalModel> items, int? id) =>
      items.where((item) => item.id == id).firstOrNull;
}

class _WalletData {
  const _WalletData(this.categories, this.goals);
  final List<CategoryModel> categories;
  final List<SavingsGoalModel> goals;
}
