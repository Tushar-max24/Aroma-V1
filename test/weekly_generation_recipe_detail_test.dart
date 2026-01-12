import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/ui/screens/weekly_generation/weekly_generation_recipe_detail_screen.dart';

void main() {
  group('Weekly Generation Recipe Detail Screen - Cuisine Type Tests', () {
    testWidgets('should display cuisine from "Cuisine" field', (WidgetTester tester) async {
      final recipeData = {
        'Recipe Name': 'Test Recipe',
        'Cuisine': 'Indian',
        'Cooking Time': '30 min',
        'Serving': 4,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyGenerationRecipeDetailScreen(recipeData: recipeData),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the cuisine is displayed
      expect(find.text('Indian'), findsOneWidget);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('should display cuisine from "Cuisine_Preference" field', (WidgetTester tester) async {
      final recipeData = {
        'Recipe Name': 'Test Recipe',
        'Cuisine_Preference': 'Chinese',
        'Cooking Time': '30 min',
        'Serving': 4,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyGenerationRecipeDetailScreen(recipeData: recipeData),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the cuisine is displayed
      expect(find.text('Chinese'), findsOneWidget);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('should display cuisine from "Recipe Type" field', (WidgetTester tester) async {
      final recipeData = {
        'Recipe Name': 'Test Recipe',
        'Recipe Type': 'Italian',
        'Cooking Time': '30 min',
        'Serving': 4,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyGenerationRecipeDetailScreen(recipeData: recipeData),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the cuisine is displayed
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('Unknown'), findsNothing);
    });

    testWidgets('should display "Unknown" when no cuisine field is found', (WidgetTester tester) async {
      final recipeData = {
        'Recipe Name': 'Test Recipe',
        'Cooking Time': '30 min',
        'Serving': 4,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyGenerationRecipeDetailScreen(recipeData: recipeData),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if "Unknown" is displayed when no cuisine is found
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('should prioritize first found cuisine field', (WidgetTester tester) async {
      final recipeData = {
        'Recipe Name': 'Test Recipe',
        'Cuisine': 'Indian',
        'Cuisine_Preference': 'Chinese',
        'Recipe Type': 'Italian',
        'Cooking Time': '30 min',
        'Serving': 4,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyGenerationRecipeDetailScreen(recipeData: recipeData),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the first cuisine field (Cuisine) is prioritized
      expect(find.text('Indian'), findsOneWidget);
      expect(find.text('Chinese'), findsNothing);
      expect(find.text('Italian'), findsNothing);
    });
  });
}
