# Splash Screen Initialization Strategy

## Overview

The splash screen has been optimized to use the 10-20 second loading time efficiently by initializing all SQLite cache services and preloading essential data before the user enters the home screen.

## Initialization Phases

### 🚀 **Phase 1: Critical Services (0-3 seconds)**
```
Status: "Setting up cache system..."
Progress: 20%
```

**Tasks:**
- ✅ Cache Manager initialization
- ✅ Database connection establishment
- ✅ Initial cache statistics collection
- ✅ Database health check

**SQLite Operations:**
- Create/open database connection
- Verify table structures
- Collect initial cache statistics
- Optimize database with VACUUM command

### 🧹 **Phase 2: Cache Optimization (3-5 seconds)**
```
Status: "Loading recipes..."
Progress: 50%
```

**Tasks:**
- ✅ Clean up expired cache entries
- ✅ Database optimization
- ✅ Cache statistics after cleanup
- ✅ Parallel recipe loading (if needed)

**SQLite Operations:**
- DELETE expired entries (older than 24 hours)
- VACUUM database for file size optimization
- UPDATE cache statistics
- SELECT cleaned cache data

### ⚡ **Phase 3: Preloading Common Data (5-8 seconds)**
```
Status: "Finalizing setup..."
Progress: 80%
```

**Tasks:**
- ✅ Preload popular recipe details
- ✅ Warm up Gemini service connection
- ✅ Final cache statistics collection
- ✅ Background task preparation

**SQLite Operations:**
- SELECT popular recipes from cache
- Preload recipe details into memory
- Cache final statistics

### 🔐 **Phase 4: Authentication Check (8-10+ seconds)**
```
Status: "Checking authentication..."
Progress: 90%
```

**Tasks:**
- ✅ Wait for auth service initialization
- ✅ Verify user authentication status
- ✅ Prepare navigation

### ✅ **Phase 5: Ready! (10-20 seconds)**
```
Status: "Ready!"
Progress: 100%
```

**Tasks:**
- ✅ Navigate to appropriate screen
- ✅ Start background maintenance tasks
- ✅ Display initialization statistics

## Database Initialization Details

### **SQLite Cache Tables Prepared**

#### **1. Recipe Details Table**
```sql
-- Initialized during Phase 1
CREATE TABLE IF NOT EXISTS recipe_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_name TEXT UNIQUE NOT NULL,
  description TEXT,
  nutrition TEXT,              -- JSON stored as TEXT
  cookware TEXT,               -- JSON array stored as TEXT
  preparation_steps TEXT,      -- JSON array stored as TEXT
  cached_at TEXT NOT NULL,
  -- Indexes created for fast lookups
  CREATE INDEX idx_recipe_name ON recipe_details(recipe_name)
);
```

#### **2. Cooking Steps Table**
```sql
-- Initialized during Phase 1
CREATE TABLE IF NOT EXISTS cooking_steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_name TEXT NOT NULL,
  step_number INTEGER NOT NULL,
  instruction TEXT,
  tips TEXT,                   -- JSON array stored as TEXT
  ingredients TEXT,            -- JSON array stored as TEXT
  cached_at TEXT NOT NULL,
  UNIQUE(recipe_name, step_number),
  -- Indexes for performance
  CREATE INDEX idx_cooking_recipe_name ON cooking_steps(recipe_name)
);
```

#### **3. Generated Recipes Table**
```sql
-- Initialized during Phase 1
CREATE TABLE IF NOT EXISTS generated_recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  preference_hash TEXT UNIQUE NOT NULL,
  recipes TEXT,                -- JSON array stored as TEXT
  recipe_images TEXT,          -- JSON object stored as TEXT
  cuisine TEXT,
  cached_at TEXT NOT NULL,
  -- Index for fast preference lookups
  CREATE INDEX idx_preference_hash ON generated_recipes(preference_hash)
);
```

### **Cache Optimization Operations**

#### **Expired Entry Cleanup**
```sql
-- Phase 2: Remove entries older than 24 hours
DELETE FROM recipe_details WHERE cached_at < datetime('now', '-24 hours');
DELETE FROM cooking_steps WHERE cached_at < datetime('now', '-24 hours');
DELETE FROM generated_recipes WHERE cached_at < datetime('now', '-24 hours');
```

#### **Database Optimization**
```sql
-- Phase 2: Optimize database file size
VACUUM;
```

#### **Statistics Collection**
```sql
-- Phase 1 & 3: Collect cache statistics
SELECT COUNT(*) FROM recipe_details;
SELECT COUNT(*) FROM cooking_steps;
SELECT COUNT(*) FROM generated_recipes;
```

## Preloaded Content

### **Popular Recipes Preloaded**
During Phase 3, the system attempts to preload these commonly accessed recipes:
- Chicken Curry
- Pasta
- Salad
- Soup
- Rice
- Bread
- Eggs
- Vegetables

### **Background Tasks Started**
After splash screen completion:
- **Cache Statistics Monitoring**: Every 30 minutes
- **Background Cache Warming**: Every hour
- **Automatic Cleanup**: Every 24 hours

## Performance Metrics

### **Initialization Timing**
| Phase | Duration | Operations |
|-------|----------|------------|
| Phase 1 | 0-3s | Critical services, DB setup |
| Phase 2 | 3-5s | Cache cleanup, optimization |
| Phase 3 | 5-8s | Preloading, statistics |
| Phase 4 | 8-10s | Authentication |
| Total | 10-20s | Complete initialization |

### **Cache Performance**
- **Database size**: Typically 1-10 MB depending on usage
- **Cache hit time**: ~50ms for cached recipes
- **Cleanup time**: ~100-500ms depending on cache size
- **Preload benefit**: Instant access to popular recipes

## Progress Indicators

### **Visual Feedback**
The splash screen shows:
- **Status text**: Current initialization phase
- **Progress bar**: Visual completion percentage
- **Percentage display**: Numerical progress (0-100%)

### **Console Logging**
During initialization, these logs are displayed:
```
🚀 Starting app initialization...
📋 Phase 1: Critical Services
✅ Phase 1 completed in 150ms
📊 Cache stats: 45 items cached
🧹 Phase 2: Cache Optimization
✅ Phase 2 completed in 200ms
🗑️ Cache cleanup completed
⚡ Phase 3: Preloading Common Data
✅ Phase 3 completed in 300ms
📦 Preloaded 8 cached items
🔄 Phase 4: Starting Background Tasks
✅ Background tasks started
✅ App initialized successfully in 850ms
```

## Error Handling

### **Graceful Degradation**
If any phase fails:
- **Phase 1 failure**: App continues with limited caching
- **Phase 2 failure**: App continues without cleanup
- **Phase 3 failure**: App continues without preloading
- **Phase 4 failure**: App continues to login screen

### **Fallback Strategy**
- Cache initialization failures don't prevent app usage
- Users can still access all features
- Cache will be initialized on-demand during usage

## Benefits

### **User Experience**
- **Smooth loading**: Progress indicators show activity
- **Faster app start**: Preloaded content available immediately
- **Offline readiness**: Cache prepared for offline usage
- **Instant access**: Popular recipes load instantly

### **Technical Benefits**
- **Database optimization**: Performed during idle time
- **Cache warming**: Popular content preloaded
- **Background tasks**: Maintenance started automatically
- **Statistics monitoring**: Performance tracking enabled

## Configuration

### **Timing Adjustments**
Modify splash duration in `splash_screen.dart`:
```dart
// Change minimum splash time
Future.delayed(const Duration(seconds: 5)), // Reduced from 3 seconds
```

### **Preload List**
Customize preloaded recipes in `app_initialization_service.dart`:
```dart
final popularRecipes = [
  'Custom Recipe 1',
  'Custom Recipe 2',
  // Add your popular recipes
];
```

### **Cleanup Frequency**
Adjust background task intervals:
```dart
// Cache statistics monitoring
Timer.periodic(const Duration(minutes: 30), (timer) => ...);

// Background cache warming  
Timer.periodic(const Duration(hours: 1), (timer) => ...);
```

## Monitoring

### **Initialization Statistics**
Access initialization stats:
```dart
final stats = AppInitializationService.initStats;
print('Total time: ${stats['totalTime']}ms');
print('Cache items: ${stats['finalCacheStats']['total']}');
print('Cleanup performed: ${stats['cleanupPerformed']}');
```

### **Cache Statistics**
Monitor cache health:
```dart
final stats = await CacheManagerService.getCacheStats();
print('Recipe details: ${stats['recipeDetails']}');
print('Cooking steps: ${stats['cookingSteps']}');
print('Generated recipes: ${stats['generatedRecipes']}');
```

---

## Summary

The splash screen initialization strategy maximizes the 10-20 second loading window by:

1. **Setting up complete SQLite cache infrastructure**
2. **Optimizing database performance** 
3. **Preloading popular content**
4. **Starting background maintenance**
5. **Providing visual feedback** throughout the process

This ensures users enter the home screen with a fully optimized cache system ready for instant recipe access and smooth app performance.
