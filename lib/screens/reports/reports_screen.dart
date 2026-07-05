import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cards/finance_card.dart';
import '../../widgets/common/app_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Reportes',
      children: const [
        _ReportFilters(),
        _ReportGrid(),
      ],
    );
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _FilterBox(label: 'Mes', value: 'Mayo 2025')),
        SizedBox(width: 10),
        Expanded(child: _FilterBox(label: 'Cuenta', value: 'Todas')),
        SizedBox(width: 10),
        Expanded(child: _FilterBox(label: 'Categoria', value: 'Todas')),
      ],
    );
  }
}

class _FilterBox extends StatelessWidget {
  const _FilterBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid();

  static const reports = [
    _ReportItem(Icons.category_outlined, 'Reporte por categoria', AppColors.red),
    _ReportItem(Icons.account_balance_outlined, 'Reporte por cuenta', AppColors.blue),
    _ReportItem(Icons.track_changes_outlined, 'Presupuesto vs. Gasto', AppColors.orange),
    _ReportItem(Icons.currency_exchange, 'Diferencia de cambio', AppColors.green),
    _ReportItem(Icons.credit_card, 'Tarjetas de credito', AppColors.purple),
    _ReportItem(Icons.savings_outlined, 'Ahorro', AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final report = reports[index];
        return FinanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: report.color.withValues(alpha: 0.16),
                child: Icon(report.icon, color: report.color),
              ),
              const Spacer(),
              Text(report.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        );
      },
    );
  }
}

class _ReportItem {
  const _ReportItem(this.icon, this.title, this.color);

  final IconData icon;
  final String title;
  final Color color;
}
