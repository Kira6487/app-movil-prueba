import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AddActionSheet extends StatelessWidget {
  const AddActionSheet({super.key});

  static const _actions = [
    _AddAction(
      icon: Icons.remove_circle_outline,
      title: 'Registrar gasto',
      description: 'Registra un gasto rapido',
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
      description: 'Registra un consumo con tarjeta de credito',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nueva accion',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final action = _actions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: AppColors.surfaceAlt,
                  leading: CircleAvatar(
                    backgroundColor: action.color.withOpacity(0.16),
                    child: Icon(action.icon, color: action.color),
                  ),
                  title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(action.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action.title} estara disponible pronto')),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
