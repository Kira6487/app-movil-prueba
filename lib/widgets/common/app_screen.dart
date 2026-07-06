import 'package:flutter/material.dart';

import 'app_scaffold.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      actions: actions,
      children: children,
    );
  }
}
