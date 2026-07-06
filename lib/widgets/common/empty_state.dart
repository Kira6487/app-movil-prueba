import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.blue.withValues(alpha: 0.16),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: AppTextStyles.muted, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
