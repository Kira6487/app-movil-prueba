import 'package:flutter/material.dart';

import '../../widgets/common/app_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Configuracion',
      children: [
        ListTile(
          leading: Icon(Icons.tune),
          title: Text('Preferencias generales'),
          subtitle: Text('Pantalla preparada para proximas etapas'),
        ),
      ],
    );
  }
}
