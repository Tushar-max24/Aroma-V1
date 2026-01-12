import 'lib/data/services/home_recipe_service.dart';
import 'lib/data/services/cache_database_service.dart';

void main() async {
  print('🧪 Testing Daily Preferences Implementation\n');
  
  final homeService = HomeRecipeService();
  
  // Test 1: Check daily preferences status
  print('📅 Checking daily preferences status...');
  final dailyStatus = await homeService.getDailyPreferencesStatus();
  print('Daily preferences status: $dailyStatus\n');
  
  // Test 2: Generate recipes (should use cached preferences if available)
  print('🍳 Generating home recipes...');
  try {
    final recipes = await homeService.generateHomeRecipes();
    print('✅ Successfully generated ${recipes.length} recipes');
    print('First recipe: ${recipes.isNotEmpty ? recipes[0] : 'None'}\n');
  } catch (e) {
    print('❌ Error generating recipes: $e\n');
  }
  
  // Test 3: Check cache status
  print('💾 Checking recipe cache status...');
  final cacheStatus = await homeService.getCacheStatus();
  print('Cache status: $cacheStatus\n');
  
  // Test 4: Generate recipes again (should use same preferences)
  print('🔄 Generating recipes again (should use same preferences)...');
  try {
    final recipes2 = await homeService.generateHomeRecipes();
    print('✅ Successfully generated ${recipes2.length} recipes');
    print('First recipe: ${recipes2.isNotEmpty ? recipes2[0] : 'None'}\n');
  } catch (e) {
    print('❌ Error generating recipes: $e\n');
  }
  
  print('🎉 Test completed!');
}
