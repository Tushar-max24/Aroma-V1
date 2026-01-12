# IP Address Change Checklist - Aroma App

## 🎯 **When IPs Change, Update These Files:**

---

## 📊 **MongoDB Connection Files**

### 1. **MongoDB Service** (PRIMARY)
**File:** `lib/data/services/mongo_ingredient_service.dart`
**Line 6:** `static const String _baseUrl = "http://CURRENT_IP:3000";`
**Purpose:** Main MongoDB API connection

### 2. **MongoDB Server** (PRIMARY)
**File:** `mongodb-setup/server.js`
**Line 363:** `console.log(\`🌐 External Access: http://CURRENT_IP:\${PORT}/api\`);`
**Purpose:** Server startup message with external IP

---

## 🔌 **Backend API Files**

### 3. **Scan Bill Service** (PRIMARY)
**File:** `lib/data/services/scan_bill_service.dart`
**Line 9:** `Uri.parse("http://API_IP:5002/detect-image-qty")`
**Purpose:** Bill/ingredient scanning API

### 4. **Generate Recipe Service** (PRIMARY)
**File:** `lib/data/services/generate_recipe_service.dart`
**Line 8:** `static const String _recipeUrl = "http://API_IP:5002/generate-recipes-ingredient";`
**Line 9:** `static const String _imageUrl = "http://API_IP:5002/generate-dish-image";`
**Purpose:** Recipe and image generation API

### 5. **Pantry Add Service** (PRIMARY)
**File:** `lib/data/services/pantry_add_service.dart`
**Line 9:** `baseUrl: "http://API_IP:5002"`
**Purpose:** Pantry ingredient scanning and processing

---

## 🌐 **Environment Configuration**

### 6. **Environment Variables** (IF EXISTS)
**File:** `mongodb-setup/.env`
**Content:** `MONGODB_URI=mongodb+srv://...`
**Purpose:** MongoDB Atlas connection string

---

## 📱 **UI Files** (NO CHANGES NEEDED - They use services above)

These files call the services but don't need IP changes:
- `lib/ui/screens/add_ingredients/capture_preview_screen.dart`
- `lib/ui/screens/add_ingredients/review_ingredients_screen.dart`
- `lib/ui/screens/pantry/pantry_review_ingredients_screen.dart`
- `lib/ui/screens/add_ingredients/review_ingredients_list_screen.dart`
- `lib/ui/screens/pantry/review_items_screen.dart`
- `lib/ui/screens/test_mongo_screen.dart`

---

## 🔧 **Quick Change Summary**

### **When MongoDB IP Changes:**
```dart
// lib/data/services/mongo_ingredient_service.dart - Line 6
static const String _baseUrl = "http://NEW_MONGODB_IP:3000";

// mongodb-setup/server.js - Line 363
console.log(`🌐 External Access: http://NEW_MONGODB_IP:${PORT}/api`);
```

### **When API IP Changes:**
```dart
// lib/data/services/scan_bill_service.dart - Line 9
Uri.parse("http://NEW_API_IP:5002/detect-image-qty")

// lib/data/services/generate_recipe_service.dart - Lines 8-9
static const String _recipeUrl = "http://NEW_API_IP:5002/generate-recipes-ingredient";
static const String _imageUrl = "http://NEW_API_IP:5002/generate-dish-image";

// lib/data/services/pantry_add_service.dart - Line 9
baseUrl: "http://NEW_API_IP:5002"
```

---

## 📋 **Current Working IPs (For Reference)**

### **MongoDB Server:**
- **IP:** `192.168.137.1`
- **Port:** `3000`
- **Endpoint:** `http://192.168.137.1:3000/api`

### **Backend API Server:**
- **IP:** `192.168.137.150`
- **Port:** `5002`
- **Endpoints:** 
  - `http://192.168.137.150:5002/detect-image-qty`
  - `http://192.168.137.150:5002/generate-recipes-ingredient`
  - `http://192.168.137.150:5002/generate-dish-image`

---

## 🚀 **Testing After IP Changes**

### **Test MongoDB Connection:**
```bash
cd mongodb-setup
node test-connection-new.js
```

### **Test API Endpoints:**
```bash
# Test scan API
curl -X POST "http://NEW_API_IP:5002/detect-image-qty" -F "image=@test.jpg"

# Test recipe API
curl -X POST "http://NEW_API_IP:5002/generate-recipes-ingredient" -H "Content-Type: application/json" -d '{"ingredients":["chicken"],"preferences":{}}'
```

### **Test in Flutter App:**
1. Scan a bill/image
2. Check console for successful API calls
3. Verify ingredients are stored in MongoDB
4. Test recipe generation

---

## ⚠️ **Important Notes**

1. **Port Numbers:** MongoDB uses `3000`, API uses `5002` - don't mix these up
2. **Service Files:** Only change the 5 primary files listed above
3. **UI Files:** Automatically use updated services - no changes needed
4. **Environment:** Check `.env` file if MongoDB Atlas connection fails
5. **Network:** Ensure new IPs are accessible from your device/emulator

---

## 🔄 **Change Process**

1. **Update MongoDB IP** (2 files)
2. **Update API IP** (3 files)
3. **Restart servers** if needed
4. **Test connections** with provided commands
5. **Test in Flutter app** with real scanning

**Total Files to Change: 5** (3 for API, 2 for MongoDB)
