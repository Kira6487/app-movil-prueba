import 'package:flutter/material.dart';

import '../../models/transaction_history_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.item,
  });

  final TransactionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final transaction = item.transaction;
    final isIncome = transaction.type == 'income';
    final color = isIncome ? AppColors.green : AppColors.red;
    final sign = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.categoryName, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  '${item.accountName} · ${_formatDate(transaction.date)}',
                  style: AppTextStyles.muted,
                ),
                if (transaction.comment != null &&
                    transaction.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(transaction.comment!, style: AppTextStyles.muted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sign${_formatAmount(transaction.currency, transaction.amount)}',
            style: AppTextStyles.amount.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatAmount(String currency, double amount) {
    if (currency == 'USD') {
      return formatUsd(amount);
    }
    return formatSol(amount);
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
