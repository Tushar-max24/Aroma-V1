import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/pantry_state.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../data/services/ingredient_metrics_service.dart';
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
  final IngredientMetricsService _metricsService = IngredientMetricsService();
  bool _metricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadPantryData();
  }

  Future<void> _loadPantryData() async {
    // Add a small delay to ensure pantry state is loaded
    await Future.delayed(const Duration(milliseconds: 100));
    final pantryState = Provider.of<PantryState>(context, listen: false);
    await pantryState.loadPantry();
    debugPrint('LowStockScreen: Force loading pantry data...');
    debugPrint('LowStockScreen: Pantry items count: ${pantryState.pantryQty.length}');
  }

  Future<void> _loadMetrics() async {
    await _metricsService.loadMetrics();
    setState(() {
      _metricsLoaded = true;
    });
  }

  // ---------------- EDIT ITEM ----------------
  Future<void> _editItem(String name, double currentQuantity, String currentUnit) async {
    final quantityController = TextEditingController(text: currentQuantity.toString());
    final unitController = TextEditingController(text: currentUnit);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                hintText: "Enter quantity"
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: "Unit/Metric",
                hintText: "e.g., kg, g, pcs, liters",
                helperText: "Suggested: ${_metricsService.getMetricsForIngredient(name)}",
                helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = double.tryParse(quantityController.text) ?? currentQuantity;
              String newUnit = unitController.text.trim().isNotEmpty ? unitController.text.trim() : currentUnit;
              
              // If user didn't enter a unit, use the suggested metric
              if (newUnit == currentUnit && unitController.text.trim().isEmpty) {
                final suggestedMetric = _metricsService.getMetricsForIngredient(name);
                if (suggestedMetric.isNotEmpty) {
                  newUnit = suggestedMetric;
                }
              }
              
              if (newQuantity > 0 && newUnit.isNotEmpty) {
                final pantryState = Provider.of<PantryState>(context, listen: false);
                pantryState.setItem(name, newQuantity, newUnit);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

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
    debugPrint('=== LowStockScreen._addItemsToShoppingList ===');
    debugPrint('Selected items: $selectedItems');
    debugPrint('Item quantities: $itemQuantities');
    debugPrint('Item units: $itemUnits');
    
    final shoppingService =
        Provider.of<ShoppingListService>(context, listen: false);
    final pantry = Provider.of<PantryState>(context, listen: false);

    debugPrint('Shopping service items before: ${shoppingService.items.length}');

    for (final name in selectedItems) {
      debugPrint('Adding to shopping list: $name');
      debugPrint('  - Quantity: ${itemQuantities[name] ?? 1}');
      debugPrint('  - Unit: ${itemUnits[name] ?? 'pcs'}');
      debugPrint('  - Category: ${CategoryEngine.getCategory(name)}');
      
      shoppingService.addItem(
        name: name,
        quantity: itemQuantities[name] ?? 1,
        unit: itemUnits[name] ?? 'pcs',
        category: CategoryEngine.getCategory(name),
        imageUrl: pantry.pantryImages[name] ?? '', // Get imageUrl from pantry data
      );
    }
    
    debugPrint('Shopping service items after: ${shoppingService.items.length}');
    debugPrint('Navigation to shopping list...');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShoppingListScreen(),
      ),
    );
    debugPrint('==============================');
  }
  

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // 🔥 LIVE PANTRY DATA
    final pantry = context.watch<PantryState>();

    final lowStockItems = pantry.pantryQty.entries
        .where((e) => e.value > 0 && e.value <= 3)
        .toList();

    // Debug logging
    debugPrint('=== Low Stock Debug ===');
    debugPrint('Total pantry items: ${pantry.pantryQty.length}');
    debugPrint('Low stock items count: ${lowStockItems.length}');
    for (var item in lowStockItems) {
      debugPrint('Low stock item: ${item.key} -> quantity: ${item.value}');
    }
    debugPrint('====================');

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
              // Show count header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${lowStockItems.length} items in low stock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (selectedItems.isNotEmpty)
                const SizedBox(height: 56),

              Expanded(
                child: lowStockItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No low stock items 🎉',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All your pantry items are well stocked',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lowStockItems.length,
                        itemBuilder: (context, index) {
                          final item = lowStockItems[index];
                          final name = item.key.toString();
                          final qty = item.value;
                          final pantry = context.read<PantryState>();
                          String unit = pantry.pantryUnit[name] ?? '';
                          
                          // If pantry unit is empty or default 'pcs', try to get better metric from service
                          if ((unit.isEmpty || unit == 'pcs') && _metricsLoaded) {
                            final suggestedMetric = _metricsService.getMetricsForIngredient(name);
                            debugPrint('LowStock: $name -> pantry unit: "$unit", suggested metric: $suggestedMetric');
                            if (suggestedMetric.isNotEmpty) {
                              unit = suggestedMetric; // Keep the full metric string like "500 g"
                            }
                          } else if (unit.isEmpty && !_metricsLoaded) {
                            unit = 'pcs'; // fallback while loading
                          }
                          
                          debugPrint('LowStock: $name -> final unit: $unit (loaded: $_metricsLoaded)');

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
                                  imageUrl: pantry.pantryImages[name] ?? '', // Get imageUrl from pantry data
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'in ${CategoryEngine.getCategory(name)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: $qty | Metric: $unit',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  GestureDetector(
                                    onTap: () => _editItem(name, qty, unit),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFE3F2FD),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Add to cart button
                                  IconButton(
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
                                ],
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