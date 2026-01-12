import 'lib/data/services/cache_database_service.dart';

void main() async {
  print('🧪 Testing Database Migration\n');
  
  try {
    // Force database initialization to trigger migration
    final db = await CacheDatabaseService.database;
    print('✅ Database initialized successfully');
    
    // Check if daily_preferences table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='daily_preferences'"
    );
    
    if (tables.isNotEmpty) {
      print('✅ daily_preferences table exists');
      
      // Test inserting and retrieving daily preferences
      final testDate = '2026-01-01';
      final testPreferences = {
        'Cuisine_Preference': 'Test',
        'Dietary_Restrictions': 'None',
      };
      final testHash = 'test_hash_123';
      
      await CacheDatabaseService.cacheDailyPreferences(testDate, testPreferences, testHash);
      print('✅ Successfully cached test preferences');
      
      final retrieved = await CacheDatabaseService.getDailyPreferences(testDate);
      if (retrieved != null) {
        print('✅ Successfully retrieved test preferences');
        print('Retrieved preferences: ${retrieved['preferences']}');
      } else {
        print('❌ Failed to retrieve test preferences');
      }
      
      // Clean up test data
      await db.delete('daily_preferences', where: 'date = ?', whereArgs: [testDate]);
      print('🧹 Cleaned up test data');
      
    } else {
      print('❌ daily_preferences table does not exist');
    }
    
    await CacheDatabaseService.closeDatabase();
    print('🔒 Database closed');
    
  } catch (e) {
    print('❌ Error during migration test: $e');
  }
  
  print('\n🎉 Migration test completed!');
}
