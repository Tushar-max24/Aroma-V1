import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'pantry_empty_screen.dart';
import 'low_stock_items_screen.dart';
import 'shopping_list_screen.dart';
import 'category_items_screen.dart';
import 'pantry_item_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import 'pantry_search_add_screen.dart';


const Color kAccent = Color(0xFFFF7A4A);
const Color kLightAccent = Color(0xFFFFE8E0);

class PantryHomeScreen extends StatefulWidget {
  const PantryHomeScreen({super.key});

  @override
  State<PantryHomeScreen> createState() => _PantryHomeScreenState();
}

class _PantryHomeScreenState extends State<PantryHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load pantry state when the screen initializes
    final pantryState = Provider.of<PantryState>(context, listen: false);
    pantryState.loadPantry();
  }
  Future<String?> _getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }


  // Get pantry items from state
  List<Map<String, dynamic>> get pantryItems {
    final pantryState = Provider.of<PantryState>(context);
    return pantryState.items.map((item) => {
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'imageUrl': item.imageUrl, // Include imageUrl
    }).toList();
  }

  // Get low stock item count
  int get lowStockItemCount {
    return pantryItems.where((item) {
      final qty = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 0;
      return qty > 0 && qty <= 3;
    }).length;
  }

  // ---------- CATEGORY ----------
  Map<String, List<Map<String, dynamic>>> get groupedItems {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final item in pantryItems) {
      final category = CategoryEngine.getCategory(item['name']);
      map.putIfAbsent(category, () => []);
      map[category]!.add(item);
    }
    return map;
  }


  @override
  Widget build(BuildContext context) {
    if (pantryItems.isEmpty) {
      return const PantryEmptyScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () {
      // Navigate directly to home screen, clearing the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(phoneNumber: ''),
        ),
        (route) => false, // Remove all previous routes
      );
    },
  ),
        title: const Text(
          "Pantry",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- SEARCH ----------
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantrySearchAddScreen(),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Items",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

                      // ---------- INFO CARDS ----------
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShoppingListScreen(),
                        ),
                      );
                    },
                    child: Consumer<ShoppingListService>(
  builder: (_, shoppingService, __) {
    return _infoCard(
      shoppingService.items.length.toString(),
      "items",
      "in shopping list",
    );
  },
),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LowStockItemsScreen(),
                        ),
                      );
                    },
                    child: _infoCard(
                      lowStockItemCount.toString(),
                      "items",
                      "in low stock",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------- CATEGORIES ----------
            ...groupedItems.entries.map((e) {
              return _categorySection(
                title: e.key,
                items: e.value,
              );
            }),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccent,
        onPressed: () {
          // Navigate to pantry empty screen, replacing current route
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PantryEmptyScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Items"),
      ),
    );
  }

  // ---------- UI COMPONENTS ----------

  Widget _infoCard(String count, String label1, String label2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: kLightAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: const TextStyle(
              color: kAccent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              children: [
                TextSpan(text: label1, style: const TextStyle(fontWeight: FontWeight.w600)),
                const TextSpan(text: " "),
                TextSpan(text: label2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection({
  required String title,
  required List<Map<String, dynamic>> items,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ✅ SEE ALL BUTTON (FIXED)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryItemsScreen(
          category: title, // 🔥 PASS CATEGORY NAME
          allItems: pantryItems,
                  ),
                ),
              );
            },
            child: const Text(
              'All →',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      SizedBox(
        height: 140, // Increased from 120 to 140
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final item = items[index];
            return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantryItemDetailsScreen(item: item),
        ),
      );
    },
    child: _itemCard(item),
  );
          },
        ),
      ),

      const SizedBox(height: 24),
    ],
  );
}


  Widget _itemCard(Map<String, dynamic> item) {
  return Container(
    width: 150, // Increased from 130 to 150
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image takes most of the space
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item['imageUrl'] != null
                  ? Image.network(
                      item['imageUrl'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain, // Changed from cover to contain
                      errorBuilder: (_, __, ___) => 
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.restaurant, size: 35, color: Colors.grey),
                      ),
                    )
                : ItemImageResolver.getImageWidget(
                    item['name'],
                    size: 80, // Reduced from 100
                    imageUrl: item['imageUrl'],
                  ),
            ),
          ),
        const SizedBox(height: 8),
        // Name takes minimal space
        Text(
          item['name'],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        // Add to shopping list button - compact with toggle state
        Consumer<ShoppingListService>(
          builder: (_, shoppingService, __) {
            final isAdded = shoppingService.isAdded(item['name']);
            return GestureDetector(
              onTap: () => isAdded ? _removeFromShoppingList(item) : _addToShoppingList(item),
              child: Container(
                width: double.infinity,
                height: 28, // Increased from 26
                decoration: BoxDecoration(
                  color: isAdded ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAdded ? Colors.green.shade300 : Colors.orange.shade300, 
                    width: 0.5
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAdded ? Icons.check_circle_outline : Icons.shopping_cart_outlined,
                      size: 14, // Increased from 13
                      color: isAdded ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isAdded ? 'Added' : 'Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAdded ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

  // ---------------- ADD TO SHOPPING LIST ----------------
  void _addToShoppingList(Map<String, dynamic> item) {
    debugPrint('=== PantryHomeScreen._addToShoppingList ===');
    debugPrint('Adding item: ${item['name']}');
    
    final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
    final pantry = Provider.of<PantryState>(context, listen: false);
    
    // Get item details
    final name = item['name'] as String;
    final quantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 1.0;
    final unit = pantry.pantryUnit[name] ?? 'pcs';
    final category = CategoryEngine.getCategory(name);
    final imageUrl = pantry.pantryImages[name] ?? '';
    
    debugPrint('  - Name: $name');
    debugPrint('  - Quantity: $quantity');
    debugPrint('  - Unit: $unit');
    debugPrint('  - Category: $category');
    
    shoppingService.addItem(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      imageUrl: imageUrl,
    );
    
    debugPrint('✅ Item added to shopping list');
    debugPrint('==============================');
  }

  // ---------------- REMOVE FROM SHOPPING LIST ----------------
  void _removeFromShoppingList(Map<String, dynamic> item) {
    debugPrint('=== PantryHomeScreen._removeFromShoppingList ===');
    debugPrint('Removing item: ${item['name']}');
    
    final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
    final name = item['name'] as String;
    
    shoppingService.removeItem(name);
    
    debugPrint('✅ Item removed from shopping list');
    debugPrint('==============================');
  }
}
