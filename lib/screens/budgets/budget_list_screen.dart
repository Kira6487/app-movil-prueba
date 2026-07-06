import 'package:flutter/material.dart';

import '../../models/budget_summary_model.dart';
import '../../providers/budget_change_notifier.dart';
import '../../services/budget_calculator.dart';
import '../../services/budget_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import 'budget_form_screen.dart';

class BudgetListScreen extends StatelessWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AppScaffold(
      title: 'Presupuestos',
      children: [
        AppPrimaryButton(
          label: 'Nuevo presupuesto',
          icon: Icons.add,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BudgetFormScreen()),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: BudgetChangeNotifier.version,
          builder: (context, _, __) {
            return FutureBuilder<BudgetOverview>(
              future: BudgetService().getOverview(
                year: now.year,
                month: now.month,
                today: now,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    title: 'No se pudieron cargar presupuestos',
                    message: 'Intenta nuevamente.',
                    icon: Icons.error_outline,
                  );
                }
                final overview = snapshot.data!;
                return _BudgetTotalsCard(overview: overview);
              },
            );
          },
        ),
        const SectionHeader(
          title: 'Presupuestos creados',
          subtitle: 'Toca una regla para editarla o desactivarla.',
        ),
        ValueListenableBuilder<int>(
          valueListenable: BudgetChangeNotifier.version,
          builder: (context, _, __) {
            return FutureBuilder<List<BudgetRuleView>>(
              future: BudgetService().getBudgetRuleViews(activeOnly: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    title: 'No se pudo cargar la lista',
                    message: 'Revisa la base local e intenta nuevamente.',
                    icon: Icons.error_outline,
                  );
                }
                final rules = snapshot.data ?? const [];
                if (rules.isEmpty) {
                  return const EmptyState(
                    title: 'No hay presupuestos configurados',
                    message: 'Crea tu primer presupuesto para calcular estados reales.',
                    icon: Icons.track_changes_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final view in rules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BudgetRuleCard(view: view),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _BudgetTotalsCard extends StatelessWidget {
  const _BudgetTotalsCard({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total presupuestado del mes', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          _Metric(label: 'Presupuesto mensual', value: formatSol(overview.monthBudget)),
          _Metric(label: 'Presupuesto acumulado', value: formatSol(overview.accumulatedBudget)),
          _Metric(label: 'Gasto real del mes', value: formatSol(overview.monthSpent), color: AppColors.red),
          _Metric(label: 'Disponible', value: formatSol(overview.available), color: overview.available >= 0 ? AppColors.green : AppColors.red),
        ],
      ),
    );
  }
}

class _BudgetRuleCard extends StatelessWidget {
  const _BudgetRuleCard({required this.view});

  final BudgetRuleView view;

  @override
  Widget build(BuildContext context) {
    final rule = view.rule;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BudgetFormScreen(initial: view)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rule.isActive
                ? AppColors.blue.withValues(alpha: 0.16)
                : AppColors.textMuted.withValues(alpha: 0.16),
            child: Icon(
              rule.isActive ? Icons.track_changes_outlined : Icons.pause_circle_outline,
              color: rule.isActive ? AppColors.blue : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(view.categoryName, style: AppTextStyles.muted),
                const SizedBox(height: 4),
                Text(BudgetRecurrenceType.label(rule.recurrenceType), style: AppTextStyles.muted),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatAmount(rule.currency, rule.amount), style: AppTextStyles.amount),
              const SizedBox(height: 4),
              Text(rule.isActive ? 'Activo' : 'Inactivo', style: AppTextStyles.label),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(String currency, double amount) {
    return currency == 'USD' ? formatUsd(amount) : formatSol(amount);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.muted)),
          Text(value, style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
