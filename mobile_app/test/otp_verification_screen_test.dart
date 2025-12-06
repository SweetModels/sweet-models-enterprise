import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/otp_verification_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

void main() {
  group('OTP Verification Screen Tests', () {
    testWidgets('OTP Screen renders correctly', (WidgetTester tester) async {
      bool verificationComplete = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {
              verificationComplete = true;
            },
          ),
        ),
      );

      // Verificar que el título aparece
      expect(find.text('Verificación de Identidad'), findsOneWidget);

      // Verificar que el icono de teléfono aparece
      expect(find.byIcon(Icons.phone_android), findsOneWidget);

      // Verificar que PinCodeTextField está presente
      expect(find.byType(PinCodeTextField), findsOneWidget);

      // Verificar que el mensaje de countdown aparece
      expect(find.textContaining('segundos'), findsOneWidget);
    });

    testWidgets('Phone number is masked', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Verificar que el teléfono está enmascarado
      expect(find.textContaining('****'), findsAtLeastNWidgets(1));
    });

    testWidgets('Countdown timer starts at 30', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Verificar que el countdown comienza en 30
      expect(find.textContaining('30'), findsOneWidget);
    });

    testWidgets('Countdown decreases over time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Esperar 2 segundos
      await tester.pump(const Duration(seconds: 2));

      // Verificar que el contador cambió (debe ser menor a 30)
      expect(find.textContaining('28'), findsOneWidget);
    });

    testWidgets('OTP info text is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Verificar que el texto informativo aparece
      expect(
        find.textContaining('Los códigos son válidos por 10 minutos'),
        findsOneWidget,
      );
    });

    testWidgets('Cannot go back during verification', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Verificar que WillPopScope está configurado
      final willPopScope = tester.widget<WillPopScope>(
        find.byType(WillPopScope),
      );

      // Verificar que onWillPop retorna false
      expect(await willPopScope.onWillPop?.call(), false);
    });
  });

  group('OTP Verification Screen Styling', () {
    testWidgets('Uses corporate colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '+573001234567',
            onVerificationComplete: () {},
          ),
        ),
      );

      // Verificar que el background es oscuro
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0A0E27));

      // Verificar que el AppBar tiene el color correcto
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFF1D1E33));
    });
  });

  group('OTP Verification Screen Edge Cases', () {
    testWidgets('Handles empty phone', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '',
            onVerificationComplete: () {},
          ),
        ),
      );

      // La app no debería crashear
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('Handles invalid phone format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            phone: '123',
            onVerificationComplete: () {},
          ),
        ),
      );

      // La app no debería crashear
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });
  });
}
