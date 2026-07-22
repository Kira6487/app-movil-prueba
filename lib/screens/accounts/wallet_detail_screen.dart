import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/savings_goal_model.dart';
import '../../models/wallet_model.dart';
import '../../models/wallet_movement.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/savings_service.dart';
import '../../services/category_service.dart';
import '../../services/transfer_service.dart';
import '../../models/transfer_model.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import 'wallet_form_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({super.key, required this.walletId});
  final int walletId;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Future<_WalletDetailData> _future = _load();

  Future<_WalletDetailData> _load() async {
    final savings = SavingsService();
    final wallet = await savings.getWalletById(widget.walletId);
    if (wallet == null) throw StateError('Alcancía no encontrada.');
    final account = await AccountService().getAccountById(wallet.accountId);
    final history = await savings.getWalletHistory(widget.walletId);
    final goals = await savings.getAllSavingsGoals(activeOnly: false);
    final goal =
        goals.where((item) => item.id == wallet.savingsItemId).firstOrNull;
    final categories = await CategoryService()
        .getCategoriesByType('savings', activeOnly: false);
    final category = categories
        .where((item) => item.id == wallet.savingsCategoryId)
        .firstOrNull;
    final progress =
        goal?.id == null ? 0.0 : await savings.getGoalProgress(goal!.id!);
    return _WalletDetailData(
        wallet, account, history, goal, category?.name, progress);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalle de alcancía',
      children: [
        FutureBuilder<_WalletDetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data?.account == null) {
              return const EmptyState(
                title: 'No se pudo cargar la alcancía',
                message: 'Revisa la base local e intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }
            final data = snapshot.data!;
            final wallet = data.wallet;
            final amount = data.history.fold<double>(
                0,
                (total, movement) =>
                    total +
                    (movement.type == 'Depósito'
                        ? movement.amount
                        : -movement.amount));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.name, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 6),
                      Text('Cuenta padre: ${data.account!.name}',
                          style: AppTextStyles.muted),
                      Text('Moneda: ${wallet.currency}',
                          style: AppTextStyles.muted),
                      Text(
                          'Categoría de ahorro: ${data.categoryName ?? 'Sin configurar'}',
                          style: AppTextStyles.muted),
                      Text(
                          'Contrapartida: ${data.goal?.name ?? 'Sin configurar'}',
                          style: AppTextStyles.muted),
                      Text(
                          'Categoría de ahorro: ${wallet.savingsCategoryId ?? 'Sin configurar'}',
                          style: AppTextStyles.muted),
                      Text(
                          'Contrapartida: ${wallet.savingsItemId ?? 'Sin configurar'}',
                          style: AppTextStyles.muted),
                      const SizedBox(height: 14),
                      Text(
                          wallet.currency == 'USD'
                              ? formatUsd(amount)
                              : formatSol(amount),
                          style: AppTextStyles.amount),
                      if (data.goal != null)
                        Text(
                          'Objetivo: ${data.goal!.name} · Progreso: ${data.progress.toStringAsFixed(2)} / ${data.goal!.targetAmount.toStringAsFixed(2)} ${wallet.currency}',
                          style: AppTextStyles.muted,
                        ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppSecondaryButton(
                        label: 'Depositar',
                        icon: Icons.add,
                        onPressed: () => _move(wallet, deposit: true)),
                    AppSecondaryButton(
                        label: 'Retirar',
                        icon: Icons.remove,
                        onPressed: () => _move(wallet, deposit: false)),
                    AppSecondaryButton(
                        label: 'Transferir',
                        icon: Icons.swap_horiz,
                        onPressed: () => _transfer(wallet)),
                    AppSecondaryButton(
                        label: 'Editar',
                        icon: Icons.edit_outlined,
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => WalletFormScreen(
                                  account: data.account!, initial: wallet)));
                          _refresh();
                        }),
                    AppSecondaryButton(
                        label: 'Eliminar',
                        icon: Icons.delete_outline,
                        onPressed: () => _delete(wallet)),
                  ],
                ),
                const SectionHeader(
                    title: 'Historial de movimientos',
                    subtitle: 'Depósitos, retiros y transferencias contables.'),
                AppCard(
                  child: data.history.isEmpty
                      ? const EmptyState(
                          title: 'Sin movimientos',
                          message: 'Aún no hay movimientos en esta alcancía.',
                          icon: Icons.receipt_long_outlined)
                      : Column(children: [
                          for (final item in data.history)
                            _MovementTile(item: item)
                        ]),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _move(WalletModel wallet, {required bool deposit}) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deposit ? 'Depositar' : 'Retirar'),
        content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext,
                  double.tryParse(controller.text.replaceAll(',', '.'))),
              child: Text(deposit ? 'Depositar' : 'Retirar')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || amount == null || amount <= 0) return;
    final now = AppDateUtils.nowIso();
    await TransferService().insertTransfer(TransferModel(
      fromAccountId: wallet.accountId,
      toAccountId: wallet.accountId,
      fromWalletId: deposit ? null : wallet.id,
      toWalletId: deposit ? wallet.id : null,
      savingsItemId: wallet.savingsItemId,
      amountFrom: amount,
      currencyFrom: wallet.currency,
      amountTo: amount,
      currencyTo: wallet.currency,
      date: now,
      comment:
          deposit ? 'Depósito en ${wallet.name}' : 'Retiro de ${wallet.name}',
      createdAt: now,
    ));
    if (!mounted) return;
    TransactionChangeNotifier.notifyChanged();
    _refresh();
  }

  Future<void> _transfer(WalletModel wallet) async {
    final accounts = await AccountService().getAllAccounts();
    final targets = accounts
        .where((item) =>
            item.id != wallet.accountId && item.currency == wallet.currency)
        .toList();
    if (!mounted || targets.isEmpty) return;
    final target = await showDialog<AccountModel>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
              title: const Text('Cuenta destino'),
              children: [
                for (final account in targets)
                  SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialogContext, account),
                      child: Text(account.name))
              ],
            ));
    if (!mounted || target == null) return;
    final controller = TextEditingController();
    final amount = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Transferir'),
              content: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext,
                        double.tryParse(controller.text.replaceAll(',', '.'))),
                    child: const Text('Transferir'))
              ],
            ));
    controller.dispose();
    if (!mounted || amount == null || amount <= 0) return;
    final now = AppDateUtils.nowIso();
    await TransferService().insertTransfer(TransferModel(
        fromAccountId: wallet.accountId,
        toAccountId: target.id!,
        fromWalletId: wallet.id,
        amountFrom: amount,
        currencyFrom: wallet.currency,
        amountTo: amount,
        currencyTo: target.currency,
        savingsItemId: wallet.savingsItemId,
        date: now,
        comment: 'Transferencia desde ${wallet.name}',
        createdAt: now));
    if (mounted) {
      TransactionChangeNotifier.notifyChanged();
      _refresh();
    }
  }

  Future<void> _delete(WalletModel wallet) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Eliminar alcancía'),
                content: const Text(
                    'Solo se puede eliminar si su saldo es cero. Si tiene historial se desactivará.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Eliminar'))
                ]));
    if (!mounted || confirmed != true) return;
    try {
      await SavingsService().deleteOrDeactivateWallet(wallet.id!);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _WalletDetailData {
  const _WalletDetailData(this.wallet, this.account, this.history, this.goal,
      this.categoryName, this.progress);
  final WalletModel wallet;
  final AccountModel? account;
  final List<WalletMovement> history;
  final SavingsGoalModel? goal;
  final String? categoryName;
  final double progress;
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.item});
  final WalletMovement item;
  @override
  Widget build(BuildContext context) => ListTile(
      title: Text(item.type),
      subtitle: Text('${item.date} · ${item.comment}',
          maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
          '${item.type == 'Depósito' ? '+' : '-'} ${item.currency} ${item.amount.toStringAsFixed(2)}'));
}
