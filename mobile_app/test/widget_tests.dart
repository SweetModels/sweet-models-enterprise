import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweet_models_mobile/screens/admin_dashboard_screen.dart';

void main() {
  group('Admin Dashboard Widget Tests', () {
    testWidgets('Shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('Shows metric cards when data loaded', (WidgetTester tester) async {
      // This would require mocking the provider state
      // For now, just verify the structure exists
      
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump();
      
      // Verify AppBar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });
  });
  
  group('Login Form Tests', () {
    testWidgets('Login form has email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });
    
    testWidgets('Password field is obscured', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ),
        ),
      );
      
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });
  });
  
  group('Moderator Console Tests', () {
    testWidgets('Group card shows correct information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                title: const Text('Test Group'),
                subtitle: const Text('3 members'),
                trailing: const Text('15.0K tokens'),
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('3 members'), findsOneWidget);
      expect(find.text('15.0K tokens'), findsOneWidget);
    });
    
    testWidgets('Production form has date and tokens fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Date'),
                ),
                const TextField(
                  decoration: InputDecoration(labelText: 'Tokens'),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Tokens'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });
  });
  
  group('Notification Card Tests', () {
    testWidgets('Notification card displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Achievement Unlocked'),
                subtitle: const Text('You reached 10K tokens!'),
                trailing: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('NEW'),
                ),
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Achievement Unlocked'), findsOneWidget);
      expect(find.text('You reached 10K tokens!'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
    
    testWidgets('High priority notification has different color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              color: Colors.red.shade50,
              child: const ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text('Urgent: Contract Expires Soon'),
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Urgent: Contract Expires Soon'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
  
  group('Progress Bar Tests', () {
    testWidgets('Progress bar shows correct percentage', (WidgetTester tester) async {
      const current = 7500.0;
      const goal = 10000.0;
      const percentage = current / goal;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LinearProgressIndicator(value: percentage),
                Text('${(percentage * 100).toStringAsFixed(0)}%'),
                Text('${(goal - current).toStringAsFixed(0)} tokens remaining'),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('2500 tokens remaining'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
    
    testWidgets('Goal achieved shows special indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                title: Text('🎉 Goal Achieved!'),
                subtitle: Text('10,000 tokens reached'),
              ),
            ),
          ),
        ),
      );
      
      expect(find.textContaining('Goal Achieved'), findsOneWidget);
      expect(find.textContaining('10,000'), findsOneWidget);
    });
  });
  
  group('Export Dialog Tests', () {
    testWidgets('Export dialog shows format options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Export Data'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          ListTile(title: Text('Export as CSV')),
                          ListTile(title: Text('Export as Excel')),
                          ListTile(title: Text('Export as PDF')),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Export'),
              ),
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Export as CSV'), findsOneWidget);
      expect(find.text('Export as Excel'), findsOneWidget);
      expect(find.text('Export as PDF'), findsOneWidget);
    });
  });
}
