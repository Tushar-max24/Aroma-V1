import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pantry_add_service.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../state/pantry_state.dart';

const Color kAccent = Color(0xFFFF7A4A);

class ReviewItemsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const ReviewItemsScreen({super.key, required this.items});

  @override
  State<ReviewItemsScreen> createState() => _ReviewItemsScreenState();
}

class _ReviewItemsScreenState extends State<ReviewItemsScreen> {
  late List<Map<String, dynamic>> reviewItems;

  @override
  void initState() {
    super.initState();
    reviewItems = List.from(widget.items);
  }

  // Background processing method (doesn't block UI)
  Future<void> _processItemsInBackground() async {
    try {
      // Get services
      final pantryState = Provider.of<PantryState>(context, listen: false);
      final shoppingService = Provider.of<ShoppingListService>(context, listen: false);
      
      // Process each item
      for (final item in reviewItems) {
        final name = item['item']?.toString() ?? '';
        final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
        final unit = item['unit']?.toString() ?? 'pcs';
        
        // Add to pantry
        await pantryState.setItem(name, qty, unit);
        
        // Add to shopping list
        shoppingService.addItem(
          name: name,
          quantity: qty,
          unit: unit,
          category: 'Pantry',
        );
      }

      // Save to server (fire and forget)
      PantryAddService().saveToPantry(reviewItems);
    } catch (e) {
      debugPrint("Background processing failed: $e");
      // Don't show any error to user since we've already navigated away
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Review Items",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: ListView.separated(
        itemCount: reviewItems.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = reviewItems[index];

          return ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(
              item["item"],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "Avl Qty: ${item["quantity"]}",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  reviewItems.removeAt(index);
                });
              },
            ),
          );
        },
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              // Navigate back to pantry home screen immediately
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/pantry',
                (route) => false,
              );
              
              // Process items in background (don't wait for completion)
              _processItemsInBackground();
            },
  child: const Text("Add to pantry",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
