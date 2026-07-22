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

const savingsIconChoices = [
  AppIconChoice(
      id: 'savings_general',
      label: 'Ahorro general',
      icon: Icons.savings_outlined),
  AppIconChoice(
      id: 'emergency_fund',
      label: 'Fondo de emergencia',
      icon: Icons.health_and_safety_outlined),
  AppIconChoice(id: 'goal', label: 'Meta', icon: Icons.track_changes_outlined),
  AppIconChoice(
      id: 'travel', label: 'Viaje', icon: Icons.flight_takeoff_outlined),
  AppIconChoice(id: 'house', label: 'Casa', icon: Icons.home_outlined),
  AppIconChoice(
      id: 'education', label: 'Educación', icon: Icons.school_outlined),
  AppIconChoice(id: 'car', label: 'Auto', icon: Icons.directions_car_outlined),
  AppIconChoice(
      id: 'retirement', label: 'Jubilación', icon: Icons.beach_access_outlined),
  AppIconChoice(
      id: 'investment', label: 'Inversión', icon: Icons.trending_up_outlined),
  AppIconChoice(id: 'health', label: 'Salud', icon: Icons.favorite_border),
  AppIconChoice(id: 'pets', label: 'Mascotas', icon: Icons.pets_outlined),
  AppIconChoice(
      id: 'technology', label: 'Tecnología', icon: Icons.laptop_outlined),
  AppIconChoice(id: 'wedding', label: 'Boda', icon: Icons.favorite_outline),
  AppIconChoice(
      id: 'gifts', label: 'Regalos', icon: Icons.card_giftcard_outlined),
  AppIconChoice(
      id: 'debts', label: 'Deudas', icon: Icons.request_quote_outlined),
  AppIconChoice(id: 'other_savings', label: 'Otros', icon: Icons.more_horiz),
];

IconData iconDataForId(String? id) {
  return [...appIconChoices, ...savingsIconChoices]
      .firstWhere(
        (choice) => choice.id == id,
        orElse: () => appIconChoices.first,
      )
      .icon;
}

String iconLabelForId(String? id) {
  return [...appIconChoices, ...savingsIconChoices]
      .firstWhere(
        (choice) => choice.id == id,
        orElse: () => appIconChoices.first,
      )
      .label;
}
