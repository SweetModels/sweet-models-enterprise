import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_models_mobile/identity_camera_screen.dart';

void main() {
  group('Identity Camera Screen Tests', () {
    testWidgets('Camera Screen renders correctly', (WidgetTester tester) async {
      bool documentUploaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: 'test-user-id',
            onDocumentUploaded: () {
              documentUploaded = true;
            },
          ),
        ),
      );

      // Verificar que el título correcto aparece
      expect(find.text('Capturar: Frente de la Cédula'), findsOneWidget);

      // Verificar que el scaffold está presente
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('All document types have correct labels', (WidgetTester tester) async {
      final documentTypes = {
        'national_id_front': 'Frente de la Cédula',
        'national_id_back': 'Dorso de la Cédula',
        'selfie': 'Foto de Rostro',
        'proof_address': 'Comprobante de Domicilio',
      };

      for (var entry in documentTypes.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: IdentityCameraScreen(
              documentType: entry.key,
              userId: 'test-user',
              onDocumentUploaded: () {},
            ),
          ),
        );

        // Verificar que el label correcto aparece en el título
        expect(find.textContaining(entry.value), findsOneWidget);

        // Limpiar para la siguiente iteración
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('Screen uses dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: 'test-user',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // Verificar que el scaffold tiene fondo negro
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('AppBar has correct style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'selfie',
            userId: 'test-user',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // Verificar que AppBar tiene estilo correcto
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.black87);
      expect(appBar.elevation, 0);
      expect(appBar.centerTitle, true);
    });

    testWidgets('Cannot go back during upload', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: 'test-user',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // Verificar que WillPopScope está presente
      expect(find.byType(WillPopScope), findsOneWidget);
    });
  });

  group('Identity Camera Screen Edge Cases', () {
    testWidgets('Handles empty userId', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: '',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // La app no debería crashear
      expect(find.byType(IdentityCameraScreen), findsOneWidget);
    });

    testWidgets('Handles unknown document type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'unknown_type',
            userId: 'test-user',
            onDocumentUploaded: () {},
          ),
        ),
      );

      // La app no debería crashear
      expect(find.byType(IdentityCameraScreen), findsOneWidget);
    });
  });

  group('Identity Camera Screen Functionality', () {
    testWidgets('Document type labels are correct', (WidgetTester tester) async {
      // Test national_id_front
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'national_id_front',
            userId: 'test',
            onDocumentUploaded: () {},
          ),
        ),
      );
      expect(find.textContaining('Frente'), findsOneWidget);

      // Test selfie
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityCameraScreen(
            documentType: 'selfie',
            userId: 'test',
            onDocumentUploaded: () {},
          ),
        ),
      );
      expect(find.textContaining('Rostro'), findsOneWidget);
    });
  });
}
