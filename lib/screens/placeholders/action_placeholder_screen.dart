import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';

class ActionPlaceholderScreen extends StatelessWidget {
  const ActionPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    this.color = AppColors.blue,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.16),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 18),
              Text(title, style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(description, style: AppTextStyles.muted),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Volver',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
