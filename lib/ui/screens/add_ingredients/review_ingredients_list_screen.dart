import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/emoji_service.dart';
import '../../../data/models/ingredient_model.dart';
import '../../widgets/ingredient_row.dart';
import '../preferences/cooking_preference_screen.dart';

class ReviewIngredientsListScreen extends StatefulWidget {
  final dynamic scanResult;

  const ReviewIngredientsListScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ReviewIngredientsListScreen> createState() =>
      _ReviewIngredientsListScreenState();
}

class _ReviewIngredientsListScreenState
    extends State<ReviewIngredientsListScreen> {
  List<IngredientModel> _ingredients = [];

  /// 👉 Store price & quantity separately (clean approach)
  final Map<String, double> _priceMap = {};
  final Map<String, int> _quantityMap = {};
  final Map<String, String> _metricsMap = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  // ---------------- Fetch Ingredients from Scan ----------------
  Future<void> _fetchIngredients() async {
    try {
      // Initialize emoji service
      await EmojiService().initialize();
      
      final result = widget.scanResult;
      final ing = result["ingredients_with_quantity"] ?? [];

      _ingredients = [];
      for (var item in ing) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();
        final itemName = item["item"]?.toString() ?? "";
        
        _priceMap[id] = double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
        _quantityMap[id] = int.tryParse(item["quantity"]?.toString() ?? "1") ?? 1;
        
        // Get emoji for the ingredient
        final emoji = EmojiService().getEmojiForIngredient(itemName);
        
        // Get metrics for the ingredient
        final metrics = EmojiService().getMetricsForIngredient(itemName) ?? '1 pc';
        _metricsMap[id] = metrics;
        
        _ingredients.add(
          IngredientModel(
            id: id,
            emoji: emoji, // Can be null, which is handled by IngredientRow
            name: itemName,
            match: 100,
            quantity: _quantityMap[id]?.toDouble() ?? 1.0,
            price: _priceMap[id] ?? 0.0,
            metrics: metrics,
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = "Failed: $e";
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // ADD INGREDIENT (NAME + PRICE + QUANTITY)
  // =====================================================
  Future<void> _showAddIngredientDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Ingredient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Ingredient name"),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final id =
                    DateTime.now().microsecondsSinceEpoch.toString();

                setState(() {
                  _ingredients.add(
                    IngredientModel(
                      id: id,
                      emoji: "🍎",
                      name: name,
                      match: 100,
                    ),
                  );
                  _priceMap[id] =
                      double.tryParse(priceController.text) ?? 0.0;
                  _quantityMap[id] =
                      int.tryParse(quantityController.text) ?? 1;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ---------------- Remove Ingredient ----------------
  void _removeIngredient(int index) {
    setState(() {
      final removed = _ingredients.removeAt(index);
      // Also remove from price and quantity maps
      if (removed.id != null) {
        _priceMap.remove(removed.id);
        _quantityMap.remove(removed.id);
      }
    });
  }

  void _showEditDialog(int index) {
    final ingredient = _ingredients[index];
    final quantityController = TextEditingController(
      text: ingredient.quantity.toInt().toString(),
    );
    final metricsController = TextEditingController(
      text: ingredient.metrics ?? '1 pc',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ingredient.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: metricsController,
              decoration: const InputDecoration(
                labelText: 'Metrics (e.g., kg, g, pcs)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text) ?? 1;
              final newMetrics = metricsController.text.trim();
              
              setState(() {
                if (ingredient.id != null) {
                  // Update quantity in the quantity map
                  _quantityMap[ingredient.id!] = newQuantity;
                  
                  // Update metrics in the metrics map if it's not empty
                  if (newMetrics.isNotEmpty) {
                    _metricsMap[ingredient.id!] = newMetrics;
                  }
                  
                  // Update the ingredient in the list
                  _ingredients[index] = ingredient.copyWith(
                    quantity: newQuantity.toDouble(),
                    metrics: newMetrics.isNotEmpty ? newMetrics : ingredient.metrics,
                  );
                }
              });
              
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),

      // ---------- HEADER ----------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _circleIcon(Icons.arrow_back),
                  ),
                  GestureDetector(
                    onTap: _showAddIngredientDialog,
                    child: _addMoreBtn(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Review Ingredients',
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ],
          ),
        ),
      ),

      // ---------- BODY ----------
      body: Column(
        children: [
          Expanded(child: _buildBody()),

          // ---------- PROCEED BUTTON ----------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                final ingredientsPayload = _ingredients.map((e) {
                  return {
                    "item": e.name,
                    "price": _priceMap[e.id] ?? 0.0,
                    "quantity": _quantityMap[e.id] ?? 1,
                  };
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CookingPreferenceScreen(
                      ingredients: ingredientsPayload,
                    ),
                  ),
                );
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Proceed',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LIST UI ----------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_ingredients.isEmpty) {
      return const Center(child: Text('No ingredients found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final item = _ingredients[index];
        final price = item.id != null ? _priceMap[item.id!] ?? 0.0 : 0.0;
        final qty = item.id != null ? _quantityMap[item.id!] ?? 1 : 1;

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IngredientRow(
                    emoji: item.emoji,
                    name: item.name,
                    matchPercent: item.match,
                    onRemove: () => _removeIngredient(index),
                    onEdit: () => _showEditDialog(index),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Qty: $qty',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Metrics: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: _metricsMap[item.id] ?? '1 pc',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.black.withOpacity(0.06)),
          ],
        );
      },
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.15)),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _addMoreBtn() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFFFF0E9),
        border:
            const Border.fromBorderSide(BorderSide(color: Color(0xFFFF6A45))),
      ),
      child: const Center(
        child: Text(
          'Add more',
          style: TextStyle(
              color: Color(0xFFFF6A45),
              fontWeight: FontWeight.w600,
              fontSize: 14.5),
        ),
      ),
    );
  }
}
