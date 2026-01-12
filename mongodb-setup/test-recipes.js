// Test script to verify recipes functionality
const http = require('http');

// Test health check first
function testHealthCheck() {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/health',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const req = http.request(options, (res) => {
    console.log(`Health Check Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('Health Check Response:', data);
      
      if (res.statusCode === 200) {
        console.log('✅ Server is running!');
        
        // Test inserting a sample recipe
        testInsertSampleRecipe();
      } else {
        console.log('❌ Server is not responding correctly');
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error connecting to server:', error.message);
  });

  req.end();
}

// Test inserting a sample recipe
function testInsertSampleRecipe() {
  const sampleRecipe = {
    recipe_name: "Simple Vegetable Stir Fry",
    recipe_description: "A quick and healthy vegetable stir fry with colorful vegetables and savory sauce.",
    difficulty: "Easy",
    serving: 4,
    total_time: "20 minutes",
    recipe_image_url: "http://example.com/stir-fry.jpg",
    ingredients: [
      {
        item: "Broccoli",
        quantity: "200 g",
        image_url: "http://example.com/broccoli.jpg"
      },
      {
        item: "Carrots",
        quantity: "150 g",
        image_url: "http://example.com/carrots.jpg"
      },
      {
        item: "Bell Pepper",
        quantity: "1 pcs",
        image_url: "http://example.com/bell-pepper.jpg"
      }
    ],
    cooking_steps: [
      {
        step: 1,
        instruction: "Heat oil in a wok or large pan over medium-high heat.",
        time: "2 minutes",
        ingredients_used: [],
        tips: ["Use a wok for best results"]
      },
      {
        step: 2,
        instruction: "Add vegetables and stir-fry for 5-7 minutes until tender-crisp.",
        time: "7 minutes",
        ingredients_used: [
          { item: "Broccoli", quantity: "200 g" },
          { item: "Carrots", quantity: "150 g" },
          { item: "Bell Pepper", quantity: "1 pcs" }
        ],
        tips: ["Don't overcrowd the pan"]
      }
    ],
    nutrition: {
      calories: 180,
      protein: 6,
      carbs: 25,
      fats: 8,
      fiber: 7
    },
    tags: {
      meal_type: "Dinner",
      dietary: "Vegetarian",
      cuisine: "Asian",
      cooking_time: "20 minutes",
      cookware: ["Gas Stove", "Wok"]
    },
    source: "test",
    status: true,
    created_at: new Date().toISOString(),
    last_accessed: new Date().toISOString()
  };

  const testData = JSON.stringify(sampleRecipe);
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/recipes',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(testData),
    },
  };

  const req = http.request(options, (res) => {
    console.log(`\nInsert Recipe Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('Insert Recipe Response:', data);
      
      if (res.statusCode === 201) {
        console.log('✅ Successfully inserted sample recipe!');
        
        // Test getting all recipes
        testGetAllRecipes();
      } else {
        console.log('⚠️ Recipe might already exist or there was an error');
        // Continue with getting recipes anyway
        testGetAllRecipes();
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error inserting recipe:', error.message);
  });

  req.write(testData);
  req.end();
}

// Test getting all recipes
function testGetAllRecipes() {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/recipes',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const req = http.request(options, (res) => {
    console.log(`\nGet All Recipes Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('All Recipes Response:', JSON.stringify(JSON.parse(data), null, 2));
      
      if (res.statusCode === 200) {
        const recipes = JSON.parse(data);
        console.log(`✅ Found ${recipes.length} recipes!`);
        
        // Test getting a specific recipe if any exist
        if (recipes.length > 0) {
          testGetRecipeById(recipes[0]._id);
        }
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error getting recipes:', error.message);
  });

  req.end();
}

// Test getting a specific recipe by ID
function testGetRecipeById(recipeId) {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: `/api/recipes/${recipeId}`,
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const req = http.request(options, (res) => {
    console.log(`\nGet Recipe by ID Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('Recipe by ID Response:', JSON.stringify(JSON.parse(data), null, 2));
      
      if (res.statusCode === 200) {
        const recipe = JSON.parse(data);
        console.log('✅ Successfully retrieved recipe:', recipe.recipe_name);
        
        // Test recipe structure
        if (recipe.nutrition && recipe.nutrition.calories !== undefined) {
          console.log('✅ Recipe has nutrition data');
        }
        if (recipe.ingredients && Array.isArray(recipe.ingredients)) {
          console.log(`✅ Recipe has ${recipe.ingredients.length} ingredients`);
        }
        if (recipe.cooking_steps && Array.isArray(recipe.cooking_steps)) {
          console.log(`✅ Recipe has ${recipe.cooking_steps.length} cooking steps`);
        }
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error getting recipe by ID:', error.message);
  });

  req.end();
}

// Test getting user recommendations
function testRecommendations() {
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/recommendations/admin',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const req = http.request(options, (res) => {
    console.log(`\nRecommendations Status Code: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log('Recommendations Response:', JSON.stringify(JSON.parse(data), null, 2));
      
      if (res.statusCode === 200) {
        const recommendations = JSON.parse(data);
        console.log(`✅ Found ${recommendations.length} recipe recommendations!`);
      }
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error getting recommendations:', error.message);
  });

  req.end();
}

// Run all tests
console.log('🧪 Testing recipes functionality...');
testHealthCheck();

// Test recommendations after a delay
setTimeout(() => {
  console.log('\n🎯 Testing recommendations...');
  testRecommendations();
}, 2000);
