class ExchangeRateService {
  const ExchangeRateService();

  double usdToSol(double amount, {double exchangeRate = 3.80}) {
    return amount * exchangeRate;
  }
}
