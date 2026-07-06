import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(detail, style: AppTextStyles.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
