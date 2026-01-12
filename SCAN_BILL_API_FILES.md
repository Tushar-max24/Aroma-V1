# Scan Bill API Files - Change Checklist

## When New API is Provided, Update These Files:

### 🔧 **Core Service Files** (MUST CHANGE)

1. **`lib/data/services/scan_bill_service.dart`**
   - **Line 9:** `Uri.parse("http://192.168.137.150:5002/detect-image-qty")`
   - **Method:** `scanBill(XFile image)`
   - **Purpose:** Main API call for bill scanning

### 📱 **UI Screen Files** (Use ScanBillService - Verify Integration)

2. **`lib/ui/screens/add_ingredients/capture_preview_screen.dart`**
   - **Line 96:** `final scanResult = await ScanBillService().scanBill(file);`
   - **Line 287:** `final scanResult = await ScanBillService().scanBill(image);`

3. **`lib/ui/screens/add_ingredients/review_ingredients_screen.dart`**
   - **Line 57:** `final result = await ScanBillService().scanBill(widget.capturedImage!);`

4. **`lib/ui/screens/pantry/pantry_review_ingredients_screen.dart`**
   - **Line 56:** `final result = await ScanBillService().scanBill(widget.capturedImage!);`

### 🗄️ **Database Storage Files** (Store Scan Results)

5. **`lib/data/services/mongo_ingredient_service.dart`**
   - **Line 271:** `storeScanBillIngredients()` method
   - **Purpose:** Stores scan results in MongoDB

6. **`lib/ui/screens/add_ingredients/review_ingredients_list_screen.dart`**
   - **Line 302:** `await MongoIngredientService.storeScanBillIngredients(scanIngredients);`

7. **`lib/ui/screens/pantry/review_items_screen.dart`**
   - **Line 113:** `await MongoIngredientService.storeScanBillIngredients(reviewItems, source: "pantry");`

8. **`lib/ui/screens/pantry/pantry_review_ingredients_screen.dart`**
   - **Line 899:** `await MongoIngredientService.storeScanBillIngredients(scanIngredients, source: "pantry");`

### 🧪 **Test Files** (For Testing)

9. **`lib/ui/screens/test_mongo_screen.dart`**
   - **Line 91:** `await MongoIngredientService.storeScanBillIngredients([testIngredient]);`
   - **Line 128:** `await MongoIngredientService.storeScanBillIngredients(testIngredients);`

---

## 📋 **Quick Change Summary**

### **Primary Change Required:**
```dart
// In scan_bill_service.dart, line 9
Uri.parse("NEW_API_ENDPOINT/detect-image-qty")
```

### **Files That Use the Service:**
- ✅ **Service File:** `scan_bill_service.dart` (CHANGE THIS)
- ✅ **UI Files:** 4 screen files (NO CHANGE NEEDED - they call the service)
- ✅ **Storage Files:** 3 files handle results (NO CHANGE NEEDED)
- ✅ **Test Files:** 1 test file (NO CHANGE NEEDED)

---

## 🎯 **What to Update When API Changes**

### **Step 1: Update the Service**
```dart
// lib/data/services/scan_bill_service.dart
class ScanBillService {
  Future<dynamic> scanBill(XFile image) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("NEW_API_ENDPOINT_HERE"), // 🔧 CHANGE THIS LINE
    );
    // ... rest of the code
  }
}
```

### **Step 2: Test the Integration**
All other files automatically use the updated service, no changes needed:
- UI screens call `ScanBillService().scanBill()`
- Storage services receive scan results
- Test files verify functionality

### **Step 3: Verify Endpoints**
Make sure the new API supports:
- **Method:** POST
- **Endpoint:** `/detect-image-qty`
- **Input:** Multipart form data with image file
- **Output:** JSON with ingredient detection results

---

## 📊 **Impact Assessment**

- **Files to Modify:** 1 (scan_bill_service.dart)
- **Files Affected:** 9 total
- **Breaking Changes:** None (same method signature)
- **Testing Required:** UI integration with new API
