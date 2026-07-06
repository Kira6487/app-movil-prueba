import 'package:finanzas_personales/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('muestra la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const FinanzasPersonalesApp());
    await tester.pump();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Resumen del mes'), findsOneWidget);
    expect(find.text('Mayo 2025'), findsOneWidget);
  });
}
