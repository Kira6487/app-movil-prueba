import 'package:finanzas_personales/app.dart';
import 'package:finanzas_personales/database/app_database.dart';
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

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('muestra la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const FinanzasPersonalesApp());
    await tester.pump();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Resumen de cuentas'), findsOneWidget);
    expect(find.text('Presupuestos'), findsOneWidget);
  });

  testWidgets('renderiza registrar ingreso sin error de Material',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransactionFormScreen(type: 'income')),
    );
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Registrar ingreso'), findsWidgets);
  });

  testWidgets('abre la pestaña de presupuestos sin overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const FinanzasPersonalesApp());
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    await tester.tap(find.text('Presupuestos').last);
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Planifica con tus movimientos reales'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(AppDatabase.instance.close);
    await tester.pump();
  });

  testWidgets('renderiza registrar gasto sin error de Material',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransactionFormScreen(type: 'expense')),
    );
    await tester.pump();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();

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
