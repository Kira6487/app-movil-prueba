import 'package:flutter/material.dart';

import '../../models/budget_rule_model.dart';
import '../../models/budget_summary_model.dart';
import '../../models/category_model.dart';
import '../../providers/budget_change_notifier.dart';
import '../../services/budget_calculator.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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

class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({super.key, this.initial, this.initialMonth});

  final BudgetRuleView? initial;
  final DateTime? initialMonth;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _conditionController = TextEditingController();

  late Future<List<CategoryModel>> _categoriesFuture;
  CategoryModel? _selectedCategory;
  String _currency = 'SOL';
  String _budgetType = BudgetType.category;
  String _recurrenceType = BudgetRecurrenceType.monthly;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _saving = false;
  String _icon = 'wallet';
  String _color = '#005FD1';
  final Set<int> _selectedWeekdays = <int>{};

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final selectedMonth = widget.initialMonth ?? DateTime.now();
    _startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    _categoriesFuture = _loadCategories();
    final initial = widget.initial?.rule;
    if (initial != null) {
      _nameController.text = initial.name;
      _amountController.text = _formatNumber(initial.amount);
      _currency = initial.currency;
      _budgetType = initial.budgetType;
      _recurrenceType = initial.recurrenceType;
      _unitsController.text = _formatNumber(initial.unitsPerDay);
      _descriptionController.text = initial.description ?? '';
      _conditionController.text = initial.conditionText ?? '';
      _icon = initial.iconKey ?? _icon;
      _color = initial.colorHex ?? _color;
      _startDate = DateTime.tryParse(initial.startDate ?? '') ?? DateTime.now();
      _endDate = DateTime.tryParse(initial.endDate ?? '');
      _isActive = initial.isActive;
      _selectedWeekdays
          .addAll(BudgetCalculator.parseWeekdays(initial.selectedWeekdays));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitsController.dispose();
    _descriptionController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<List<CategoryModel>> _loadCategories() async {
    final categories = (await CategoryService().getAllCategories())
        .where((category) => category.type == 'expense')
        .toList();
    final initial = widget.initial?.rule;
    if (initial != null) {
      for (final category in categories) {
        if (category.id == initial.categoryId) {
          _selectedCategory = category;
          break;
        }
      }
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto',
      children: [
        FutureBuilder<List<CategoryModel>>(
          future: _categoriesFuture,
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
            final categories = snapshot.data ?? const [];
            if (categories.isEmpty) {
              return const EmptyState(
                title: 'No hay categorias de gasto',
                message: 'Crea categorias antes de registrar presupuestos.',
                icon: Icons.category_outlined,
              );
            }
            return AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextInput(
                      label: 'Nombre del presupuesto',
                      controller: _nameController,
                      prefixIcon: Icons.edit_outlined,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Ingresa un nombre'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<String>(
                      label: 'Tipo de presupuesto',
                      items: BudgetType.values,
                      itemLabel: BudgetType.label,
                      value: _budgetType,
                      prefixIcon: Icons.tune,
                      onChanged: (value) => setState(() {
                        _budgetType = value ?? BudgetType.category;
                        _recurrenceType = _budgetType == BudgetType.recurrence
                            ? BudgetRecurrenceType.customWeekdays
                            : BudgetRecurrenceType.monthly;
                      }),
                    ),
                    const SizedBox(height: 14),
                    if (_budgetType != BudgetType.savings) ...[
                      AppDropdownField<CategoryModel>(
                        label: 'Categoría asociada',
                        items: categories,
                        itemLabel: (category) => category.name,
                        value: _selectedCategory,
                        prefixIcon: Icons.category_outlined,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        validator: (value) =>
                            _budgetType != BudgetType.savings && value == null
                                ? 'Selecciona una categoría'
                                : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    AppTextInput(
                      label: _budgetType == BudgetType.recurrence
                          ? 'Monto unitario'
                          : (_budgetType == BudgetType.savings
                              ? 'Objetivo mensual'
                              : 'Monto límite'),
                      hintText: '0.00',
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      onChanged: (value) =>
                          setState(() => _currency = value ?? 'SOL'),
                    ),
                    const SizedBox(height: 14),
                    if (_budgetType == BudgetType.recurrence) ...[
                      const SizedBox(height: 14),
                      _WeekdaySelector(
                        selected: _selectedWeekdays,
                        onChanged: (selected) {
                          setState(() {
                            _selectedWeekdays
                              ..clear()
                              ..addAll(selected);
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextInput(
                        label: 'Cantidad por día',
                        controller: _unitsController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.numbers,
                        validator: _validateAmount,
                      ),
                    ],
                    if (_budgetType == BudgetType.customRule) ...[
                      const SizedBox(height: 14),
                      AppTextInput(
                        label: 'Descripción de la regla',
                        controller: _descriptionController,
                        prefixIcon: Icons.notes_outlined,
                      ),
                      const SizedBox(height: 14),
                      AppTextInput(
                        label: 'Condición opcional',
                        controller: _conditionController,
                        prefixIcon: Icons.rule_outlined,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Fecha inicial',
                      controller:
                          TextEditingController(text: _formatDate(_startDate)),
                      readOnly: true,
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.expand_more),
                      onTap: () => _pickStartDate(context),
                    ),
                    const SizedBox(height: 14),
                    AppTextInput(
                      label: 'Fecha final opcional',
                      controller: TextEditingController(
                          text: _endDate == null ? '' : _formatDate(_endDate!)),
                      readOnly: true,
                      prefixIcon: Icons.event_busy_outlined,
                      suffixIcon: _endDate == null
                          ? const Icon(Icons.expand_more)
                          : IconButton(
                              onPressed: () => setState(() => _endDate = null),
                              icon: const Icon(Icons.close),
                            ),
                      onTap: () => _pickEndDate(context),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo'),
                      subtitle: const Text(
                          'Incluir este presupuesto en los calculos'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: 14),
                    IconPaletteField(
                      label: 'Ícono',
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
                    if (_isEditing && widget.initial!.rule.isActive) ...[
                      const SizedBox(height: 12),
                      AppSecondaryButton(
                        label: 'Desactivar presupuesto',
                        icon: Icons.pause_circle_outline,
                        onPressed: _saving ? null : _deactivate,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_budgetType == BudgetType.recurrence && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos un dia personalizado')),
      );
      return;
    }
    final category = _selectedCategory;
    if (_budgetType != BudgetType.savings && category == null) return;

    setState(() => _saving = true);
    try {
      final now = AppDateUtils.nowIso();
      final rule = BudgetRuleModel(
        id: widget.initial?.rule.id,
        name: _nameController.text.trim(),
        budgetType: _budgetType,
        categoryId: _budgetType == BudgetType.savings ? null : category!.id!,
        amount: _parseAmount(_amountController.text)!,
        currency: _currency,
        recurrenceType: _recurrenceType,
        selectedWeekdays: _budgetType == BudgetType.recurrence
            ? BudgetCalculator.encodeWeekdays(_selectedWeekdays)
            : null,
        unitsPerDay: _budgetType == BudgetType.recurrence
            ? _parseAmount(_unitsController.text)!
            : 1,
        description: _emptyToNull(_descriptionController.text),
        conditionText: _emptyToNull(_conditionController.text),
        startDate: AppDateUtils.dateOnlyIso(_startDate),
        endDate: _endDate == null ? null : AppDateUtils.dateOnlyIso(_endDate!),
        iconKey: _icon,
        colorHex: _color,
        isActive: _isActive,
        createdAt: widget.initial?.rule.createdAt ?? now,
        updatedAt: now,
      );
      if (_isEditing) {
        await BudgetService().updateBudgetRule(rule);
      } else {
        await BudgetService().insertBudgetRule(rule);
      }
      BudgetChangeNotifier.notifyChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto guardado')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    final id = widget.initial?.rule.id;
    if (id == null) return;
    setState(() => _saving = true);
    await BudgetService().deactivateBudgetRule(id);
    BudgetChangeNotifier.notifyChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Presupuesto desactivado')),
    );
    Navigator.of(context).pop();
  }

  String? _validateAmount(String? value) {
    final amount = _parseAmount(value ?? '');
    if (amount == null || amount <= 0) return 'Ingresa un monto mayor a 0';
    return null;
  }

  double? _parseAmount(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const labels = {
    DateTime.monday: 'Lun',
    DateTime.tuesday: 'Mar',
    DateTime.wednesday: 'Mie',
    DateTime.thursday: 'Jue',
    DateTime.friday: 'Vie',
    DateTime.saturday: 'Sab',
    DateTime.sunday: 'Dom',
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dias personalizados', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in labels.entries)
                FilterChip(
                  selected: selected.contains(entry.key),
                  label: Text(entry.value),
                  onSelected: (value) {
                    final next = {...selected};
                    if (value) {
                      next.add(entry.key);
                    } else {
                      next.remove(entry.key);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
