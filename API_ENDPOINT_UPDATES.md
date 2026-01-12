# API Endpoint Updates - Aroma App

## Updated API Server
**New Base URL:** `http://192.168.137.150:5002`

## Services Updated

### 1. ScanBillService (`lib/data/services/scan_bill_service.dart`)
- **Endpoint:** `http://192.168.137.150:5002/detect-image-qty`
- **Purpose:** Scan bills/receipts to detect ingredients and quantities
- **Method:** `scanBill(XFile image)`
- **Status:** ✅ Updated

### 2. GenerateRecipeService (`lib/data/services/generate_recipe_service.dart`)
- **Recipe Generation Endpoint:** `http://192.168.137.150:5002/generate-recipes-ingredient`
- **Image Generation Endpoint:** `http://192.168.137.150:5002/generate-dish-image`
- **Methods:** 
  - `generateRecipes(ingredients, preferences)`
  - `generateDishImage(dishName)`
- **Status:** ✅ Updated

### 3. PantryAddService (`lib/data/services/pantry_add_service.dart`)
- **Base URL:** `http://192.168.137.150:5002`
- **Methods:**
  - `scanPantryImage(XFile image)` - NEW: Image-based pantry scanning
  - `processRawText(String rawText)` - Process scanned bill text
  - `saveToPantry(items, isUpdate)` - Save/update pantry items
- **Endpoints:**
  - `/detect-image-qty` - For image scanning
  - `/pantry/add` - For text processing
- **Status:** ✅ Updated with new image scanning capability

## API Usage Examples

### Bill Scanning
```dart
final scanService = ScanBillService();
final result = await scanService.scanBill(imageFile);
// Returns detected ingredients with quantities
```

### Pantry Image Scanning (NEW)
```dart
final pantryService = PantryAddService();
final result = await pantryService.scanPantryImage(imageFile);
// Returns detected ingredients from pantry image
```

### Recipe Generation
```dart
final recipeService = GenerateRecipeService();
final recipes = await recipeService.generateRecipes(
  ['Chicken', 'Tomatoes'],
  {'meal_type': 'Lunch', 'difficulty': 'Easy'}
);
```

### Dish Image Generation
```dart
final recipeService = GenerateRecipeService();
final image = await recipeService.generateDishImage('Spicy Chicken Curry');
// Returns image URL or base64 image data
```

## Benefits of New API Server

1. **Unified Endpoint:** All ingredient scanning and recipe generation on one server
2. **Enhanced Pantry Scanning:** Now supports image-based pantry ingredient detection
3. **Consistent API Responses:** Standardized response formats across all services
4. **Improved Performance:** Single server location for reduced latency
5. **Simplified Configuration:** One base URL to manage

## Migration Notes

- All services now point to `192.168.137.150:5002`
- PantryAddService has been enhanced with image scanning capability
- Existing method signatures remain unchanged for backward compatibility
- Error handling and timeout configurations are maintained

## Testing Recommendations

1. Test bill scanning with receipt images
2. Test pantry scanning with ingredient images
3. Verify recipe generation with various ingredient combinations
4. Test image generation for different dish names
5. Validate error handling for network issues

## Network Configuration

Ensure the device/emulator can access `192.168.137.150:5002`:
- Check network connectivity
- Verify firewall settings
- Confirm the API server is running and accessible
- Test with tools like Postman or curl before app integration
