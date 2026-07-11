import '../models/budget_rule_model.dart';
import '../models/budget_summary_model.dart';

class BudgetRecurrenceType {
  const BudgetRecurrenceType._();

  static const onceThisMonth = 'once_this_month';
  static const monthly = 'monthly';
  static const weeklyOnce = 'weekly_once';
  static const customWeekdays = 'custom_weekdays';

  static String weekday(int weekday) => 'weekday_$weekday';

  static const values = [
    onceThisMonth,
    monthly,
    weeklyOnce,
    'weekday_1',
    'weekday_2',
    'weekday_3',
    'weekday_4',
    'weekday_5',
    'weekday_6',
    'weekday_7',
    customWeekdays,
  ];

  static String label(String value) {
    return switch (value) {
      onceThisMonth => 'Solo este mes',
      monthly => 'Repetir mensualmente',
      weeklyOnce => 'Repetir una vez a la semana',
      'weekday_1' => 'Todos los lunes',
      'weekday_2' => 'Todos los martes',
      'weekday_3' => 'Todos los miercoles',
      'weekday_4' => 'Todos los jueves',
      'weekday_5' => 'Todos los viernes',
      'weekday_6' => 'Todos los sabados',
      'weekday_7' => 'Todos los domingos',
      customWeekdays => 'Dias personalizados',
      _ => value,
    };
  }
}

class BudgetCalculator {
  const BudgetCalculator._();

  static double monthlyAmount(BudgetRuleModel rule, int year, int month) {
    return occurrencesForMonth(rule, year, month).length *
        rule.unitsPerDay *
        rule.amount;
  }

  static double accumulatedAmount(
    BudgetRuleModel rule,
    int year,
    int month,
    DateTime until,
  ) {
    return occurrencesForMonth(rule, year, month, until: until).length *
        rule.unitsPerDay *
        rule.amount;
  }

  static String formula(BudgetRuleModel rule) {
    if (rule.budgetType != BudgetType.recurrence) {
      return BudgetRecurrenceType.label(rule.recurrenceType);
    }
    final days = parseWeekdays(rule.selectedWeekdays)
        .map((day) =>
            const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][day - 1])
        .join(', ');
    final units = rule.unitsPerDay == rule.unitsPerDay.roundToDouble()
        ? rule.unitsPerDay.toStringAsFixed(0)
        : rule.unitsPerDay.toStringAsFixed(1);
    final amount = rule.amount.toStringAsFixed(2);
    return '${days.isEmpty ? BudgetRecurrenceType.label(rule.recurrenceType) : days} · '
        '$units por día · ${rule.currency == 'USD' ? r'$' : 'S/'} $amount';
  }

  static List<DateTime> occurrencesForDate(
    List<BudgetRuleModel> rules,
    DateTime date,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final occurrences = <DateTime>[];
    for (final rule in rules) {
      final days = occurrencesForMonth(rule, day.year, day.month, until: day);
      if (days.any((item) => _isSameDay(item, day))) {
        occurrences.add(day);
      }
    }
    return occurrences;
  }

  static List<DateTime> occurrencesForMonth(
    BudgetRuleModel rule,
    int year,
    int month, {
    DateTime? until,
  }) {
    if (!rule.isActive) return const [];

    final monthStart = DateTime(year, month);
    final monthEnd = DateTime(year, month + 1, 0);
    final effectiveEnd = until == null
        ? monthEnd
        : _minDate(monthEnd, DateTime(until.year, until.month, until.day));
    final start = _parseDate(rule.startDate) ?? monthStart;
    final end = _parseDate(rule.endDate);
    final rangeStart =
        _maxDate(monthStart, DateTime(start.year, start.month, start.day));
    final rangeEnd = end == null
        ? effectiveEnd
        : _minDate(effectiveEnd, DateTime(end.year, end.month, end.day));

    if (rangeEnd.isBefore(rangeStart)) return const [];

    return switch (rule.recurrenceType) {
      BudgetRecurrenceType.onceThisMonth =>
        _onceThisMonth(rule, year, month, rangeStart, rangeEnd),
      BudgetRecurrenceType.monthly => [rangeStart],
      BudgetRecurrenceType.weeklyOnce =>
        _daysByWeekday(rangeStart, rangeEnd, start.weekday),
      BudgetRecurrenceType.customWeekdays =>
        _customWeekdays(rule, rangeStart, rangeEnd),
      _ => _weekdayRule(rule, rangeStart, rangeEnd),
    };
  }

  static BudgetStatus statusFor(
      {required double spent, required double budget}) {
    return BudgetStatus.from(spent: spent, budget: budget);
  }

  static List<int> parseWeekdays(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet()
        .toList()
      ..sort();
  }

  static String encodeWeekdays(Iterable<int> weekdays) {
    final unique = weekdays
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet()
        .toList()
      ..sort();
    return unique.join(',');
  }

  static List<DateTime> _onceThisMonth(
    BudgetRuleModel rule,
    int year,
    int month,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final date = _parseDate(rule.startDate) ?? DateTime(year, month);
    final day = DateTime(date.year, date.month, date.day);
    if (day.year != year || day.month != month) return const [];
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) return const [];
    return [day];
  }

  static List<DateTime> _weekdayRule(
    BudgetRuleModel rule,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    const prefix = 'weekday_';
    if (!rule.recurrenceType.startsWith(prefix)) return const [];
    final weekday = int.tryParse(rule.recurrenceType.substring(prefix.length));
    if (weekday == null) return const [];
    return _daysByWeekday(rangeStart, rangeEnd, weekday);
  }

  static List<DateTime> _customWeekdays(
    BudgetRuleModel rule,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final weekdays = parseWeekdays(rule.selectedWeekdays);
    final days = <DateTime>[];
    for (final weekday in weekdays) {
      days.addAll(_daysByWeekday(rangeStart, rangeEnd, weekday));
    }
    days.sort();
    return days;
  }

  static List<DateTime> _daysByWeekday(
    DateTime start,
    DateTime end,
    int weekday,
  ) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) return const [];
    final days = <DateTime>[];
    var day = start;
    while (day.weekday != weekday && !day.isAfter(end)) {
      day = day.add(const Duration(days: 1));
    }
    while (!day.isAfter(end)) {
      days.add(day);
      day = day.add(const Duration(days: 7));
    }
    return days;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
  static DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}
