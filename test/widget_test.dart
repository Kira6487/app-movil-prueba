import 'package:finanzas_personales/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const FinanzasPersonalesApp());

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Resumen del mes'), findsOneWidget);
    expect(find.text('Mayo 2025'), findsOneWidget);
  });
}
