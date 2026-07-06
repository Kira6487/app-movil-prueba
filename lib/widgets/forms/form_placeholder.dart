import 'package:flutter/material.dart';

import '../common/app_card.dart';

class FormPlaceholder extends StatelessWidget {
  const FormPlaceholder({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(description!),
          ],
        ],
      ),
    );
  }
}
