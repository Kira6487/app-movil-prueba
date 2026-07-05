import 'package:flutter/material.dart';

class FormPlaceholder extends StatelessWidget {
  const FormPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}
