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
import '../../widgets/inputs/color_palette_field.dart';
import '../../widgets/inputs/savings_icon_palette_field.dart';
import 'savings_goal_form_screen.dart';

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
  String _icon = 'savings_general';
  String _color = '#7C3AED';
  bool _saving = false;
  bool _loadingGoals = false;
  List<SavingsGoalModel> _goals = const [];

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
    if (widget.initial != null) {
      _category = _findCategory(categories, widget.initial!.savingsCategoryId);
      await _refreshGoals(notify: false);
      _goal = _findGoal(_goals, widget.initial!.savingsItemId);
    }
    return _WalletData(categories);
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
                    onChanged: (value) async {
                      setState(() {
                        _category = value;
                        _goal = null;
                      });
                      await _refreshGoals();
                    },
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 14),
                  if (_loadingGoals)
                    const LinearProgressIndicator()
                  else if (_goals.isEmpty)
                    Column(
                      children: [
                        const Text(
                            'No hay objetivos de ahorro activos compatibles.'),
                        TextButton.icon(
                          onPressed: _category == null ? null : _createGoal,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear objetivo de ahorro'),
                        ),
                      ],
                    )
                  else
                    AppDropdownField<SavingsGoalModel>(
                      label: 'Contrapartida de ahorro',
                      items: _goals,
                      itemLabel: (item) => '${item.name} · ${item.currency}',
                      selectedItemLabel: (item) => item.name,
                      value: _goal,
                      onChanged: (value) => setState(() => _goal = value),
                      validator: (value) =>
                          value == null ? 'Selecciona un objetivo' : null,
                    ),
                  const SizedBox(height: 14),
                  SavingsIconPaletteField(
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

  Future<void> _refreshGoals({bool notify = true}) async {
    final categoryId = _category?.id;
    if (categoryId == null) {
      _goals = const [];
      return;
    }
    if (notify && mounted) setState(() => _loadingGoals = true);
    final goals = await SavingsService().getCompatibleSavingsGoals(
      savingsCategoryId: categoryId,
      currency: widget.account.currency,
    );
    if (!mounted && notify) return;
    _goals = goals;
    if (!_goals.any((item) => item.id == _goal?.id)) _goal = null;
    if (notify) setState(() => _loadingGoals = false);
  }

  Future<void> _createGoal() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => SavingsGoalFormScreen(
        initialCategory: _category,
        initialCurrency: widget.account.currency,
      ),
    ));
    if (!mounted || created != true) return;
    await _refreshGoals();
  }
}

class _WalletData {
  const _WalletData(this.categories);
  final List<CategoryModel> categories;
}
