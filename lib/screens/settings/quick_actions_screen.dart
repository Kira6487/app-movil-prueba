import 'package:flutter/material.dart';

import '../../models/quick_action_model.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/quick_action_service.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/color_palette_field.dart';
import 'quick_action_form_screen.dart';

class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Botones rapidos',
      children: [
        AppPrimaryButton(
          label: 'Nuevo boton rapido',
          icon: Icons.add,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<bool>(
              builder: (_) => const QuickActionFormScreen(),
            ),
          ),
        ),
        const SectionHeader(
          title: 'Configurados',
          subtitle: 'Estos accesos aparecen en Registrar gasto.',
        ),
        ValueListenableBuilder<int>(
          valueListenable: TransactionChangeNotifier.version,
          builder: (context, _, __) {
            return FutureBuilder<List<QuickActionModel>>(
              future:
                  QuickActionService().getAllQuickActions(activeOnly: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    title: 'No se pudieron cargar botones',
                    message: 'Intenta nuevamente.',
                    icon: Icons.error_outline,
                  );
                }
                final actions = snapshot.data ?? const [];
                if (actions.isEmpty) {
                  return const EmptyState(
                    title: 'Sin botones rapidos',
                    message:
                        'Crea tu primer acceso para registrar gastos mas rapido.',
                    icon: Icons.bolt_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final action in actions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuickActionTile(action: action),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final QuickActionModel action;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(action.color);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => QuickActionFormScreen(initial: action),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(iconDataForId(action.icon), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  '${action.currency == 'USD' ? formatUsd(action.amount) : formatSol(action.amount)}'
                  '${action.isActive ? '' : ' - inactivo'}',
                  style: AppTextStyles.muted,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar boton rapido'),
        content: Text('Se quitara "${action.name}" del panel de gasto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await QuickActionService().deleteQuickAction(action.id!);
    TransactionChangeNotifier.notifyChanged();
  }
}
