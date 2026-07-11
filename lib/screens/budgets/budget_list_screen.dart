import 'package:flutter/material.dart';

import '../../models/budget_rule_model.dart';
import '../../models/budget_summary_model.dart';
import '../../providers/budget_change_notifier.dart';
import '../../services/budget_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/inputs/color_palette_field.dart';
import 'budget_detail_screen.dart';
import 'budget_form_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Presupuestos',
      subtitle: 'Planifica con tus movimientos reales',
      actions: [
        IconButton(
          tooltip: 'Nuevo presupuesto',
          onPressed: _openCreate,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
      children: [
        _MonthPicker(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        _FilterBar(
            value: _filter,
            onChanged: (value) => setState(() => _filter = value)),
        ValueListenableBuilder<int>(
          valueListenable: BudgetChangeNotifier.version,
          builder: (context, _, __) => FutureBuilder<BudgetOverview>(
            future: BudgetService().getOverview(
              year: _month.year,
              month: _month.month,
              today: DateTime.now(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const EmptyState(
                  title: 'No se pudieron cargar presupuestos',
                  message: 'Revisa la base local e intenta nuevamente.',
                  icon: Icons.error_outline,
                );
              }
              return _Dashboard(
                overview: snapshot.data!,
                filter: _filter,
                month: _month,
                onCreate: _openCreate,
              );
            },
          ),
        ),
      ],
    );
  }

  void _changeMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetFormScreen(initialMonth: _month),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker(
      {required this.month, required this.onPrevious, required this.onNext});
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const names = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
                onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                '${names[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle,
              ),
            ),
            IconButton(
                onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in const [
              ('all', 'Todos'),
              (BudgetType.category, 'Categorías'),
              (BudgetType.recurrence, 'Repetición'),
              (BudgetType.customRule, 'Reglas'),
            ]) ...[
              ChoiceChip(
                label: Text(item.$2),
                selected: value == item.$1,
                onSelected: (_) => onChanged(item.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.overview,
    required this.filter,
    required this.month,
    required this.onCreate,
  });
  final BudgetOverview overview;
  final String filter;
  final DateTime month;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final visible = overview.items
        .where((item) => filter == 'all' || item.view.rule.budgetType == filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(overview: overview),
        const SizedBox(height: 22),
        if (overview.items.isEmpty)
          EmptyState(
            title: 'Aún no tienes presupuestos',
            message:
                'Crea el primero para comparar límites con tus gastos reales.',
            icon: Icons.track_changes_outlined,
            action: AppPrimaryButton(
              label: 'Crear presupuesto',
              icon: Icons.add,
              onPressed: onCreate,
            ),
          )
        else if (visible.isEmpty)
          const EmptyState(
            title: 'Sin resultados para este filtro',
            message: 'Prueba otro tipo de presupuesto.',
            icon: Icons.filter_alt_off_outlined,
          )
        else ...[
          if (filter == 'all' || filter == BudgetType.category)
            _Section(
              title: 'Por categorías',
              subtitle: 'Límites comparados con gastos del mes.',
              items: visible
                  .where((item) =>
                      item.view.rule.budgetType == BudgetType.category)
                  .toList(),
              month: month,
            ),
          if (filter == 'all' || filter == BudgetType.recurrence)
            _Section(
              title: 'Calculados por fechas',
              subtitle: 'El límite cambia según los días del mes.',
              items: visible
                  .where((item) =>
                      item.view.rule.budgetType == BudgetType.recurrence)
                  .toList(),
              month: month,
            ),
          if (filter == 'all' || filter == BudgetType.customRule)
            _Section(
              title: 'Reglas propias',
              subtitle: 'Topes personalizados y condiciones simples.',
              items: visible
                  .where((item) =>
                      item.view.rule.budgetType == BudgetType.customRule)
                  .toList(),
              month: month,
            ),
          if (filter == 'all')
            _Section(
              title: 'Objetivos de ahorro',
              subtitle: 'Metas separadas de tus gastos.',
              items: visible
                  .where(
                      (item) => item.view.rule.budgetType == BudgetType.savings)
                  .toList(),
              month: month,
            ),
          const SizedBox(height: 8),
          _Alerts(items: overview.items),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.overview});
  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    final status = overview.monthlyStatus;
    final color = _statusColor(status);
    final progress = overview.monthUsagePercent.clamp(0.0, 1.0);
    final message = overview.available < 0
        ? 'Superaste tu presupuesto por ${formatSol(-overview.available)}.'
        : 'Te quedan ${formatSol(overview.available)} para el resto del mes.';
    return AppCard(
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presupuesto mensual',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(formatSol(overview.monthBudget),
              style: AppTextStyles.amount.copyWith(fontSize: 30)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 10),
          Text(
            'Has usado ${(overview.monthUsagePercent * 100).toStringAsFixed(0)}% · $message',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _Metric(
                      label: 'Usado',
                      value: formatSol(overview.monthSpent),
                      color: AppColors.red)),
              Expanded(
                  child: _Metric(
                      label: 'Disponible',
                      value: formatSol(overview.available),
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.subtitle,
      required this.items,
      required this.month});
  final String title;
  final String subtitle;
  final List<BudgetItemSummary> items;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 10),
          for (final item in items) ...[
            _BudgetCard(item: item, month: month),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.item, required this.month});
  final BudgetItemSummary item;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final rule = item.view.rule;
    final color = colorFromHex(rule.colorHex ?? item.view.categoryColor);
    final statusColor = _statusColor(item.status);
    final amount = rule.currency == 'USD' ? formatUsd : formatSol;
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BudgetDetailScreen(item: item, month: month),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(
                    iconDataForId(rule.iconKey ?? item.view.categoryIcon),
                    color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.name,
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      rule.budgetType == BudgetType.recurrence
                          ? item.formula
                          : item.view.categoryName,
                      style: AppTextStyles.muted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: Text(
                      '${amount(item.spent)} usados de ${amount(item.limit)}',
                      style: AppTextStyles.body)),
              Text('${(item.usagePercent * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.label.copyWith(color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: item.usagePercent.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: statusColor,
            backgroundColor: statusColor.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.items});
  final List<BudgetItemSummary> items;

  @override
  Widget build(BuildContext context) {
    final alerts = items
        .where((item) => item.view.rule.budgetType != BudgetType.savings)
        .toList()
      ..sort((a, b) => b.usagePercent.compareTo(a.usagePercent));
    if (alerts.isEmpty) return const SizedBox.shrink();
    final item = alerts.first;
    final text = switch (item.status) {
      BudgetStatus.exceeded =>
        '${item.view.rule.name} superó el presupuesto por ${formatSol(-item.baseLimit + item.baseSpent)}.',
      BudgetStatus.warning => '${item.view.rule.name} está cerca del límite.',
      _ =>
        'Aún tienes ${formatSol(item.baseLimit - item.baseSpent)} disponibles en ${item.view.rule.name}.',
    };
    return AppCard(
      backgroundColor: _statusColor(item.status).withValues(alpha: 0.08),
      borderColor: _statusColor(item.status).withValues(alpha: 0.28),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: _statusColor(item.status)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BudgetStatus status;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status.label,
            style: AppTextStyles.label.copyWith(color: _statusColor(status))),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.muted),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
        ],
      );
}

Color _statusColor(BudgetStatus status) => switch (status) {
      BudgetStatus.warning => AppColors.orange,
      BudgetStatus.exceeded => AppColors.red,
      BudgetStatus.good => AppColors.green,
      BudgetStatus.empty => AppColors.blue,
    };
