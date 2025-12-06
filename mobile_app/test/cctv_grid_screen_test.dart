import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/cctv_grid_screen.dart';

void main() {
  group('CCTV Grid Screen Tests', () {
    testWidgets('CCTV Screen basic structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      // Verificar elementos básicos
      expect(find.text('Monitoreo en Vivo'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Uses dark theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      expect(scaffold.backgroundColor, const Color(0xFF0A0E27));
      expect(appBar.backgroundColor, const Color(0xFF1D1E33));
    });

    testWidgets('AppBar has correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, 0);
    });

    testWidgets('Shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      // Sin pump adicional, debería mostrar loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Has camera icon in title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CctvGridScreen(),
        ),
      );

      expect(find.byIcon(Icons.videocam), findsAtLeastNWidgets(1));
    });
  });
}
