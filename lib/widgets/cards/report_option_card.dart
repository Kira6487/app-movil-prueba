import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class ReportOptionCard extends StatelessWidget {
  const ReportOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(title, style: AppTextStyles.cardTitle),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(description!, style: AppTextStyles.muted, maxLines: 2),
          ],
          const SizedBox(height: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
