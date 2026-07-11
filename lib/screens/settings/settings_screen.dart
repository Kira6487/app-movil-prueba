import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/section_header.dart';
import 'category_management_screen.dart';
import 'quick_actions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Configuracion',
      children: [
        const SectionHeader(
          title: 'Preferencias',
          subtitle: 'Personaliza accesos y datos usados por Duna.',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceAlt,
                    child: Icon(Icons.bolt_outlined, color: AppColors.blue),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Botones rapidos'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: 'Configurar botones rapidos',
                icon: Icons.tune,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QuickActionsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surfaceAlt,
                    child:
                        Icon(Icons.category_outlined, color: AppColors.purple),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Categorías'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: 'Administrar categorías',
                icon: Icons.edit_note_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoryManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
