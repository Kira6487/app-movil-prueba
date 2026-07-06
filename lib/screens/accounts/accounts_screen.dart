import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/cards/finance_card.dart';
import '../../widgets/common/app_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Cuentas',
      children: [
        const _AccountActions(),
        FutureBuilder<List<AccountModel>>(
          future: AccountService().getAllAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const FinanceCard(
                child: Text('No se pudieron cargar las cuentas locales.'),
              );
            }

            final accounts = snapshot.data ?? const [];
            if (accounts.isEmpty) {
              return const FinanceCard(
                child: Text('Todavia no hay cuentas registradas.'),
              );
            }

            return Column(
              children: [
                for (final account in accounts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AccountCard.fromModel(account),
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
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Nueva cuenta'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Transferir'),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.visibleInBudget,
    required this.color,
  });

  final String name;
  final String type;
  final String currency;
  final String balance;
  final bool visibleInBudget;
  final Color color;

  factory _AccountCard.fromModel(AccountModel account) {
    return _AccountCard(
      name: account.name,
      type: _accountTypeLabel(account.accountType),
      currency: account.currency,
      balance: _formatBalance(account),
      visibleInBudget: !account.isHiddenFromBudget,
      color: _colorFromHex(account.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(Icons.account_balance_wallet_outlined, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type · $currency',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    visibleInBudget
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                  ),
                  label: Text(
                    visibleInBudget
                        ? 'Visible en presupuesto'
                        : 'Oculta del presupuesto',
                  ),
                ),
              ],
            ),
          ),
          Text(
            balance,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
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
