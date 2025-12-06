import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/register_model_screen_advanced.dart';

void main() {
  group('Register Model Screen Advanced Tests', () {
    testWidgets('Register Screen basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      // Verificar elementos básicos
      expect(find.text('Registro de Modelo'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Uses corporate colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      expect(scaffold.backgroundColor, const Color(0xFF0A0E27));
      expect(appBar.backgroundColor, const Color(0xFF1D1E33));
      expect(appBar.elevation, 0);
      expect(appBar.centerTitle, true);
    });

    testWidgets('Step 1 shows basic info', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      // Verificar paso 1
      expect(find.text('Datos Básicos'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Basic input fields are present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      // Verificar iconos de campos
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
    });

    testWidgets('Continue button exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('Uses IndexedStack', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('Has person_add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('Is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterModelScreenAdvanced(),
        ),
      );

      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
