import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/cards/calendar_event_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/month_selector.dart';
import '../../widgets/common/section_header.dart';
import '../placeholders/action_placeholder_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static const _events = [
    _CalendarEvent(Icons.restaurant, 'Menú', 'S/ 12.00', AppColors.red),
    _CalendarEvent(Icons.directions_bus, 'Pasaje', 'S/ 4.00', AppColors.red),
    _CalendarEvent(Icons.water_drop_outlined, 'Agua', 'S/ 45.00 pendiente',
        AppColors.orange),
    _CalendarEvent(Icons.credit_card, 'Fecha de corte BCP Visa', 'Recordatorio',
        AppColors.blue),
    _CalendarEvent(Icons.school_outlined, 'Universidad',
        'S/ 350.00 pago cercano', AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Calendario',
      children: [
        const MonthSelector(),
        const _CalendarFilters(),
        const _StaticCalendar(),
        SectionHeader(
          title: 'Día seleccionado',
          subtitle: '${_events.length} eventos demo para este día',
        ),
        for (final event in _events)
          CalendarEventCard(
            icon: event.icon,
            title: event.title,
            detail: event.detail,
            color: event.color,
          ),
        AppSecondaryButton(
          label: 'Agregar evento para este día',
          icon: Icons.add,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActionPlaceholderScreen(
                title: 'Agregar evento',
                description:
                    'El calendario persistente se implementará en una fase posterior.',
                icon: Icons.event_available_outlined,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarFilters extends StatelessWidget {
  const _CalendarFilters();

  static const filters = [
    'Todos',
    'Presupuestos',
    'Pagos',
    'Tarjetas',
    'Alertas'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: filter == 'Todos',
                onSelected: (_) {},
                label: Text(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaticCalendar extends StatelessWidget {
  const _StaticCalendar();

  @override
  Widget build(BuildContext context) {
    final days = List.generate(35, (index) => index < 4 ? '' : '${index - 3}');
    const highlighted = {
      5: AppColors.red,
      12: AppColors.orange,
      18: AppColors.blue,
      24: AppColors.purple,
    };

    return AppCard(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Weekday('L'),
              _Weekday('M'),
              _Weekday('M'),
              _Weekday('J'),
              _Weekday('V'),
              _Weekday('S'),
              _Weekday('D'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final color = highlighted[int.tryParse(day) ?? 0];
              final isSelected = day == '15';
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: color == null ? null : Border.all(color: color),
                ),
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(child: Text(label, style: AppTextStyles.label)),
    );
  }
}

class _CalendarEvent {
  const _CalendarEvent(this.icon, this.title, this.detail, this.color);

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}
