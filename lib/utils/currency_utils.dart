String normalizeCurrencyCode(String value) {
  final code = value.trim().toUpperCase();
  return code == 'PEN' ? 'SOL' : code;
}

bool currenciesMatch(String left, String right) =>
    normalizeCurrencyCode(left) == normalizeCurrencyCode(right);
