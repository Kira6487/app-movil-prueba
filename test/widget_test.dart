import 'package:finanzas_personales/app.dart';
import 'package:finanzas_personales/screens/reports/reports_screen.dart';
import 'package:finanzas_personales/screens/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';
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

  testWidgets('renderiza registrar ingreso sin error de Material',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransactionFormScreen(type: 'income')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Registrar ingreso'), findsWidgets);
  });

  testWidgets('renderiza registrar gasto sin error de Material',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransactionFormScreen(type: 'expense')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Registrar gasto'), findsWidgets);
  });

  testWidgets('renderiza reportes en pantalla compacta sin overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Reportes'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Reporte por categor\u00EDa'), findsOneWidget);
  });
}
