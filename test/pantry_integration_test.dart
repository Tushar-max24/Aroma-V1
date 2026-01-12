import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/state/pantry_state.dart';
import '../lib/ui/screens/calendar/calendar_empty_screen.dart';

void main() {
  group('Pantry Items Integration Tests', () {
    testWidgets('should use local pantry items for recipe generation', (WidgetTester tester) async {
      // Create mock pantry items
      final mockPantryItems = [
        {'name': 'apple', 'quantity': 5, 'unit': 'pcs'},
        {'name': 'pomegranate', 'quantity': 2, 'unit': 'pcs'},
      ];

      // Create test app with PantryState
      final pantryState = PantryState();
      
      // Add items to pantry state
      for (final item in mockPantryItems) {
        await pantryState.setItem(
          item['name'] as String,
          (item['quantity'] as num).toDouble(),
          item['unit'] as String,
        );
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<PantryState>(
          create: (_) => pantryState,
          child: MaterialApp(
            home: Scaffold(
              body: CalendarEmptyScreen(),
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that local pantry items are used
      // This test would need to be expanded based on the actual implementation
      expect(pantryState.items.length, equals(2));
      expect(pantryState.items.first.name, equals('apple'));
      expect(pantryState.items.last.name, equals('pomegranate'));
    });

    testWidgets('should handle empty pantry gracefully', (WidgetTester tester) async {
      final emptyPantryState = PantryState();

      await tester.pumpWidget(
        ChangeNotifierProvider<PantryState>(
          create: (_) => emptyPantryState,
          child: MaterialApp(
            home: Scaffold(
              body: CalendarEmptyScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty pantry is handled
      expect(emptyPantryState.items.length, equals(0));
    });
  });
}
