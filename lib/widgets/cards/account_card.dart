import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.visibleInBudget,
    required this.color,
    this.icon = Icons.account_balance_wallet_outlined,
    this.onTap,
  });

  final String name;
  final String type;
  final String currency;
  final String balance;
  final bool visibleInBudget;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text('$type - $currency', style: AppTextStyles.muted),
                const SizedBox(height: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                  backgroundColor: AppColors.surfaceAlt,
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
          const SizedBox(width: 12),
          Text(
            balance,
            textAlign: TextAlign.end,
            style: AppTextStyles.amount.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
