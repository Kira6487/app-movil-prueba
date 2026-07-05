class AppDateUtils {
  const AppDateUtils._();

  static String nowIso() => DateTime.now().toIso8601String();

  static String dateOnlyIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}
