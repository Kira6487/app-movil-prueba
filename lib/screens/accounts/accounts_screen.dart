import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/cards/account_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../placeholders/action_placeholder_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cuentas',
      children: [
        const SectionHeader(
          title: 'Tus cuentas',
          subtitle: 'Saldos locales cargados desde SQLite',
        ),
        const _AccountActions(),
        FutureBuilder<List<AccountModel>>(
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
                title: 'Todavía no hay cuentas registradas',
                message: 'La pantalla está lista para mostrar cuentas locales.',
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
                      type: _accountTypeLabel(account.accountType),
                      currency: account.currency,
                      balance: _formatBalance(account),
                      visibleInBudget: !account.isHiddenFromBudget,
                      color: _colorFromHex(account.color),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppPrimaryButton(
            label: 'Nueva cuenta',
            icon: Icons.add,
            onPressed: () => _openPlaceholder(
              context,
              title: 'Nueva cuenta',
              description:
                  'El formulario real de cuentas se implementará en una fase posterior.',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSecondaryButton(
            label: 'Transferir',
            icon: Icons.swap_horiz,
            onPressed: () => _openPlaceholder(
              context,
              title: 'Transferencia entre cuentas',
              description:
                  'La transferencia funcional se implementará más adelante.',
              icon: Icons.swap_horiz,
              color: AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionPlaceholderScreen(
          title: title,
          description: description,
          icon: icon,
          color: color,
        ),
      ),
    );
  }
}

String _formatBalance(AccountModel account) {
  if (account.currency == 'USD') {
    return formatUsd(account.currentBalance);
  }
  return formatSol(account.currentBalance);
}

String _accountTypeLabel(String type) {
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

Color _colorFromHex(String? value) {
  if (value == null || value.length != 7 || !value.startsWith('#')) {
    return AppColors.blue;
  }

  return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
}
