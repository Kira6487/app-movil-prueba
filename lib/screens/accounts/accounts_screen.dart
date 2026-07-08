import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/cards/account_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../transactions/transactions_screen.dart';
import '../transfers/transfer_form_screen.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Cuentas',
      children: [
        SectionHeader(
          title: 'Tus cuentas',
          subtitle: 'Gestiona tus movimientos de forma local',
        ),
        _AccountActions(),
        _AccountsList(),
      ],
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TransactionChangeNotifier.version,
      builder: (context, _, __) {
        return FutureBuilder<List<AccountModel>>(
          future: AccountService().getAllAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudieron cargar las cuentas',
                message: 'Revisa la base local o intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }

            final accounts = snapshot.data ?? const [];
            if (accounts.isEmpty) {
              return const EmptyState(
                title: 'Todavia no hay cuentas registradas',
                message: 'Crea una cuenta local para comenzar.',
                icon: Icons.account_balance_wallet_outlined,
              );
            }

            return Column(
              children: [
                for (final account in accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccountCard(
                      name: account.name,
                      type: accountTypeLabel(account.accountType),
                      currency: account.currency,
                      balance: formatAccountBalance(account),
                      visibleInBudget: !account.isHiddenFromBudget,
                      color: colorFromHex(account.color),
                      icon: iconForAccount(account.icon),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AccountDetailScreen(accountId: account.id!),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                label: 'Nueva cuenta',
                icon: Icons.add,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => const AccountFormScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSecondaryButton(
                label: 'Transferir',
                icon: Icons.swap_horiz,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => const TransferFormScreen(),
                    ),
                  );
                  TransactionChangeNotifier.notifyChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppSecondaryButton(
          label: 'Todas las transacciones',
          icon: Icons.receipt_long_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TransactionsScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
