import 'package:flutter/material.dart';

import '../../providers/transaction_change_notifier.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards/progress_bar_card.dart';
import '../../widgets/cards/status_card.dart';
import '../../widgets/cards/summary_card.dart';
import '../../widgets/cards/transaction_history_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/month_selector.dart';
import '../../widgets/common/section_header.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Inicio',
      actions: [
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificaciones estarán disponibles pronto'),
            ),
          ),
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          tooltip: 'Configuración',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      children: const [
        MonthSelector(),
        Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Estado Diario',
                status: 'Bueno',
                description: 'Gasto dentro del presupuesto',
                color: AppColors.green,
                icon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatusCard(
                title: 'Estado Mensual',
                status: 'En alerta',
                description: 'Vas 78% del presupuesto',
                color: AppColors.orange,
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        SectionHeader(
          title: 'Resumen financiero',
          subtitle: 'Datos demo para validar estructura visual',
        ),
        SummaryCard(
          title: 'Resumen del mes',
          icon: Icons.receipt_long_outlined,
          accentColor: AppColors.green,
          items: [
            SummaryItem(
              label: 'Ingreso total',
              value: 'S/ 2,450.00',
              valueColor: AppColors.green,
            ),
            SummaryItem(label: 'Gasto presupuestado', value: 'S/ 1,800.00'),
            SummaryItem(
              label: 'Ahorro presupuestado',
              value: 'S/ 500.00',
              valueColor: AppColors.purple,
            ),
            SummaryItem(
              label: 'Gasto real',
              value: 'S/ 1,410.50',
              valueColor: AppColors.red,
            ),
            SummaryItem(
              label: 'Disponible',
              value: 'S/ 389.50',
              valueColor: AppColors.green,
            ),
            SummaryItem(
              label: 'Ahorro generado',
              value: 'S/ 389.50',
              valueColor: AppColors.green,
            ),
          ],
        ),
        ProgressBarCard(
          title: 'Gasto real vs. límite de presupuesto',
          currentLabel: 'S/ 1,410.50 usado',
          percentLabel: '78%',
          value: 0.78,
          color: AppColors.orange,
        ),
        SummaryCard(
          title: 'Resumen de cuentas',
          icon: Icons.account_balance_wallet_outlined,
          accentColor: AppColors.blue,
          items: [
            SummaryItem(
              label: 'BCP Ahorros',
              value: 'S/ 850.00',
              valueColor: AppColors.blue,
            ),
            SummaryItem(
              label: 'Yape',
              value: 'S/ 120.00',
              valueColor: AppColors.purple,
            ),
            SummaryItem(
              label: 'Cuenta USD',
              value: r'$200.00 / S/ 760.00',
              valueColor: AppColors.green,
            ),
            SummaryItem(
              label: 'Plazo Fijo',
              value: 'S/ 3,000.00 oculto',
              valueColor: AppColors.orange,
            ),
          ],
        ),
        SectionHeader(
          title: 'Últimos movimientos',
          subtitle: 'Movimientos reales guardados en SQLite',
        ),
        _LatestTransactions(),
      ],
    );
  }
}

class _LatestTransactions extends StatelessWidget {
  const _LatestTransactions();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TransactionChangeNotifier.version,
      builder: (context, _, __) {
        return FutureBuilder(
          future: TransactionService().getLatestTransactions(limit: 10),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudo cargar el historial',
                message:
                    'Intenta nuevamente después de registrar un movimiento.',
                icon: Icons.error_outline,
              );
            }
            return TransactionHistoryCard(items: snapshot.data ?? const []);
          },
        );
      },
    );
  }
}
