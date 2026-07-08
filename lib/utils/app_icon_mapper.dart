import 'package:flutter/material.dart';

class AppIconChoice {
  const AppIconChoice({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const appIconChoices = [
  AppIconChoice(
      id: 'wallet',
      label: 'Cuenta',
      icon: Icons.account_balance_wallet_outlined),
  AppIconChoice(
      id: 'bank', label: 'Banco', icon: Icons.account_balance_outlined),
  AppIconChoice(id: 'cash', label: 'Efectivo', icon: Icons.payments_outlined),
  AppIconChoice(id: 'card', label: 'Tarjeta', icon: Icons.credit_card),
  AppIconChoice(id: 'savings', label: 'Ahorro', icon: Icons.savings_outlined),
  AppIconChoice(id: 'piggy', label: 'Meta', icon: Icons.savings),
  AppIconChoice(id: 'home', label: 'Casa', icon: Icons.home_outlined),
  AppIconChoice(id: 'travel', label: 'Viaje', icon: Icons.flight_takeoff),
  AppIconChoice(id: 'food', label: 'Comida', icon: Icons.restaurant),
  AppIconChoice(
      id: 'transport', label: 'Transporte', icon: Icons.directions_bus),
  AppIconChoice(id: 'coffee', label: 'Cafe', icon: Icons.local_cafe),
  AppIconChoice(id: 'taxi', label: 'Taxi', icon: Icons.local_taxi),
];

IconData iconDataForId(String? id) {
  return appIconChoices
      .firstWhere(
        (choice) => choice.id == id,
        orElse: () => appIconChoices.first,
      )
      .icon;
}

String iconLabelForId(String? id) {
  return appIconChoices
      .firstWhere(
        (choice) => choice.id == id,
        orElse: () => appIconChoices.first,
      )
      .label;
}
