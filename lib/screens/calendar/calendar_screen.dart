import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cards/finance_card.dart';
import '../../widgets/common/app_screen.dart';
import '../../widgets/common/month_selector.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Calendario',
      children: const [
        MonthSelector(),
        _CalendarFilters(),
        _StaticCalendar(),
        _SelectedDayList(),
      ],
    );
  }
}

class _CalendarFilters extends StatelessWidget {
  const _CalendarFilters();

  static const filters = ['Todos', 'Presupuestos', 'Pagos', 'Tarjetas', 'Alertas'];

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
                selectedColor: AppColors.blue.withValues(alpha: 0.22),
                checkmarkColor: AppColors.blue,
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
    const highlighted = {5: AppColors.red, 12: AppColors.orange, 18: AppColors.blue, 24: AppColors.purple};

    return FinanceCard(
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
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
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
      child: Center(
        child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SelectedDayList extends StatelessWidget {
  const _SelectedDayList();

  static const items = [
    _CalendarItem(Icons.restaurant, 'Menu', 'S/ 12.00', AppColors.red),
    _CalendarItem(Icons.directions_bus, 'Pasaje', 'S/ 4.00', AppColors.red),
    _CalendarItem(Icons.water_drop_outlined, 'Agua', 'S/ 45.00 pendiente', AppColors.orange),
    _CalendarItem(Icons.credit_card, 'Fecha de corte BCP Visa', 'Recordatorio', AppColors.blue),
    _CalendarItem(Icons.school_outlined, 'Universidad', 'S/ 350.00 pago cercano', AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dia seleccionado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: item.color.withValues(alpha: 0.16),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(item.title),
              subtitle: Text(item.detail),
            ),
        ],
      ),
    );
  }
}

class _CalendarItem {
  const _CalendarItem(this.icon, this.title, this.detail, this.color);

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}
