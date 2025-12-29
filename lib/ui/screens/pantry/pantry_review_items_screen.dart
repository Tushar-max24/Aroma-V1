import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'dart:async';

import '../../../data/models/ingredient_model.dart';
import '../../../data/services/pantry_add_service.dart';
import '../../../widgets/primary_button.dart';
import '../../../state/pantry_state.dart';
import '../../../core/enums/scan_mode.dart';

class PantryReviewItemsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const PantryReviewItemsScreen({
    super.key,
    required this.items,
  });

  @override
  State<PantryReviewItemsScreen> createState() => _PantryReviewItemsScreenState();
}

class _PantryReviewItemsScreenState extends State<PantryReviewItemsScreen> {
  late List<IngredientModel> _ingredients;
  final Map<String, int> _quantities = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeIngredients();
  }

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🔥 NORMALIZE SCANNED ITEM NAMES
  String _normalizeScanName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'^w\s+'), '') // remove "W "
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  
  
  Future<void> _saveItems() async {
    try {
      final pantryService = PantryAddService();
      final itemsToSave = _ingredients.map((ingredient) {
        return {
          'id': ingredient.id,
          'name': ingredient.name,
          'quantity': _quantities[ingredient.id ?? ''] ?? 1,
          'unit': 'pcs', // Default unit
        };
      }).toList();
      
      final success = await pantryService.saveToPantry(itemsToSave);
      
      if (success && mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save items: $e')),
        );
      }
    }
  }

  void _initializeIngredients() {
    _ingredients = widget.items.map((item) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;

      _quantities[id] = quantity;
      _priceControllers[id] = TextEditingController(text: price.toStringAsFixed(2));

      return IngredientModel(
        id: id,
        name: (item['item'] ?? item['name'] ?? 'Unknown Item').toString(),
        quantity: quantity.toDouble(),
        unit: item['unit']?.toString() ?? 'pcs',
        price: price,
      );
    }).toList();
  }

  void _updateQuantity(String id, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _quantities[id] = newQuantity;
      });
    }
  }

  void _removeItem(String id) {
    setState(() {
      _ingredients.removeWhere((item) => item.id == id);
      _quantities.remove(id);
      _priceControllers.remove(id)?.dispose();
    });
  }

  List<Map<String, dynamic>> _getUpdatedItems() {
    return _ingredients.map((ingredient) {
      final price = double.tryParse(
            _priceControllers[ingredient.id]?.text ?? '0',
          ) ??
          0.0;

      return {
  'item': ingredient.name,   // 🔥 REQUIRED for backend
  'name': ingredient.name,   // keep for frontend safety
  'quantity': _quantities[ingredient.id] ?? 1,
  'unit': ingredient.unit,
  'price': price,
};

    }).toList();
  }

  Future<void> _addItemsToPantry() async {
    if (!mounted) return;
    
    try {
      final pantryState = Provider.of<PantryState>(context, listen: false);
      final items = _getUpdatedItems();

      // Save to local state
      for (final item in items) {
        final name = item['name']?.toString() ?? '';
        final quantity = (item['quantity'] as num).toDouble();
        final unit = item['unit']?.toString() ?? 'pcs';
        
        await pantryState.setItem(name, quantity, unit);
      }

      // Save to server
      if (!mounted) return;
      final success = await PantryAddService().saveToPantry(items);
      
      if (!mounted) return;

      // Navigate back with success
      Navigator.of(context).pop(success);
      
    } catch (e) {
      debugPrint('Error in _addItemsToPantry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Items'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _addItemsToPantry,
          ),
        ],
      ),
      body: _ingredients.isEmpty
          ? _buildEmptyState()
          : _buildIngredientList(),
      bottomNavigationBar: _ingredients.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No items to review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        final quantity = _quantities[ingredient.id] ?? 1;
        final priceController = _priceControllers[ingredient.id]!;

        return Dismissible(
          key: Key(ingredient.id ?? ''),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => ingredient.id != null ? _removeItem(ingredient.id!) : null,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () =>
                            ingredient.id != null ? _updateQuantity(ingredient.id!, quantity - 1) : null,
                      ),
                      Text(quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            ingredient.id != null ? _updateQuantity(ingredient.id!, quantity + 1) : null,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _addItemsToPantry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Add to Pantry',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
