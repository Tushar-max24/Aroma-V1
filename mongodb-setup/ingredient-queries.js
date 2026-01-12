// MongoDB Query Functions for Aroma Recipe App
// Utility functions for fast ingredient-based recipe retrieval

const { MongoClient } = require('mongodb');

// Load environment variables
require('dotenv').config();

const uri = process.env.MONGODB_URI;
const dbName = 'Aroma_v1';

/**
 * Find recipes that match selected ingredients
 * @param {string[]} selectedIngredients - Array of ingredient names selected by user
 * @param {number} minMatchCount - Minimum number of ingredients that must match (default: 2)
 * @param {boolean} allowPartialMatch - Allow partial ingredient matching (default: true)
 * @returns {Promise<Array>} Array of matching recipes sorted by match count
 */
async function findRecipesByIngredients(selectedIngredients, minMatchCount = 2, allowPartialMatch = true) {
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    const recipesCollection = db.collection('recipes');
    
    let matchingRecipes;
    
    if (allowPartialMatch) {
      // For partial matching, we need to fetch all recipes and filter in JavaScript
      // because MongoDB regex with $in array doesn't work as expected
      matchingRecipes = await recipesCollection.find({
        status: true
      }).toArray();
      
      // Filter recipes that have partial matches
      matchingRecipes = matchingRecipes.filter(recipe => 
        recipe.needed_ingredients.some(ingredient => 
          selectedIngredients.some(selected => 
            ingredient.toLowerCase().includes(selected.toLowerCase())
          )
        )
      );
    } else {
      // Exact matching only
      matchingRecipes = await recipesCollection.find({
        needed_ingredients: { $in: selectedIngredients },
        status: true
      }).toArray();
    }
    
    // Calculate match scores and filter by minimum match count
    const scoredRecipes = matchingRecipes.map(recipe => {
      let matchCount = 0;
      
      if (allowPartialMatch) {
        // Count partial matches
        matchCount = recipe.needed_ingredients.filter(ingredient => 
          selectedIngredients.some(selected => 
            ingredient.toLowerCase().includes(selected.toLowerCase())
          )
        ).length;
      } else {
        // Count exact matches only
        matchCount = recipe.needed_ingredients.filter(ingredient => 
          selectedIngredients.includes(ingredient)
        ).length;
      }
      
      return {
        ...recipe,
        matchCount,
        matchPercentage: Math.round((matchCount / recipe.needed_ingredients.length) * 100),
        matchedIngredients: recipe.needed_ingredients.filter(ingredient => 
          allowPartialMatch 
            ? selectedIngredients.some(selected => ingredient.toLowerCase().includes(selected.toLowerCase()))
            : selectedIngredients.includes(ingredient)
        )
      };
    }).filter(recipe => recipe.matchCount >= minMatchCount);
    
    // Sort by match count (descending) and then by match percentage
    scoredRecipes.sort((a, b) => {
      if (b.matchCount !== a.matchCount) {
        return b.matchCount - a.matchCount;
      }
      return b.matchPercentage - a.matchPercentage;
    });
    
    return scoredRecipes;
    
  } catch (error) {
    console.error('Error finding recipes by ingredients:', error);
    throw error;
  } finally {
    await client.close();
  }
}

/**
 * Find exact ingredient matches (all selected ingredients must be present)
 * @param {string[]} selectedIngredients - Array of ingredient names selected by user
 * @returns {Promise<Array>} Array of recipes containing all selected ingredients
 */
async function findExactIngredientMatches(selectedIngredients) {
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    const recipesCollection = db.collection('recipes');
    
    // Find recipes that contain ALL selected ingredients
    const exactMatches = await recipesCollection.find({
      needed_ingredients: { $all: selectedIngredients },
      status: true
    }).toArray();
    
    return exactMatches;
    
  } catch (error) {
    console.error('Error finding exact ingredient matches:', error);
    throw error;
  } finally {
    await client.close();
  }
}

/**
 * Get popular ingredients based on recipe frequency
 * @param {number} limit - Maximum number of ingredients to return
 * @returns {Promise<Array>} Array of popular ingredients with usage count
 */
async function getPopularIngredients(limit = 20) {
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    const recipesCollection = db.collection('recipes');
    
    // Aggregate to count ingredient usage across all recipes
    const popularIngredients = await recipesCollection.aggregate([
      { $match: { status: true } },
      { $unwind: "$needed_ingredients" },
      { $group: { _id: "$needed_ingredients", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: limit },
      { $project: { ingredient: "$_id", usageCount: "$count", _id: 0 } }
    ]).toArray();
    
    return popularIngredients;
    
  } catch (error) {
    console.error('Error getting popular ingredients:', error);
    throw error;
  } finally {
    await client.close();
  }
}

/**
 * Update last_accessed timestamp for recipes (useful for tracking user preferences)
 * @param {string[]} recipeIds - Array of recipe IDs to update
 */
async function updateRecipeAccessTime(recipeIds) {
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    const db = client.db(dbName);
    const recipesCollection = db.collection('recipes');
    
    await recipesCollection.updateMany(
      { _id: { $in: recipeIds.map(id => new ObjectId(id)) } },
      { $set: { last_accessed: new Date() } }
    );
    
    console.log(`Updated access time for ${recipeIds.length} recipes`);
    
  } catch (error) {
    console.error('Error updating recipe access time:', error);
    throw error;
  } finally {
    await client.close();
  }
}

// Example usage and testing
async function demonstrateQueries() {
  try {
    console.log('=== Testing Ingredient-Based Recipe Queries ===\n');
    
    // Example 1: Partial matching (default behavior)
    const selectedIngredients = ["Chicken"];
    console.log(`Finding recipes with partial match for: ${selectedIngredients.join(', ')}`);
    
    const partialMatches = await findRecipesByIngredients(selectedIngredients, 1, true);
    console.log(`Found ${partialMatches.length} matching recipes (partial match):`);
    partialMatches.forEach(recipe => {
      console.log(`- ${recipe.recipe_name} (${recipe.matchCount}/${recipe.needed_ingredients.length} ingredients matched)`);
      console.log(`  Matched ingredients: ${recipe.matchedIngredients.join(', ')}`);
    });
    
    console.log('\n');
    
    // Example 2: Exact matching
    console.log(`Finding recipes with exact match for: ${selectedIngredients.join(', ')}`);
    
    const exactMatches = await findRecipesByIngredients(selectedIngredients, 1, false);
    console.log(`Found ${exactMatches.length} matching recipes (exact match):`);
    exactMatches.forEach(recipe => {
      console.log(`- ${recipe.recipe_name} (${recipe.matchCount}/${recipe.needed_ingredients.length} ingredients matched)`);
      console.log(`  Matched ingredients: ${recipe.matchedIngredients.join(', ')}`);
    });
    
    console.log('\n');
    
    // Example 3: Multiple ingredients with partial matching
    const multipleIngredients = ["Chicken", "Eggs"];
    console.log(`Finding recipes with partial match for: ${multipleIngredients.join(', ')}`);
    
    const multipleMatches = await findRecipesByIngredients(multipleIngredients, 1, true);
    console.log(`Found ${multipleMatches.length} matching recipes (partial match):`);
    multipleMatches.forEach(recipe => {
      console.log(`- ${recipe.recipe_name} (${recipe.matchCount}/${recipe.needed_ingredients.length} ingredients matched)`);
      console.log(`  Matched ingredients: ${recipe.matchedIngredients.join(', ')}`);
    });
    
    console.log('\n');
    
    // Example 4: Get popular ingredients
    console.log('Getting popular ingredients:');
    const popularIngredients = await getPopularIngredients(10);
    popularIngredients.forEach(ing => {
      console.log(`- ${ing.ingredient} (used in ${ing.usageCount} recipes)`);
    });
    
  } catch (error) {
    console.error('Error in demonstration:', error);
  }
}

// Export functions for use in other modules
module.exports = {
  findRecipesByIngredients,
  findExactIngredientMatches,
  getPopularIngredients,
  updateRecipeAccessTime,
  demonstrateQueries
};

// Run demonstration if this file is executed directly
if (require.main === module) {
  demonstrateQueries();
}
