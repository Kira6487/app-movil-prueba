import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../placeholders/action_placeholder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ActionPlaceholderScreen(
      title: 'Configuración',
      description:
          'Preferencias generales de la app. Esta pantalla queda preparada para próximas etapas.',
      icon: Icons.tune,
      color: AppColors.blue,
    );
  }
}
