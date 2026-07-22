import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../models/savings_goal_model.dart';
import '../../providers/savings_change_notifier.dart';
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

class SavingsGoalFormScreen extends StatefulWidget {
  const SavingsGoalFormScreen({
    super.key,
    this.initial,
    this.initialCategory,
    this.initialCurrency,
  });

  final SavingsGoalModel? initial;
  final CategoryModel? initialCategory;
  final String? initialCurrency;

  @override
  State<SavingsGoalFormScreen> createState() => _SavingsGoalFormScreenState();
}

class _SavingsGoalFormScreenState extends State<SavingsGoalFormScreen> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  late Future<List<CategoryModel>> _categoriesFuture;
  CategoryModel? _category;
  late String _currency;
  late String _icon;
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController.text = initial?.name ?? '';
    _targetController.text = initial?.targetAmount.toStringAsFixed(2) ?? '';
    _currency = initial?.currency ?? widget.initialCurrency ?? 'SOL';
    _icon = initial?.iconKey ?? 'savings_general';
    _color = initial?.colorHex ?? '#7C3AED';
    _category = widget.initialCategory;
    _categoriesFuture = _loadCategories();
  }

  Future<List<CategoryModel>> _loadCategories() async {
    final categories = await CategoryService().getCategoriesByType('savings');
    final initialId = widget.initial?.categoryId ?? widget.initialCategory?.id;
    _category = categories.where((item) => item.id == initialId).firstOrNull;
    return categories;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.initial == null ? 'Nuevo objetivo' : 'Editar objetivo',
      children: [
        FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return AppCard(
              child: Column(
                children: [
                  AppTextInput(label: 'Nombre', controller: _nameController),
                  const SizedBox(height: 14),
                  AppTextInput(
                    label: 'Monto objetivo',
                    controller: _targetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<CategoryModel>(
                    label: 'Categoría de ahorro',
                    items: snapshot.data!,
                    itemLabel: (item) => item.name,
                    value: _category,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownField<String>(
                    label: 'Moneda',
                    items: const ['SOL', 'USD'],
                    itemLabel: (item) => item,
                    value: _currency == 'PEN' ? 'SOL' : _currency,
                    onChanged: (value) =>
                        setState(() => _currency = value ?? 'SOL'),
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
                    label: _saving ? 'Guardando...' : 'Guardar objetivo',
                    icon: Icons.save_outlined,
                    onPressed: _saving ? null : _save,
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
    final target = double.tryParse(_targetController.text.replaceAll(',', '.'));
    if (_nameController.text.trim().isEmpty ||
        target == null ||
        target <= 0 ||
        _category == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      final goal = SavingsGoalModel(
        id: initial?.id,
        name: _nameController.text.trim(),
        categoryId: _category!.id!,
        targetAmount: target,
        currentAmount: initial?.currentAmount ?? 0,
        currency: _currency,
        plannedMonthlyAmount: initial?.plannedMonthlyAmount,
        deadline: initial?.deadline,
        iconKey: _icon,
        colorHex: _color,
        isActive: initial?.isActive ?? true,
        createdAt: initial?.createdAt ?? AppDateUtils.nowIso(),
      );
      if (initial == null) {
        await SavingsService().insertSavingsGoal(goal);
      } else {
        await SavingsService().updateSavingsGoal(goal);
      }
      SavingsChangeNotifier.notifyChanged();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
