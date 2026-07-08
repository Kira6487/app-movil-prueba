import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class ColorChoice {
  const ColorChoice(this.hex, this.label);

  final String hex;
  final String label;
}

const appColorChoices = [
  ColorChoice('#005FD1', 'Azul'),
  ColorChoice('#38C7E8', 'Celeste'),
  ColorChoice('#20C982', 'Verde'),
  ColorChoice('#FF4D5E', 'Coral'),
  ColorChoice('#FF9F1C', 'Naranja'),
  ColorChoice('#8A6DFF', 'Morado'),
];

class ColorPaletteField extends StatelessWidget {
  const ColorPaletteField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final choice in appColorChoices)
                ChoiceChip(
                  selected: choice.hex == value,
                  label: Text(choice.label),
                  avatar:
                      CircleAvatar(backgroundColor: colorFromHex(choice.hex)),
                  onSelected: (_) => onChanged(choice.hex),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Color colorFromHex(String? value) {
  if (value == null || value.length != 7 || !value.startsWith('#')) {
    return AppColors.blue;
  }
  return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
}
