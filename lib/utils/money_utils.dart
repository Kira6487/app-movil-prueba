class MoneyUtils {
  const MoneyUtils._();

  static double? amountInBaseCurrency({
    required double amount,
    required String currency,
    required String baseCurrency,
    double? exchangeRate,
  }) {
    if (currency == baseCurrency) {
      return amount;
    }

    if (exchangeRate == null) {
      return null;
    }

    return amount * exchangeRate;
  }
}
