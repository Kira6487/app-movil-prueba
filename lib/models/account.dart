class Account {
  const Account({
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.visibleInBudget,
  });

  final String name;
  final String type;
  final String currency;
  final double balance;
  final bool visibleInBudget;
}
