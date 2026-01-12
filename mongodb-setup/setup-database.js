// MongoDB Database Setup for Aroma Recipe App
// This script creates collections and inserts sample data

const { MongoClient, ObjectId } = require('mongodb');

// Load environment variables
require('dotenv').config();

const uri = process.env.MONGODB_URI;
const dbName = 'Aroma_v1'; // Using the correct database name

async function setupDatabase() {
  const client = new MongoClient(uri);
  
  try {
    // Connect to the MongoDB cluster
    await client.connect();
    console.log('Connected to MongoDB Atlas');
    
    const db = client.db(dbName);
    
    // Create recipes collection and insert sample data
    const recipesCollection = db.collection('recipes');
    await recipesCollection.insertOne({
      "_id": new ObjectId(),
      "recipe_name": "Spicy Tuna and Chicken Egg Scramble with Yogurt Drizzle",
      "recipe_description": "A quick and flavorful Indian-inspired lunch featuring tender chicken and flaky tuna scrambled with vibrant cherry tomatoes and creamy cottage cheese. Served with a cooling yogurt drizzle and a side of cheese crackers for a satisfying meal.",
      "difficulty": "Easy",
      "serving": 5,
      "total_time": "30 minutes",
      "recipe_image_url": "http://172.168.11.205:5001/static/food_images/Spicy_Tuna_and_Chicken_Egg_Scramble_with_Yogurt_Dr_recipe_8bd2eaba.png",
      "ingredients": [
        {
          "item": "Chicken Breast",
          "quantity": "500 g",
          "image_url": "http://172.168.11.205:5001/static/food_images/Chicken_Breast_ingredient_446f2b90.png"
        },
        {
          "item": "Canned Tuna",
          "quantity": "6 cans (drained)",
          "image_url": "http://172.168.11.205:5001/static/food_images/Canned_Tuna_ingredient_4a1084b2.png"
        },
        {
          "item": "Large Eggs",
          "quantity": "6 pcs",
          "image_url": "http://172.168.11.205:5001/static/food_images/Large_Eggs_ingredient_0366f58b.png"
        }
      ],
      "cooking_steps": [
        {
          "step": 1,
          "instruction": "Dice the chicken breast into small, bite-sized pieces. Halve the cherry tomatoes.",
          "time": "5 minutes",
          "ingredients_used": [
            { "item": "Chicken Breast", "quantity": "500 g" },
            { "item": "Cherry Tomatoes", "quantity": "1/2 lb" }
          ],
          "tips": [
            "Ensure chicken pieces are uniform in size for even cooking."
          ]
        },
        {
          "step": 2,
          "instruction": "Heat a pan and cook the chicken with spices until browned.",
          "time": "7 minutes",
          "ingredients_used": [
            { "item": "Chicken Breast", "quantity": "500 g" },
            { "item": "Red Chili Powder", "quantity": "1/2 tsp" }
          ],
          "tips": [
            "Do not overcrowd the pan."
          ]
        }
      ],
      "nutrition": {
        "calories": 450,
        "protein": 40,
        "carbs": 20,
        "fats": 20,
        "fiber": 4
      },
      "tags": {
        "meal_type": "Lunch",
        "dietary": "Non-Vegetarian",
        "cuisine": "Indian",
        "cooking_time": "30 minutes",
        "cookware": ["Gas Stove"]
      },
      "needed_ingredients": [
        "Chicken Breast",
        "Canned Tuna", 
        "Large Eggs",
        "Cherry Tomatoes",
        "Red Chili Powder"
      ],
      "source": "generated",
      "status": true,
      "created_at": new Date("2026-01-02T09:40:13.967Z"),
      "last_accessed": new Date("2026-01-02T09:40:13.967Z")
    });

    // Create indexes for better query performance
    await recipesCollection.createIndex({ "recipe_name": 1 });
    await recipesCollection.createIndex({ "tags.meal_type": 1 });
    await recipesCollection.createIndex({ "tags.dietary": 1 });
    await recipesCollection.createIndex({ "tags.cuisine": 1 });
    await recipesCollection.createIndex({ "difficulty": 1 });
    await recipesCollection.createIndex({ "total_time": 1 });
    await recipesCollection.createIndex({ "needed_ingredients": 1 }); // Index for fast ingredient-based queries

    // Create users collection
    const usersCollection = db.collection('users');
    await usersCollection.insertOne({
      "_id": new ObjectId(),
      "username": "admin",
      "email": "admin@aroma.com", 
      "password_hash": "$2b$10$example_hash_here",
      "preferences": {
        "dietary_restrictions": ["Vegetarian"],
        "favorite_cuisines": ["Indian"],
        "meal_preferences": ["Lunch", "Dinner"],
        "cookware": ["Gas Stove", "Microwave"],
        "cooking_time": ["30 minutes", "45 minutes"]
      },
      "created_at": new Date(),
      "last_login": new Date()
    });

    // Create ingredients collection for centralized ingredient management
    const ingredientsCollection = db.collection('ingredients');
    
    // Function to add ingredient to centralized collection (avoid duplicates)
    async function addIngredientToCentralized(ingredient) {
      // Check if ingredient already exists
      const existing = await ingredientsCollection.findOne({ 
        name: ingredient.name.toLowerCase().trim() 
      });
      
      if (!existing) {
        // Add new ingredient to centralized collection
        await ingredientsCollection.insertOne({
          "_id": new ObjectId(),
          "name": ingredient.name,
          "image_url": ingredient.image_url,
          "common_units": ingredient.common_units || ["g", "pcs"],
          "created_at": new Date()
        });
        console.log(`Added new ingredient: ${ingredient.name}`);
      } else {
        console.log(`Ingredient already exists: ${ingredient.name}`);
      }
      return existing;
    }
    
    // Process recipe ingredients and store in centralized collection
    const recipeIngredients = [
      {
        "name": "Chicken Breast",
        "image_url": "http://172.168.11.205:5001/static/food_images/Chicken_Breast_ingredient_446f2b90.png",
        "common_units": ["g", "kg", "lbs"]
      },
      {
        "name": "Canned Tuna",
        "image_url": "http://172.168.11.205:5001/static/food_images/Canned_Tuna_ingredient_4a1084b2.png",
        "common_units": ["can", "g", "oz"]
      },
      {
        "name": "Large Eggs",
        "image_url": "http://172.168.11.205:5001/static/food_images/Large_Eggs_ingredient_0366f58b.png",
        "common_units": ["pcs", "dozen"]
      }
    ];
    
    // Add recipe ingredients to centralized collection
    for (const ingredient of recipeIngredients) {
      await addIngredientToCentralized(ingredient);
    }
    
    // Process cooking step ingredients and store in centralized collection
    const cookingStepIngredients = [
      {
        "name": "Cherry Tomatoes",
        "image_url": "http://172.168.11.205:5001/static/food_images/cherry_tomatoes_ingredient_default.png",
        "common_units": ["g", "lb", "pcs"]
      },
      {
        "name": "Red Chili Powder",
        "image_url": "http://172.168.11.205:5001/static/food_images/red_chili_powder_ingredient_default.png",
        "common_units": ["tsp", "tbsp", "g"]
      }
    ];
    
    // Add cooking step ingredients to centralized collection
    for (const ingredient of cookingStepIngredients) {
      await addIngredientToCentralized(ingredient);
    }

    // Create indexes for ingredients collection
    await ingredientsCollection.createIndex({ "name": 1 });

    console.log("Database setup completed successfully!");
    console.log("Collections created: recipes, users, ingredients");
    console.log("Indexes created for optimal query performance");
    
  } catch (error) {
    console.error('Error setting up database:', error);
  } finally {
    await client.close();
  }
}

setupDatabase().catch(console.error);
