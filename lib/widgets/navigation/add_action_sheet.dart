import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/buttons/quick_action_button.dart';
import '../../widgets/navigation/app_bottom_sheet.dart';
import '../../screens/placeholders/action_placeholder_screen.dart';

class AddActionSheet extends StatelessWidget {
  const AddActionSheet({super.key});

  static const _actions = [
    _AddAction(
      icon: Icons.remove_circle_outline,
      title: 'Registrar gasto',
      description: 'Registra un gasto rápido',
      color: AppColors.red,
    ),
    _AddAction(
      icon: Icons.add_circle_outline,
      title: 'Registrar ingreso',
      description: 'Registra un ingreso',
      color: AppColors.green,
    ),
    _AddAction(
      icon: Icons.swap_horiz,
      title: 'Transferencia entre cuentas',
      description: 'Transfiere dinero entre tus cuentas',
      color: AppColors.blue,
    ),
    _AddAction(
      icon: Icons.credit_card,
      title: 'Consumo con tarjeta',
      description: 'Registra un consumo con tarjeta de crédito',
      color: AppColors.orange,
    ),
    _AddAction(
      icon: Icons.event_available_outlined,
      title: 'Pago programado',
      description: 'Agrega o registra un pago de servicio',
      color: AppColors.purple,
    ),
    _AddAction(
      icon: Icons.savings_outlined,
      title: 'Aporte a ahorro / meta',
      description: 'Aporta a tus metas de ahorro',
      color: AppColors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Nueva acción',
      subtitle: 'Selecciona el flujo que quieres preparar',
      children: [
        for (final action in _actions)
          QuickActionButton(
            icon: action.icon,
            title: action.title,
            description: action.description,
            color: action.color,
            onTap: () => _openPlaceholder(context, action),
          ),
      ],
    );
  }

  void _openPlaceholder(BuildContext context, _AddAction action) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ActionPlaceholderScreen(
          title: action.title,
          description:
              '${action.description}. El formulario real se implementará en una fase posterior.',
          icon: action.icon,
          color: action.color,
        ),
      ),
    );
  }
}

class _AddAction {
  const _AddAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
