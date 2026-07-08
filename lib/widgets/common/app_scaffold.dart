import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundAlt, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 42,
              left: -80,
              right: -80,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.cyanSoft.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(140),
                    bottomRight: Radius.circular(220),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    titleSpacing: AppSpacing.lg,
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.display),
                        if (subtitle != null)
                          Text(subtitle!, style: AppTextStyles.muted),
                      ],
                    ),
                    actions: actions,
                  ),
                  SliverPadding(
                    padding: AppSpacing.screen,
                    sliver: SliverList.separated(
                      itemCount: children.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, index) => children[index],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
