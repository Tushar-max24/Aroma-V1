import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../state/pantry_state.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../data/services/shopping_list_service.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  void _shareShoppingList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;

    final itemsText = items
        .map((item) =>
            '• ${item['name']} - ${item['quantity']} ${item['unit']}')
        .join('\n');

    Share.share(
      '🛒 My Shopping List\n\n$itemsText\n\nShared via Aroma',
    );
  }

  double _parseQty(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryState>();

    return Consumer<ShoppingListService>(
      builder: (context, service, _) {
        final shoppingItems = service.items;

        bool needsToBuy(String item, double requiredQty) {
          return pantry.getQty(item) < requiredQty;
        }

        return Scaffold(
          backgroundColor: Colors.white,

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Shopping List",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (shoppingItems.isNotEmpty)
                TextButton(
                  onPressed: service.clearAll,
                  child: const Text(
                    "Clear All",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),

          body: shoppingItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your shopping list is empty',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shoppingItems.length,
                  itemBuilder: (context, index) {
                    final item = shoppingItems[index];

                    final double requiredQty = _parseQty(item['quantity']);

final bool stillNeeded = needsToBuy(
  item['name'],
  requiredQty,
);


                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: AssetImage(
                            ItemImageResolver.getImage(item['name']),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (stillNeeded)
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${item['quantity']} ${item['unit']} • ${item['category']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              service.removeItem(item['name']),
                        ),
                      ),
                    );
                  },
                ),

          floatingActionButton: shoppingItems.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () =>
                      _shareShoppingList(shoppingItems),
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Share List',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
      },
    );
  }
}
