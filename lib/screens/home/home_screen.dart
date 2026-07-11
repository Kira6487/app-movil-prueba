import 'package:flutter/material.dart';

import '../../models/budget_summary_model.dart';
import '../../models/account_model.dart';
import '../../providers/budget_change_notifier.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/budget_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/cards/progress_bar_card.dart';
import '../../widgets/cards/status_card.dart';
import '../../widgets/cards/summary_card.dart';
import '../../widgets/cards/transaction_history_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
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
            const SnackBar(content: Text('No hay notificaciones por revisar')),
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
        _BudgetSnapshot(),
        SectionHeader(
          title: 'Resumen de cuentas',
          subtitle: 'Saldos reales guardados en SQLite',
        ),
        _AccountsSnapshot(),
        SectionHeader(
          title: 'Últimos movimientos',
          subtitle: 'Movimientos reales guardados en SQLite',
        ),
        _LatestTransactions(),
      ],
    );
  }
}

class _BudgetSnapshot extends StatelessWidget {
  const _BudgetSnapshot();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: BudgetChangeNotifier.version,
      builder: (context, _, __) {
        final now = DateTime.now();
        return FutureBuilder<BudgetOverview>(
          future: BudgetService().getOverview(year: now.year, month: now.month),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudo cargar el presupuesto',
                message: 'Revisa la base local e intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }
            final overview = snapshot.data!;
            if (overview.rulesCount == 0) {
              return const EmptyState(
                title: 'Sin presupuesto para este mes',
                message: 'Abre Presupuestos para crear tu primer límite.',
                icon: Icons.track_changes_outlined,
              );
            }
            final status = overview.monthlyStatus;
            final color = _statusColor(status);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Estado del presupuesto',
                  subtitle: 'Cálculo real del mes actual',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatusCard(
                        title: 'Estado mensual',
                        status: status.label,
                        description:
                            '${(overview.monthUsagePercent * 100).toStringAsFixed(0)}% utilizado',
                        color: color,
                        icon: status == BudgetStatus.exceeded
                            ? Icons.error_outline
                            : Icons.track_changes_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBarCard(
                  title: 'Gasto real vs. límite de presupuesto',
                  currentLabel: '${formatSol(overview.monthSpent)} usado',
                  percentLabel:
                      '${(overview.monthUsagePercent * 100).toStringAsFixed(0)}%',
                  value: overview.monthUsagePercent.clamp(0.0, 1.0),
                  color: color,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AccountsSnapshot extends StatelessWidget {
  const _AccountsSnapshot();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TransactionChangeNotifier.version,
      builder: (context, _, __) => FutureBuilder<List<AccountModel>>(
        future: AccountService().getAllAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data ?? const [];
          if (accounts.isEmpty) {
            return const EmptyState(
              title: 'Sin cuentas',
              message: 'Crea una cuenta para ver su saldo aquí.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          return SummaryCard(
            title: 'Saldos actuales',
            icon: Icons.account_balance_wallet_outlined,
            accentColor: AppColors.blue,
            items: [
              for (final account in accounts)
                SummaryItem(
                  label: account.name,
                  value: account.currency == 'USD'
                      ? formatUsd(account.currentBalance)
                      : formatSol(account.currentBalance),
                  valueColor: account.isHiddenFromBudget
                      ? AppColors.textMuted
                      : AppColors.blue,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LatestTransactions extends StatelessWidget {
  const _LatestTransactions();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TransactionChangeNotifier.version,
      builder: (context, _, __) => FutureBuilder(
        future: TransactionService().getLatestTransactions(limit: 10),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const EmptyState(
              title: 'No se pudo cargar el historial',
              message: 'Intenta nuevamente después de registrar un movimiento.',
              icon: Icons.error_outline,
            );
          }
          return TransactionHistoryCard(items: snapshot.data ?? const []);
        },
      ),
    );
  }
}

Color _statusColor(BudgetStatus status) => switch (status) {
      BudgetStatus.warning => AppColors.orange,
      BudgetStatus.exceeded => AppColors.red,
      BudgetStatus.good => AppColors.green,
      BudgetStatus.empty => AppColors.blue,
    };
