import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadii.lg);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: borderColor),
    );

    final content = Padding(
      padding: padding,
      child: child,
    );

    return Material(
      color: backgroundColor,
      shape: shape,
      elevation: 3,
      shadowColor: AppColors.blue.withValues(alpha: 0.10),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
