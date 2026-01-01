# Recipe Caching Flow Diagram

## 🔄 **Generated Recipes Caching Flow**

### **User Action**: Select ingredients & preferences → Generate recipes

```
┌─────────────────────────────────────────────────────────────┐
│                    RECIPE LIST SCREEN                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Check Cache First                                   │
│  RecipeCacheRepository.getCachedGeneratedRecipes()          │
│                                                             │
│  ┌─────────────────┐                                        │
│  │   SQLite DB     │ ← Check if preferences+ingredients     │
│  │   (24hr expiry) │   combination exists in cache         │
│  └─────────────────┘                                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
                ┌─────────┐
                │Cache Hit?│
                └─────┬───┘
                      │
               ┌──────┴──────┐
               │             │
               ▼             ▼
┌─────────────────────┐ ┌─────────────────────┐
│   YES (Cache Hit)   │ │    NO (Cache Miss)  │
│                     │ │                     │
│ ✅ Return instantly │ │ 🔄 Fetch from       │
│    cached data      │ │    backend API      │
│                     │ │                     │
│ ⚡ Instant loading  │ │ PreferenceApiService │
│                     │ │    .generateRecipes()│
└─────────┬───────────┘ └─────────┬───────────┘
          │                       │
          ▼                       ▼
┌─────────────────────┐ ┌─────────────────────┐
│   Display recipes   │ │   Store in DB       │
│   instantly         │ │   (cache result)    │
└─────────────────────┘ │   24-hour expiry    │
                         └─────────┬───────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │   Return fresh data  │
                         │   (now cached)       │
                         └─────────┬───────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │   Display recipes   │
                         │   (first time)      │
                         └─────────────────────┘
```

## 📖 **Recipe Details Caching Flow**

### **User Action**: Tap on recipe → View details

```
┌─────────────────────────────────────────────────────────────┐
│                   RECIPE DETAIL SCREEN                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Check Cache First                                   │
│  RecipeCacheRepository.getRecipeDetails(recipeName)          │
│                                                             │
│  ┌─────────────────┐                                        │
│  │   SQLite DB     │ ← Check if recipe name exists         │
│  │   (24hr expiry) │   in cache                              │
│  └─────────────────┘                                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
                ┌─────────┐
                │Cache Hit?│
                └─────┬───┘
                      │
               ┌──────┴──────┐
               │             │
               ▼             ▼
┌─────────────────────┐ ┌─────────────────────┐
│   YES (Cache Hit)   │ │    NO (Cache Miss)  │
│                     │ │                     │
│ ✅ Return instantly │ │ 🔄 Fetch from       │
│    cached data      │ │    Gemini API       │
│                     │ │                     │
│ ⚡ Instant loading  │ │ GeminiRecipeService │
│    (description,    │ │    .fetchRecipeData()│
│    nutrition,       │ │                     │
│    cookware,        │ │                     │
│    steps)           │ │                     │
└─────────┬───────────┘ └─────────┬───────────┘
          │                       │
          ▼                       ▼
┌─────────────────────┐ ┌─────────────────────┐
│   Display details   │ │   Store in DB       │
│   instantly         │ │   (cache result)    │
└─────────────────────┘ │   24-hour expiry    │
                         └─────────┬───────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │   Return fresh data  │
                         │   (now cached)       │
                         └─────────┬───────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │   Display details   │
                         │   (first time)      │
                         └─────────────────────┘
```

## 🎯 **Key Benefits**

### **First Time (Cache Miss)**
```
User generates recipes → Backend call (2-5 seconds) → Cache result → Display
User views recipe details → Gemini call (2-5 seconds) → Cache result → Display
```

### **Subsequent Times (Cache Hit)**
```
User generates same recipes → Instant from cache (~50ms) → Display
User views same recipe → Instant from cache (~50ms) → Display
```

### **Next Session (Within 24 Hours)**
```
Same ingredients+preferences → Instant from cache (~50ms)
Same recipe name → Instant from cache (~50ms)
```

## 📊 **Cache Keys**

### **Generated Recipes Cache**
- **Key**: SHA256 hash of (preferences + ingredients)
- **Duration**: 24 hours
- **Data**: Recipe list, cuisine, images

### **Recipe Details Cache**
- **Key**: Recipe name (string)
- **Duration**: 24 hours
- **Data**: Description, nutrition, cookware, steps

### **Cooking Steps Cache**
- **Key**: Recipe name + step number
- **Duration**: 24 hours
- **Data**: Instruction, tips, ingredients per step

## 🔧 **Cache Management**

### **Automatic Cleanup**
- **Frequency**: Every 24 hours
- **Action**: Remove entries older than 24 hours
- **Trigger**: Background timer in CacheManagerService

### **Manual Cleanup**
```dart
// Clear all cache
await CacheManagerService.clearAllCache();

// Clear expired entries only
await CacheManagerService.forceCleanup();
```

## 📱 **User Experience**

### **Console Logs**
```
✅ Generated recipes loaded from cache (5 recipes)
🔄 No cache found, fetching from backend
📋 Backend returned 5 recipes and cached them
✅ Recipe details loaded from cache: Chicken Curry
🔄 Fetching recipe details from Gemini: Pasta Recipe
✅ Recipe details cached: Pasta Recipe
```

### **Performance Impact**
- **Cache Hit**: ~50ms loading time
- **Cache Miss**: 2-5 seconds (normal API time)
- **Storage**: Minimal (few KB per recipe)
- **Battery**: Reduced (fewer API calls)

---

## 🎉 **Result**

The caching system now perfectly follows the optimized flow:

1. **Check cache first** → If found, return instantly
2. **If cache miss** → Fetch from backend → Store in cache → Return
3. **Future requests** → Instant cache hits within 24 hours

This provides the best user experience with instant loading for repeated content while ensuring fresh data when needed!
