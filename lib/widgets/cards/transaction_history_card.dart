import 'package:flutter/material.dart';

import '../../models/transaction_history_item.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';
import '../common/empty_state.dart';
import 'transaction_list_item.dart';

class TransactionHistoryCard extends StatelessWidget {
  const TransactionHistoryCard({
    super.key,
    required this.items,
    this.title = 'Últimos movimientos',
  });

  final List<TransactionHistoryItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        title: 'Sin movimientos todavía',
        message: 'Registra un ingreso o gasto para verlo en el historial.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          for (var index = 0; index < items.length; index++) ...[
            TransactionListItem(item: items[index]),
            if (index < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
