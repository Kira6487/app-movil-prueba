import 'package:flutter/material.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item)),
          ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
