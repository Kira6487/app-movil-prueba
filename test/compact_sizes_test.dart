import 'package:finanzas_personales/widgets/buttons/app_primary_button.dart';
import 'package:finanzas_personales/widgets/buttons/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [
    Size(320, 700),
    Size(360, 760),
    Size(412, 915),
  ]) {
    testWidgets(
        'acciones no desbordan en ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Nueva alcancía',
                      icon: Icons.savings_outlined,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Transferir',
                      icon: Icons.swap_horiz,
                      onPressed: () {},
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  }
}
