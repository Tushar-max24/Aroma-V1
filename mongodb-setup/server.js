// Express Server for Aroma Recipe App
// Serves recipes, users, and ingredients from MongoDB Atlas

const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');

// Load environment variables
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const uri = process.env.MONGODB_URI;
const dbName = 'Aroma_v1'; // Fixed to match setup-database.js

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
let db;

async function connectToDatabase() {
  if (!process.env.MONGODB_URI) {
    console.error('❌ MONGODB_URI environment variable is not set');
    console.error('Please check your .env file and ensure MONGODB_URI is defined');
    process.exit(1);
  }
  
  const client = new MongoClient(process.env.MONGODB_URI);
  await client.connect();
  console.log('✅ Connected to MongoDB Atlas');
  db = client.db(dbName);
  return db;
}

// Initialize database connection
connectToDatabase().catch(console.error);

// API Routes

// Get all recipes
app.get('/api/recipes', async (req, res) => {
  try {
    const recipes = await db.collection('recipes').find({}).toArray();
    res.json(recipes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get recipe by ID
app.get('/api/recipes/:id', async (req, res) => {
  try {
    const recipe = await db.collection('recipes').findOne({ 
      _id: new ObjectId(req.params.id) 
    });
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }
    res.json(recipe);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get recipe by name and cooking preference
app.get('/api/recipes/preference/:name/:preference', async (req, res) => {
  try {
    console.log(`🔍 GET /api/recipes/preference/${req.params.name}/${req.params.preference}`);
    
    const recipe = await db.collection('recipes').findOne({ 
      name: { $regex: new RegExp(`^${req.params.name}$`, 'i') },
      cooking_preference: req.params.preference.toLowerCase()
    });
    
    if (recipe) {
      console.log(`✅ Found recipe by preference: ${req.params.name} (${req.params.preference})`);
      console.log(`📦 Recipe keys: ${Object.keys(recipe)}`);
      console.log(`🖼️ Recipe image: ${recipe.image_url}`);
      console.log(`🏷️ Recipe tags: ${JSON.stringify(recipe.tags)}`);
      console.log(`🥘 Recipe needed_ingredients: ${JSON.stringify(recipe.needed_ingredients)}`);
      res.json(recipe);
    } else {
      console.log(`❌ Recipe not found by preference: ${req.params.name} (${req.params.preference})`);
      res.status(404).json({ error: 'Recipe not found' });
    }
  } catch (error) {
    console.error('❌ Error fetching recipe by preference:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add new recipe
app.post('/api/recipes', async (req, res) => {
  try {
    console.log('📥 POST /api/recipes request received');
    console.log('📋 Request body:', JSON.stringify(req.body, null, 2));
    console.log('📋 Request body type:', typeof req.body);
    
    const recipeData = {
      ...req.body,
      _id: new ObjectId(),
      created_at: new Date(),
      last_accessed: new Date(),
      // Ensure enhanced schema fields are present
      tags: req.body.tags || [],
      needed_ingredients: req.body.needed_ingredients || [],
      cooking_preference: req.body.cooking_preference || 'general',
      updated_at: new Date()
    };
    
    console.log('🔍 Final recipe data to insert:', JSON.stringify(recipeData, null, 2));
    console.log('🔍 Recipe data keys:', Object.keys(recipeData));
    console.log('🔍 Cookware in recipe data:', recipeData.tags?.cookware);
    console.log('🏷️ Recipe tags:', JSON.stringify(recipeData.tags));
    console.log('🥘 Recipe needed_ingredients:', JSON.stringify(recipeData.needed_ingredients));
    console.log('🍳 Recipe cooking_preference:', recipeData.cooking_preference);
    
    const result = await db.collection('recipes').insertOne(recipeData);
    
    console.log(`✅ Successfully stored recipe: ${recipeData.recipe_name} (ID: ${result.insertedId})`);
    console.log('🔍 MongoDB insert result:', result);
    console.log('🔍 MongoDB insert acknowledged:', result.acknowledged);
    
    res.status(201).json({ 
      message: 'Recipe added successfully',
      recipeId: result.insertedId,
      recipe: recipeData
    });
  } catch (error) {
    console.error('❌ Error adding recipe:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({ error: error.message });
  }
});

// Get all ingredients
app.get('/api/ingredients', async (req, res) => {
  try {
    const ingredients = await db.collection('ingredients').find({}).toArray();
    res.json(ingredients);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get ingredient by name
app.get('/api/ingredients/name/:name', async (req, res) => {
  try {
    const ingredient = await db.collection('ingredients').findOne({ 
      name: req.params.name 
    });
    if (!ingredient) {
      return res.status(404).json({ error: 'Ingredient not found' });
    }
    res.json(ingredient);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const users = await db.collection('users').find({}).toArray();
    // Remove password hash from response
    const usersWithoutPasswords = users.map(user => {
      const { password_hash, ...userWithoutPassword } = user;
      return userWithoutPassword;
    });
    res.json(usersWithoutPasswords);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by username
app.get('/api/users/username/:username', async (req, res) => {
  try {
    const user = await db.collection('users').findOne({ 
      username: req.params.username 
    });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    // Remove password hash from response
    const { password_hash, ...userWithoutPassword } = user;
    res.json(userWithoutPassword);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Recipe recommendations based on user preferences
app.get('/api/recommendations/:usernameOrId', async (req, res) => {
  try {
    let user;
    const identifier = req.params.usernameOrId;
    
    // Try to find by username first
    user = await db.collection('users').findOne({ 
      username: identifier 
    });
    
    // If not found, try to find by ObjectId
    if (!user) {
      try {
        user = await db.collection('users').findOne({ 
          _id: new ObjectId(identifier) 
        });
      } catch (error) {
        // Invalid ObjectId format
      }
    }
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Find recipes matching user preferences
    const queryConditions = [];
    
    // Only add conditions if preferences exist and are not empty
    if (user.preferences.dietary_restrictions && user.preferences.dietary_restrictions.length > 0) {
      queryConditions.push({ "tags.dietary": { $in: user.preferences.dietary_restrictions } });
    }
    if (user.preferences.favorite_cuisines && user.preferences.favorite_cuisines.length > 0) {
      queryConditions.push({ "tags.cuisine": { $in: user.preferences.favorite_cuisines } });
    }
    if (user.preferences.meal_preferences && user.preferences.meal_preferences.length > 0) {
      queryConditions.push({ "tags.meal_type": { $in: user.preferences.meal_preferences } });
    }
    if (user.preferences.cookware && user.preferences.cookware.length > 0) {
      queryConditions.push({ "tags.cookware": { $in: user.preferences.cookware } });
    }
    if (user.preferences.cooking_time && user.preferences.cooking_time.length > 0) {
      queryConditions.push({ "tags.cooking_time": { $in: user.preferences.cooking_time } });
    }
    
    // If no preferences, return all recipes
    const query = queryConditions.length > 0 ? { $or: queryConditions } : {};
    
    const recommendedRecipes = await db.collection('recipes').find(query).toArray();

    res.json(recommendedRecipes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add new ingredient (for scanned ingredients)
app.post('/api/ingredients', async (req, res) => {
  try {
    console.log('📥 POST /api/ingredients request received');
    console.log('📋 Request body:', req.body);
    
    const { name, image_url, common_units, nutrition_per_100g } = req.body;
    
    if (!name) {
      console.log('❌ Missing required field: name');
      return res.status(400).json({ error: 'Name is required' });
    }
    
    // Check if ingredient already exists
    const existing = await db.collection('ingredients').findOne({ 
      name: { $regex: new RegExp(`^${name}$`, 'i') } // Case-insensitive check
    });
    
    if (existing) {
      console.log(`⚠️ Ingredient already exists: ${name}`);
      return res.status(400).json({ error: 'Ingredient already exists' });
    }
    
    // Add new ingredient with nutrition data
    const newIngredient = {
      name: name.trim(),
      image_url: image_url || '',
      common_units: common_units || ["g", "pcs"],
      nutrition_per_100g: {
        calories: nutrition_per_100g?.calories || 0,
        protein: nutrition_per_100g?.protein || 0,
        carbs: nutrition_per_100g?.carbs || 0,
        fats: nutrition_per_100g?.fats || 0,
        fiber: nutrition_per_100g?.fiber || 0,
        sugar: nutrition_per_100g?.sugar || 0
      },
      created_at: new Date()
    };
    
    console.log('💾 Storing new ingredient:', newIngredient);
    
    const result = await db.collection('ingredients').insertOne(newIngredient);
    
    console.log(`✅ Successfully stored ingredient: ${name} (ID: ${result.insertedId})`);
    
    res.status(201).json({ 
      message: 'Ingredient added successfully',
      ingredientId: result.insertedId,
      ingredient: newIngredient
    });
  } catch (error) {
    console.error('❌ Error adding ingredient:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update ingredient by name
app.put('/api/ingredients/:name', async (req, res) => {
  try {
    console.log('📥 PUT /api/ingredients/:name request received');
    console.log('📋 Params:', req.params);
    console.log('📋 Request body:', req.body);
    
    const { name } = req.params;
    const { nutrition_per_100g } = req.body;
    
    if (!name) {
      console.log('❌ Missing ingredient name');
      return res.status(400).json({ error: 'Ingredient name is required' });
    }
    
    // Find the ingredient
    const existing = await db.collection('ingredients').findOne({ 
      name: { $regex: new RegExp(`^${name}$`, 'i') } // Case-insensitive check
    });
    
    if (!existing) {
      console.log(`❌ Ingredient not found: ${name}`);
      return res.status(404).json({ error: 'Ingredient not found' });
    }
    
    // Update the ingredient with new nutrition data
    const updateData = {
      $set: {
        nutrition_per_100g: {
          calories: nutrition_per_100g?.calories || existing.nutrition_per_100g?.calories || 0,
          protein: nutrition_per_100g?.protein || existing.nutrition_per_100g?.protein || 0,
          carbs: nutrition_per_100g?.carbs || existing.nutrition_per_100g?.carbs || 0,
          fats: nutrition_per_100g?.fats || existing.nutrition_per_100g?.fats || 0,
          fiber: nutrition_per_100g?.fiber || existing.nutrition_per_100g?.fiber || 0,
          sugar: nutrition_per_100g?.sugar || existing.nutrition_per_100g?.sugar || 0
        },
        updated_at: new Date()
      }
    };
    
    console.log('🔧 Updating ingredient with data:', updateData);
    
    const result = await db.collection('ingredients').updateOne(
      { name: { $regex: new RegExp(`^${name}$`, 'i') } },
      updateData
    );
    
    if (result.matchedCount === 0) {
      console.log(`❌ No ingredient matched: ${name}`);
      return res.status(404).json({ error: 'Ingredient not found' });
    }
    
    console.log(`✅ Successfully updated ingredient: ${name}`);
    
    // Return the updated ingredient
    const updatedIngredient = await db.collection('ingredients').findOne({ 
      name: { $regex: new RegExp(`^${name}$`, 'i') } 
    });
    
    res.status(200).json({ 
      message: 'Ingredient updated successfully',
      ingredient: updatedIngredient
    });
  } catch (error) {
    console.error('❌ Error updating ingredient:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Aroma Recipe API is running',
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Aroma Recipe API Server',
    endpoints: {
      recipes: '/api/recipes',
      ingredients: '/api/ingredients',
      users: '/api/users',
      recommendations: '/api/recommendations/:username',
      health: '/api/health'
    }
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Aroma Recipe API Server running on port ${PORT}`);
  console.log(`📡 API Base URL: http://0.0.0.0:${PORT}/api`);
  console.log(`🏥 Health Check: http://0.0.0.0:${PORT}/api/health`);
  console.log(`🌐 External Access: http://172.16.1.119:${PORT}/api`);
});
