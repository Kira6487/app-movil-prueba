import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/transaction_history_item.dart';
import '../../models/transfer_model.dart';
import '../../models/wallet_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/transaction_service.dart';
import '../../services/savings_service.dart';
import '../../services/transfer_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/cards/transaction_list_item.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../transactions/transaction_form_screen.dart';
import '../transfers/transfer_form_screen.dart';
import 'account_form_screen.dart';
import 'wallet_detail_screen.dart';
import 'wallet_form_screen.dart';

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
                  _WalletSection(account: account),
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

class _WalletSection extends StatefulWidget {
  const _WalletSection({required this.account});

  final AccountModel account;

  @override
  State<_WalletSection> createState() => _WalletSectionState();
}

class _WalletSectionState extends State<_WalletSection> {
  late Future<List<WalletModel>> _future = _load();

  Future<List<WalletModel>> _load() =>
      SavingsService().getWalletsByAccount(widget.account.id!);

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Monederos y alcancías',
          subtitle: 'Subcuentas separadas del saldo disponible.',
          trailing: TextButton.icon(
            onPressed: _createNew,
            icon: const Icon(Icons.add),
            label: const Text('Nueva alcancía',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        FutureBuilder<List<WalletModel>>(
          future: _future,
          builder: (context, snapshot) {
            final wallets = snapshot.data ?? const [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (wallets.isEmpty) {
              return const EmptyState(
                title: 'Sin alcancías',
                message: 'Crea una para separar dinero de esta cuenta.',
                icon: Icons.savings_outlined,
              );
            }
            return AppCard(
              child: Column(
                children: [
                  for (final wallet in wallets)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.savings_outlined),
                      title: Text(wallet.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          wallet.type == 'wallet' ? 'Monedero' : 'Alcancía'),
                      trailing: Text(widget.account.currency == 'USD'
                          ? formatUsd(wallet.amount)
                          : formatSol(wallet.amount)),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              WalletDetailScreen(walletId: wallet.id!),
                        ));
                        if (mounted) _refresh();
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Legacy dialog kept for data compatibility; new alcancías use WalletFormScreen.
  // ignore: unused_element
  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva alcancía'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final now = AppDateUtils.nowIso();
    await SavingsService().insertWallet(WalletModel(
      name: name,
      accountId: widget.account.id!,
      currency: widget.account.currency,
      createdAt: now,
      updatedAt: now,
    ));
    _refresh();
  }

  Future<void> _createNew() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WalletFormScreen(account: widget.account),
    ));
    if (mounted) _refresh();
  }

  // ignore: unused_element
  Future<void> _actions(WalletModel wallet) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Depositar'),
              onTap: () => Navigator.pop(context, 'deposit')),
          ListTile(
              leading: const Icon(Icons.remove),
              title: const Text('Retirar'),
              onTap: () => Navigator.pop(context, 'withdraw')),
          ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Eliminar'),
              onTap: () => Navigator.pop(context, 'delete')),
        ]),
      ),
    );
    if (action == 'delete') {
      try {
        await SavingsService().deleteOrDeactivateWallet(wallet.id!);
        _refresh();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    } else if (action != null) {
      await _move(wallet, deposit: action == 'deposit');
    }
  }

  Future<void> _move(WalletModel wallet, {required bool deposit}) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deposit ? 'Depositar' : 'Retirar'),
        content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context,
                  double.tryParse(controller.text.replaceAll(',', '.'))),
              child: Text(deposit ? 'Depositar' : 'Retirar')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || amount == null || amount <= 0) return;
    final now = AppDateUtils.nowIso();
    await TransferService().insertTransfer(TransferModel(
      fromAccountId: widget.account.id!,
      toAccountId: widget.account.id!,
      fromWalletId: deposit ? null : wallet.id,
      toWalletId: deposit ? wallet.id : null,
      savingsItemId: wallet.savingsItemId,
      amountFrom: amount,
      currencyFrom: widget.account.currency,
      amountTo: amount,
      currencyTo: widget.account.currency,
      date: now,
      comment:
          deposit ? 'Depósito en ${wallet.name}' : 'Retiro de ${wallet.name}',
      createdAt: now,
    ));
    TransactionChangeNotifier.notifyChanged();
    _refresh();
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
            MaterialPageRoute<bool>(
              builder: (_) => TransferFormScreen(initialFromAccount: account),
            ),
          ),
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
          lockAccount: true,
        ),
      ),
    );
    TransactionChangeNotifier.notifyChanged();
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
    'billetera' => 'Cuenta digital',
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
  return iconDataForId(value);
}
