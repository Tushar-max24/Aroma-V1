// Example usage of the dynamic HomeRecipeService
import '../data/services/home_recipe_service.dart';

class HomeRecipeExample {
  static Future<void> demonstrateDynamicRecipes() async {
    final service = HomeRecipeService();
    
    print('🍳 Dynamic Recipe Generation Demo');
    print('=====================================\n');
    
    try {
      // Generate dynamic recipes
      print('1. Generating dynamic recipes with Gemini...');
      final recipes = await service.generateHomeRecipes();
      
      print('\n2. Generated ${recipes.length} recipes:');
      for (int i = 0; i < recipes.length; i++) {
        final recipe = recipes[i];
        if (recipe is Map) {
          print('   ${i + 1}. ${recipe['name'] ?? 'Unknown Recipe'}');
          if (recipe['cooking_time'] != null) {
            print('      ⏱️ ${recipe['cooking_time']}');
          }
          if (recipe['difficulty'] != null) {
            print('      📊 ${recipe['difficulty']}');
          }
        }
      }
      
      // Check cache status
      print('\n3. Checking cache status...');
      final cacheStatus = await service.getCacheStatus();
      print('   Has Cache: ${cacheStatus['hasCache']}');
      if (cacheStatus['hasCache']) {
        print('   Cache Age: ${cacheStatus['ageHours']} hours');
        print('   Is Expired: ${cacheStatus['isExpired']}');
        print('   Cuisine: ${cacheStatus['cuisine']}');
      }
      
      // Test second call (should use cache)
      print('\n4. Second call (should use cache)...');
      final cachedRecipes = await service.generateHomeRecipes();
      print('   Got ${cachedRecipes.length} recipes from cache');
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  static Future<void> clearCacheDemo() async {
    final service = HomeRecipeService();
    
    print('🧹 Cache Clear Demo');
    print('==================\n');
    
    try {
      await service.clearCache();
      print('✅ Cache cleared successfully');
      
      final status = await service.getCacheStatus();
      print('Cache status: ${status['hasCache'] ? 'Exists' : 'Empty'}');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}
