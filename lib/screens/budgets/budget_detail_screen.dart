import 'package:flutter/material.dart';

import '../../models/budget_rule_model.dart';
import '../../models/budget_summary_model.dart';
import '../../providers/budget_change_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import 'budget_form_screen.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen(
      {super.key, required this.item, required this.month});
  final BudgetItemSummary item;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final rule = item.view.rule;
    final format = rule.currency == 'USD' ? formatUsd : formatSol;
    return AppScaffold(
      title: rule.name,
      subtitle: BudgetType.label(rule.budgetType),
      actions: [
        IconButton(
          tooltip: 'Editar presupuesto',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => BudgetFormScreen(
                      initial: item.view, initialMonth: month)),
            );
            BudgetChangeNotifier.notifyChanged();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
      children: [
        AppCard(
          child: Column(
            children: [
              _Row(label: 'Categoría', value: item.view.categoryName),
              _Row(label: 'Límite calculado', value: format(item.limit)),
              _Row(label: 'Gasto real del mes', value: format(item.spent)),
              _Row(label: 'Disponible', value: format(item.available)),
              _Row(
                  label: 'Porcentaje usado',
                  value: '${(item.usagePercent * 100).toStringAsFixed(0)}%'),
              _Row(label: 'Estado', value: item.status.label),
            ],
          ),
        ),
        if (rule.description?.trim().isNotEmpty == true ||
            rule.conditionText?.trim().isNotEmpty == true)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 10),
                if (rule.description?.trim().isNotEmpty == true)
                  Text(rule.description!, style: AppTextStyles.body),
                if (rule.conditionText?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('Condición: ${rule.conditionText}',
                      style: AppTextStyles.muted),
                ],
              ],
            ),
          ),
        AppCard(
          backgroundColor: AppColors.surfaceAlt,
          child: Text(
            rule.budgetType == BudgetType.savings
                ? 'Este objetivo se mantiene separado de los gastos. Su progreso quedará preparado para el módulo de ahorro.'
                : 'El gasto mostrado incluye transacciones reales de la categoría y excluye ingresos, transferencias, ajustes manuales y cuentas ocultas del presupuesto.',
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.muted)),
            const SizedBox(width: 12),
            Flexible(
                child: Text(value,
                    textAlign: TextAlign.end, style: AppTextStyles.cardTitle)),
          ],
        ),
      );
}
