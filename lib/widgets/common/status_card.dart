import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String title;
  final String status;
  final String description;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(status, style: AppTextStyles.title.copyWith(color: color)),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.muted),
        ],
      ),
    );
  }
}

class SummaryItem {
  const SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.items,
    this.icon,
    this.accentColor = AppColors.blue,
  });

  final String title;
  final List<SummaryItem> items;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                CircleAvatar(
                  backgroundColor: accentColor.withValues(alpha: 0.16),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            _SummaryRow(item: items[index]),
            if (index == 3 && items.length > 4) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item});

  final SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(item.label, style: AppTextStyles.muted)),
          Text(
            item.value,
            style: AppTextStyles.body.copyWith(
              color: item.valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressBarCard extends StatelessWidget {
  const ProgressBarCard({
    super.key,
    required this.title,
    required this.currentLabel,
    required this.percentLabel,
    required this.value,
    this.color = AppColors.orange,
  });

  final String title;
  final String currentLabel;
  final String percentLabel;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: value,
              color: color,
              backgroundColor: AppColors.surfaceAlt,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentLabel, style: AppTextStyles.muted),
              Text(
                percentLabel,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
