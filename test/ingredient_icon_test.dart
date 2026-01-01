import 'package:flutter_test/flutter_test.dart';
import '../lib/core/utils/item_image_resolver.dart';

void main() {
  group('Ingredient Icon Tests', () {
    test('Cream cheese should return cheese emoji', () {
      final emoji = ItemImageResolver.getEmojiForIngredient('cream cheese');
      expect(emoji, equals('🧀'));
    });

    test('Granulated sugar should return rice emoji', () {
      final emoji = ItemImageResolver.getEmojiForIngredient('granulated sugar');
      expect(emoji, equals('🍚'));
    });

    test('Case insensitive matching should work', () {
      final emoji1 = ItemImageResolver.getEmojiForIngredient('Cream Cheese');
      final emoji2 = ItemImageResolver.getEmojiForIngredient('CREAM CHEESE');
      expect(emoji1, equals('🧀'));
      expect(emoji2, equals('🧀'));
    });

    test('Partial matching should work', () {
      final emoji1 = ItemImageResolver.getEmojiForIngredient('cream cheese spread');
      final emoji2 = ItemImageResolver.getEmojiForIngredient('brown granulated sugar');
      expect(emoji1, equals('🧀'));
      expect(emoji2, equals('🍚'));
    });

    test('Unknown ingredient should return default emoji', () {
      final emoji = ItemImageResolver.getEmojiForIngredient('unknown ingredient xyz');
      expect(emoji, equals('🍽️'));
    });

    test('Empty string should return default emoji', () {
      final emoji = ItemImageResolver.getEmojiForIngredient('');
      expect(emoji, equals('🍽️'));
    });
  });
}
