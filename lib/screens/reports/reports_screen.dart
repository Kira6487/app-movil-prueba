import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cards/report_option_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../placeholders/action_placeholder_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const _reports = [
    _ReportItem(Icons.category_outlined, 'Reporte por categoría',
        'Agrupa gastos por tipo', AppColors.red),
    _ReportItem(Icons.account_balance_outlined, 'Reporte por cuenta',
        'Revisa saldos y movimientos', AppColors.blue),
    _ReportItem(Icons.track_changes_outlined, 'Presupuesto vs. gasto',
        'Compara avance mensual', AppColors.orange),
    _ReportItem(Icons.currency_exchange, 'Diferencia de cambio',
        'Visualiza impacto USD/SOL', AppColors.green),
    _ReportItem(Icons.credit_card, 'Tarjetas de crédito',
        'Consumos y cuotas demo', AppColors.purple),
    _ReportItem(Icons.savings_outlined, 'Ahorro', 'Metas y progreso esperado',
        AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reportes',
      children: [
        const SectionHeader(
          title: 'Filtros',
          subtitle: 'Controles visuales demo para futuras consultas',
        ),
        const _ReportFilters(),
        const SectionHeader(
          title: 'Opciones de reporte',
          subtitle: 'Accesos preparados para Fase 4',
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reports.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final report = _reports[index];
            return ReportOptionCard(
              icon: report.icon,
              title: report.title,
              description: report.description,
              color: report.color,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActionPlaceholderScreen(
                    title: report.title,
                    description:
                        'Este reporte se conectará a datos reales en una fase posterior.',
                    icon: report.icon,
                    color: report.color,
                  ),
                ),
              ),
            );
          },
        ),
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
        Expanded(child: _FilterBox(label: 'Categoría', value: 'Todas')),
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
    return AppCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value,
              overflow: TextOverflow.ellipsis, style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}

class _ReportItem {
  const _ReportItem(this.icon, this.title, this.description, this.color);

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
