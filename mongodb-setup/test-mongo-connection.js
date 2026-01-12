const { MongoClient } = require('mongodb');
require('dotenv').config();

// Test script to verify MongoDB connection and data storage
async function testMongoConnection() {
  const uri = process.env.MONGODB_URI;
  const dbName = 'Aroma_v1';
  
  console.log('🔍 Testing MongoDB connection...');
  console.log('🔍 URI:', uri);
  
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db(dbName);
    
    // Check if recipes collection exists and has data
    const recipesCount = await db.collection('recipes').countDocuments();
    console.log(`📊 Recipes collection has ${recipesCount} documents`);
    
    // Get latest recipe to verify structure
    const latestRecipe = await db.collection('recipes').findOne({}, { sort: { created_at: -1 } });
    console.log('🔍 Latest recipe:', JSON.stringify(latestRecipe, null, 2));
    
    if (latestRecipe) {
      console.log('✅ Recipe structure verification:');
      console.log('  - recipe_name:', latestRecipe.recipe_name);
      console.log('  - recipe_image_url:', latestRecipe.recipe_image_url);
      console.log('  - cookware:', latestRecipe.tags?.cookware);
      console.log('  - ingredients count:', latestRecipe.ingredients?.length);
    }
    
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
  } finally {
    await client.close();
  }
}

testMongoConnection().catch(console.error);
