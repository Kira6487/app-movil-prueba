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
  ColorChoice('#005FD1', 'Azul Duna'),
  ColorChoice('#38C7E8', 'Celeste'),
  ColorChoice('#20C982', 'Verde'),
  ColorChoice('#FF4D5E', 'Coral'),
  ColorChoice('#FF9F1C', 'Naranja'),
  ColorChoice('#8A6DFF', 'Morado'),
  ColorChoice('#EAB308', 'Dorado'),
  ColorChoice('#0F766E', 'Turquesa'),
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
    final color = colorFromHex(value);
    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.surfaceAlt,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (_) => _ColorPickerDialog(initialHex: value),
          );
          if (selected != null) onChanged(selected);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.label),
                    const SizedBox(height: 3),
                    Text(normalizeHex(value), style: AppTextStyles.muted),
                  ],
                ),
              ),
              const Icon(Icons.colorize_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialHex});
  final String initialHex;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hexController;
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    final initial = colorFromHex(widget.initialHex);
    _hsv = HSVColor.fromColor(initial);
    _hexController = TextEditingController(text: colorToHex(initial));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() => _hsv = value);
    _hexController.text = colorToHex(value.toColor());
  }

  void _applyHex(String value) {
    if (!isValidHex(value)) return;
    setState(() => _hsv = HSVColor.fromColor(colorFromHex(value)));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: const Text('Seleccionar color'),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SaturationValueArea(
                  hsv: _hsv,
                  onChanged: _setHsv,
                ),
                const SizedBox(height: 14),
                const Text('Tono', style: AppTextStyles.label),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackShape: const _HueTrackShape(),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: _hsv.hue,
                    min: 0,
                    max: 360,
                    onChanged: (hue) => _setHsv(_hsv.withHue(hue)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hexController,
                        maxLength: 7,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'HEX',
                          counterText: '',
                          prefixText: '',
                        ),
                        validator: (value) => isValidHex(value ?? '')
                            ? null
                            : 'Usa el formato #RRGGBB',
                        onChanged: _applyHex,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Colores Duna', style: AppTextStyles.label),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final choice in appColorChoices)
                      Tooltip(
                        message: choice.label,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _setHsv(
                              HSVColor.fromColor(colorFromHex(choice.hex))),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorFromHex(choice.hex),
                              border: Border.all(
                                color: colorToHex(color) == choice.hex
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, normalizeHex(_hexController.text));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LayoutBuilder(builder: (context, constraints) {
        void update(Offset position) {
          final saturation =
              (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
          final value =
              (1 - position.dy / constraints.maxHeight).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          onTapDown: (details) => update(details.localPosition),
          onPanUpdate: (details) => update(details.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.saturation * constraints.maxWidth - 8,
                  top: (1 - hsv.value) * constraints.maxHeight - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 2)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _HueTrackShape extends RoundedRectSliderTrackShape {
  const _HueTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    const colors = [
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.red,
    ];
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..shader = const LinearGradient(colors: colors).createShader(rect),
    );
  }
}

bool isValidHex(String value) =>
    RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value.trim());

String normalizeHex(String value) {
  final normalized = value.trim().toUpperCase();
  return isValidHex(normalized) ? normalized : '#005FD1';
}

String colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color colorFromHex(String? value) {
  final normalized = normalizeHex(value ?? '');
  return Color(int.parse(normalized.substring(1), radix: 16) + 0xFF000000);
}
