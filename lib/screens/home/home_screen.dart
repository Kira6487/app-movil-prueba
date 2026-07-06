import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cards/finance_card.dart';
import '../../widgets/common/app_screen.dart';
import '../../widgets/common/month_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Inicio',
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Notificaciones estaran disponibles pronto')),
          ),
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Configuracion estara disponible pronto')),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      children: const [
        MonthSelector(),
        Row(
          children: [
            Expanded(
              child: _StatusCard(
                title: 'Estado Diario',
                status: 'Bueno',
                description: 'Gasto dentro del presupuesto',
                color: AppColors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatusCard(
                title: 'Estado Mensual',
                status: 'En alerta',
                description: 'Vas 78% del presupuesto',
                color: AppColors.orange,
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        _MonthlySummaryCard(),
        _BudgetLimitCard(),
        _AccountsSummaryCard(),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.status,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String title;
  final String status;
  final String description;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(status,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard();

  @override
  Widget build(BuildContext context) {
    return const FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del mes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          MetricRow(
              label: 'Ingreso total',
              value: 'S/ 2,450.00',
              valueColor: AppColors.green),
          MetricRow(label: 'Gasto presupuestado', value: 'S/ 1,800.00'),
          MetricRow(
              label: 'Ahorro presupuestado',
              value: 'S/ 500.00',
              valueColor: AppColors.purple),
          MetricRow(
              label: 'Gasto real',
              value: 'S/ 1,410.50',
              valueColor: AppColors.red),
          Divider(height: 24),
          MetricRow(
              label: 'Disponible',
              value: 'S/ 389.50',
              valueColor: AppColors.green),
          MetricRow(
              label: 'Ahorro generado',
              value: 'S/ 389.50',
              valueColor: AppColors.green),
        ],
      ),
    );
  }
}

class _BudgetLimitCard extends StatelessWidget {
  const _BudgetLimitCard();

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gasto real vs. limite de presupuesto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              minHeight: 12,
              value: 0.78,
              color: AppColors.orange,
              backgroundColor: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('S/ 1,410.50 usado'),
              Text('78%',
                  style: TextStyle(
                      color: AppColors.orange, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountsSummaryCard extends StatelessWidget {
  const _AccountsSummaryCard();

  @override
  Widget build(BuildContext context) {
    return const FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de cuentas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          MetricRow(
              label: 'BCP Ahorros',
              value: 'S/ 850.00',
              valueColor: AppColors.blue),
          MetricRow(
              label: 'Yape', value: 'S/ 120.00', valueColor: AppColors.purple),
          MetricRow(
              label: 'Cuenta USD',
              value: r'$200.00 / S/ 760.00',
              valueColor: AppColors.green),
          MetricRow(
              label: 'Plazo Fijo',
              value: 'S/ 3,000.00 oculto',
              valueColor: AppColors.orange),
        ],
      ),
    );
  }
}
