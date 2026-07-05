import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cards/finance_card.dart';
import '../../widgets/common/app_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Cuentas',
      children: const [
        _AccountActions(),
        _AccountCard(
          name: 'BCP Ahorros',
          type: 'Cuenta bancaria',
          currency: 'SOL',
          balance: 'S/ 850.00',
          visibleInBudget: true,
          color: AppColors.blue,
        ),
        _AccountCard(
          name: 'Yape',
          type: 'Billetera digital',
          currency: 'SOL',
          balance: 'S/ 120.00',
          visibleInBudget: true,
          color: AppColors.purple,
        ),
        _AccountCard(
          name: 'Cuenta USD',
          type: 'Cuenta bancaria',
          currency: 'USD',
          balance: r'$200.00 / S/ 760.00',
          visibleInBudget: true,
          color: AppColors.green,
        ),
        _AccountCard(
          name: 'Plazo Fijo',
          type: 'Ahorro bloqueado',
          currency: 'SOL',
          balance: 'S/ 3,000.00',
          visibleInBudget: false,
          color: AppColors.orange,
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

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.16),
            child: Icon(Icons.account_balance_wallet_outlined, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$type · $currency', style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    visibleInBudget ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16,
                  ),
                  label: Text(visibleInBudget ? 'Visible en presupuesto' : 'Oculta del presupuesto'),
                ),
              ],
            ),
          ),
          Text(balance, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
