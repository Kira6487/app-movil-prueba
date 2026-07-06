import 'package:flutter/material.dart';

import '../../screens/placeholders/action_placeholder_screen.dart';
import '../../screens/transactions/transaction_form_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons/quick_action_button.dart';
import '../../widgets/navigation/app_bottom_sheet.dart';

class AddActionSheet extends StatelessWidget {
  const AddActionSheet({super.key});

  static const _actions = [
    _AddAction(
      type: _AddActionType.expense,
      icon: Icons.remove_circle_outline,
      title: 'Registrar gasto',
      description: 'Registra un gasto rápido',
      color: AppColors.red,
    ),
    _AddAction(
      type: _AddActionType.income,
      icon: Icons.add_circle_outline,
      title: 'Registrar ingreso',
      description: 'Registra un ingreso',
      color: AppColors.green,
    ),
    _AddAction(
      type: _AddActionType.placeholder,
      icon: Icons.swap_horiz,
      title: 'Transferencia entre cuentas',
      description: 'Transfiere dinero entre tus cuentas',
      color: AppColors.blue,
    ),
    _AddAction(
      type: _AddActionType.placeholder,
      icon: Icons.credit_card,
      title: 'Consumo con tarjeta',
      description: 'Registra un consumo con tarjeta de crédito',
      color: AppColors.orange,
    ),
    _AddAction(
      type: _AddActionType.placeholder,
      icon: Icons.event_available_outlined,
      title: 'Pago programado',
      description: 'Agrega o registra un pago de servicio',
      color: AppColors.purple,
    ),
    _AddAction(
      type: _AddActionType.placeholder,
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
      subtitle: 'Selecciona el movimiento que quieres registrar',
      children: [
        for (final action in _actions)
          QuickActionButton(
            icon: action.icon,
            title: action.title,
            description: action.description,
            color: action.color,
            onTap: () => _openAction(context, action),
          ),
      ],
    );
  }

  void _openAction(BuildContext context, _AddAction action) {
    final navigator = Navigator.of(context);
    navigator.pop();

    final route = switch (action.type) {
      _AddActionType.expense => MaterialPageRoute<void>(
          builder: (_) => const TransactionFormScreen(type: 'expense'),
        ),
      _AddActionType.income => MaterialPageRoute<void>(
          builder: (_) => const TransactionFormScreen(type: 'income'),
        ),
      _AddActionType.placeholder => MaterialPageRoute<void>(
          builder: (_) => ActionPlaceholderScreen(
            title: action.title,
            description:
                '${action.description}. Este flujo funcional se implementará en una fase posterior.',
            icon: action.icon,
            color: action.color,
          ),
        ),
    };

    navigator.push(route);
  }
}

enum _AddActionType { expense, income, placeholder }

class _AddAction {
  const _AddAction({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final _AddActionType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
