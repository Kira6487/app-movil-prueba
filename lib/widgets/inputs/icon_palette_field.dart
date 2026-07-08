import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../common/app_card.dart';

class IconPaletteField extends StatelessWidget {
  const IconPaletteField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.color = AppColors.blue,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final choice in appIconChoices)
                _IconOption(
                  choice: choice,
                  selected: choice.id == value,
                  color: color,
                  onTap: () => onChanged(choice.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.choice,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final AppIconChoice choice;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(choice.icon,
                color: selected ? color : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              choice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
