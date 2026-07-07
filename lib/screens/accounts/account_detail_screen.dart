import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/transaction_history_item.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/cards/transaction_list_item.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../placeholders/action_placeholder_screen.dart';
import '../transactions/transaction_form_screen.dart';
import 'account_form_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TransactionChangeNotifier.version,
      builder: (context, _, __) {
        return FutureBuilder<AccountModel?>(
          future: AccountService().getAccountById(accountId),
          builder: (context, snapshot) {
            final account = snapshot.data;
            return AppScaffold(
              title: account?.name ?? 'Detalle de cuenta',
              actions: [
                if (account != null)
                  IconButton(
                    tooltip: 'Editar cuenta',
                    onPressed: () => _openAccountForm(context, account),
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError || account == null)
                  const EmptyState(
                    title: 'No se pudo cargar la cuenta',
                    message: 'Revisa la base local e intenta nuevamente.',
                    icon: Icons.error_outline,
                  )
                else ...[
                  _AccountSummary(account: account),
                  _AccountActionGrid(account: account),
                  const SectionHeader(
                    title: 'Historial de movimientos',
                    subtitle: 'Toca un movimiento para editarlo.',
                  ),
                  _AccountHistory(accountId: account.id!),
                ],
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _openAccountForm(
    BuildContext context,
    AccountModel account,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AccountFormScreen(initial: account),
      ),
    );
    TransactionChangeNotifier.notifyChanged();
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.color);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.16),
                child: Icon(iconForAccount(account.icon), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${accountTypeLabel(account.accountType)} - ${account.currency}',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              Text(
                formatAccountBalance(account),
                style: AppTextStyles.amount.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _InfoRow(label: 'Banco', value: 'No disponible en demo'),
          _InfoRow(label: 'Tipo', value: accountTypeLabel(account.accountType)),
          _InfoRow(label: 'Moneda', value: account.currency),
          _InfoRow(
            label: 'Saldo inicial',
            value: account.currency == 'USD'
                ? formatUsd(account.initialBalance)
                : formatSol(account.initialBalance),
          ),
          _InfoRow(
            label: 'Estado',
            value: account.isHiddenFromBudget
                ? 'Oculta del presupuesto'
                : 'Visible en presupuesto',
          ),
        ],
      ),
    );
  }
}

class _AccountActionGrid extends StatelessWidget {
  const _AccountActionGrid({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AppPrimaryButton(
          label: 'Agregar gasto',
          icon: Icons.remove_circle_outline,
          onPressed: () => _openTransaction(context, 'expense'),
        ),
        AppSecondaryButton(
          label: 'Agregar ingreso',
          icon: Icons.add_circle_outline,
          onPressed: () => _openTransaction(context, 'income'),
        ),
        AppSecondaryButton(
          label: 'Transferir',
          icon: Icons.swap_horiz,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActionPlaceholderScreen(
                title: 'Transferencia',
                description:
                    'Transferencia funcional pendiente para una fase posterior.',
                icon: Icons.swap_horiz,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
        AppSecondaryButton(
          label: 'Eliminar cuenta',
          icon: Icons.delete_outline,
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _openTransaction(BuildContext context, String type) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => TransactionFormScreen(
          type: type,
          initialAccount: account,
        ),
      ),
    );
    TransactionChangeNotifier.notifyChanged();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final movements = await AccountService().countAccountMovements(account.id!);
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          movements > 0
              ? 'Esta cuenta tiene $movements movimientos. Para proteger el historial no se borrara fisicamente.'
              : 'Esta accion eliminara la cuenta sin movimientos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(movements > 0 ? 'Entendido' : 'Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (movements > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se elimino: la cuenta tiene historial.'),
        ),
      );
      return;
    }

    await AccountService().deleteAccount(account.id!);
    TransactionChangeNotifier.notifyChanged();
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }
}

class _AccountHistory extends StatelessWidget {
  const _AccountHistory({required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionHistoryItem>>(
      future: TransactionService().getTransactionHistoryByAccount(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const EmptyState(
            title: 'No se pudo cargar el historial',
            message: 'Intenta nuevamente.',
            icon: Icons.error_outline,
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(
            title: 'Sin movimientos',
            message: 'Agrega un ingreso o gasto para verlo aqui.',
            icon: Icons.receipt_long_outlined,
          );
        }
        return AppCard(
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                TransactionListItem(
                  item: items[index],
                  onTap: () => _editTransaction(context, items[index]),
                  trailing: IconButton(
                    tooltip: 'Eliminar movimiento',
                    onPressed: () => _deleteTransaction(context, items[index]),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
                if (index < items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _editTransaction(
    BuildContext context,
    TransactionHistoryItem item,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => TransactionFormScreen(
          type: item.transaction.type,
          initialTransaction: item.transaction,
        ),
      ),
    );
    TransactionChangeNotifier.notifyChanged();
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    TransactionHistoryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content:
            const Text('Se revertira el impacto en el saldo de la cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TransactionService().deleteTransaction(item.transaction.id!);
    TransactionChangeNotifier.notifyChanged();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.muted)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String formatAccountBalance(AccountModel account) {
  if (account.currency == 'USD') return formatUsd(account.currentBalance);
  return formatSol(account.currentBalance);
}

String accountTypeLabel(String type) {
  return switch (type) {
    'ahorros' => 'Ahorros',
    'corriente' => 'Corriente',
    'sueldo' => 'Sueldo',
    'plazo_fijo' => 'Plazo fijo',
    'efectivo' => 'Efectivo',
    'billetera' => 'Billetera digital',
    _ => type,
  };
}

Color colorFromHex(String? value) {
  if (value == null || value.length != 7 || !value.startsWith('#')) {
    return AppColors.blue;
  }
  return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
}

IconData iconForAccount(String? value) {
  return switch (value) {
    'bank' => Icons.account_balance_outlined,
    'cash' => Icons.payments_outlined,
    'card' => Icons.credit_card,
    'savings' => Icons.savings_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };
}
