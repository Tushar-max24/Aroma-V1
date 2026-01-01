import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../core/utils/category_engine.dart';
import '../../../core/utils/item_image_resolver.dart';
import 'shopping_list_screen.dart';

class LowStockItemsScreen extends StatefulWidget {
  const LowStockItemsScreen({Key? key}) : super(key: key);

  @override
  State<LowStockItemsScreen> createState() => _LowStockItemsScreenState();
}

class _LowStockItemsScreenState extends State<LowStockItemsScreen> {
  Set<String> selectedItems = {};
  Map<String, double> itemQuantities = {};
  Map<String, String> itemUnits = {};

  // ---------------- TOGGLE ITEM ----------------
  void _toggleItemSelection(
    String itemName,
    double quantity,
    String unit,
  ) {
    if (selectedItems.contains(itemName)) {
      setState(() {
        selectedItems.remove(itemName);
        itemQuantities.remove(itemName);
        itemUnits.remove(itemName);
      });
    } else {
      setState(() {
        selectedItems.add(itemName);
        itemQuantities[itemName] = quantity;
        itemUnits[itemName] = unit;
      });
    }
  }

  // ---------------- ADD TO SHOPPING LIST ----------------
  void _addItemsToShoppingList() {
    final shoppingService =
        Provider.of<ShoppingListService>(context, listen: false);

    for (final name in selectedItems) {
      shoppingService.addItem(
        name: name,
        quantity: itemQuantities[name] ?? 1,
        unit: itemUnits[name] ?? 'pcs',
        category: CategoryEngine.getCategory(name),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ShoppingListScreen(),
      ),
    );
  }
  

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // 🔥 LIVE PANTRY DATA
    final pantry = context.watch<PantryState>();

    final lowStockItems = pantry.pantryQty.entries
        .where((e) => e.value > 0 && e.value <= 3)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Low Stock Items",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              if (selectedItems.isNotEmpty)
                const SizedBox(height: 56),

              Expanded(
                child: lowStockItems.isEmpty
                    ? const Center(
                        child: Text("No low stock items 🎉"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lowStockItems.length,
                        itemBuilder: (context, index) {
                          final item = lowStockItems[index];
                          final name = item.key;
                          final qty = item.value;
                          final unit = 'pcs'; // default

                          final isSelected =
                              selectedItems.contains(name);

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                child: ItemImageResolver.getImageWidget(
                                  name,
                                  size: 40,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600),
                              ),
                              subtitle: Text(
                                'in ${CategoryEngine.getCategory(name)}'
                                ' | Avl Qty: $qty $unit',
                                style:
                                    const TextStyle(fontSize: 13),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons
                                          .shopping_cart_outlined,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                onPressed: () =>
                                    _toggleItemSelection(
                                  name,
                                  qty,
                                  unit,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ---------------- TOP BAR ----------------
          if (selectedItems.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF1E8),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Added to shopping list : ${selectedItems.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500),
                    ),
                    OutlinedButton(
                      onPressed: _addItemsToShoppingList,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Finish Adding',
                        style: TextStyle(
                            color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
