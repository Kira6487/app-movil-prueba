import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, this.label = 'Mayo 2025'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left,
              size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.cardTitle),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}
