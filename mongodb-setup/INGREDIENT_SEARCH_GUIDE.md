# MongoDB Ingredient-Based Recipe Search Implementation

## Overview
This implementation adds fast ingredient-based recipe searching to the Aroma app's MongoDB database. The system allows users to select ingredients and quickly find matching recipes from previous sessions.

## Database Schema Changes

### Recipes Collection
Added a new field `needed_ingredients` to each recipe document:

```javascript
{
  "needed_ingredients": [
    "Chicken Breast",
    "Canned Tuna", 
    "Large Eggs",
    "Cherry Tomatoes",
    "Red Chili Powder"
  ]
}
```

### Indexes
Created a MongoDB index on the `needed_ingredients` field for optimal query performance:

```javascript
await recipesCollection.createIndex({ "needed_ingredients": 1 });
```

## Query Functions

### 1. findRecipesByIngredients(selectedIngredients, minMatchCount)
Finds recipes that match selected ingredients with flexibility.

**Parameters:**
- `selectedIngredients`: Array of ingredient names
- `minMatchCount`: Minimum number of ingredients that must match (default: 2)

**Returns:** Recipes sorted by match count and percentage

**Example:**
```javascript
const recipes = await findRecipesByIngredients(
  ["Chicken Breast", "Large Eggs"], 
  1
);
```

### 2. findExactIngredientMatches(selectedIngredients)
Finds recipes containing ALL selected ingredients.

**Parameters:**
- `selectedIngredients`: Array of ingredient names

**Returns:** Recipes with exact ingredient matches

**Example:**
```javascript
const exactMatches = await findExactIngredientMatches(
  ["Chicken Breast", "Large Eggs"]
);
```

### 3. getPopularIngredients(limit)
Gets most frequently used ingredients across all recipes.

**Parameters:**
- `limit`: Maximum number of ingredients to return (default: 20)

**Returns:** Array of ingredients with usage counts

**Example:**
```javascript
const popular = await getPopularIngredients(10);
```

### 4. updateRecipeAccessTime(recipeIds)
Updates the `last_accessed` timestamp for recipes (useful for analytics).

## Performance Optimization

### MongoDB Query Operators Used
- `$in`: Finds documents where the field matches any value in the specified array
- `$all`: Finds documents where the field contains all values in the specified array
- `$unwind`: Deconstructs array field to create separate documents
- `$group`: Groups documents by specified field expression
- `$sort`: Sorts documents in specified order

### Index Strategy
The `needed_ingredients` index enables:
- O(log n) lookup time for ingredient-based queries
- Efficient array containment checks
- Fast sorting and filtering operations

## Usage in Flutter App

### Backend API Integration
Create API endpoints that utilize these query functions:

```javascript
// Example Express.js endpoint
app.post('/api/recipes/by-ingredients', async (req, res) => {
  try {
    const { ingredients, minMatchCount } = req.body;
    const recipes = await findRecipesByIngredients(ingredients, minMatchCount);
    res.json(recipes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### Flutter Integration
```dart
// Example Flutter service call
Future<List<Recipe>> getRecipesByIngredients(List<String> ingredients) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/recipes/by-ingredients'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'ingredients': ingredients,
      'minMatchCount': 1
    }),
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Recipe.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load recipes');
  }
}
```

## Benefits

1. **Fast Retrieval**: Indexed queries provide millisecond response times
2. **Flexible Matching**: Support for partial and exact ingredient matching
3. **Scalable**: Efficient even with thousands of recipes
4. **User-Friendly**: Intuitive ingredient selection interface
5. **Analytics Ready**: Built-in tracking of ingredient popularity and usage

## Files Modified/Created

1. `setup-database.js` - Updated with `needed_ingredients` field and index
2. `ingredient-queries.js` - New utility functions for ingredient-based queries
3. `INGREDIENT_SEARCH_GUIDE.md` - This documentation file

## Testing

Run the test script to verify functionality:

```bash
cd mongodb-setup
node ingredient-queries.js
```

This will demonstrate:
- Finding recipes by selected ingredients
- Getting popular ingredients
- Query performance with indexed searches

## Future Enhancements

1. **Ingredient Suggestions**: Auto-suggest ingredients based on user history
2. **Smart Matching**: Implement fuzzy matching for ingredient names
3. **Caching**: Add Redis caching for frequently accessed recipes
4. **Personalization**: Weight recipes based on user preferences and history
5. **Seasonal Ingredients**: Filter recipes by seasonal ingredient availability
