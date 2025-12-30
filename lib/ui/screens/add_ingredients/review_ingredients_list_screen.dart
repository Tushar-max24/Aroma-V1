import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/ingredient_row.dart';
import '../preferences/cooking_preference_screen.dart';
import '../../../data/models/ingredient_model.dart';

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
      final result = widget.scanResult;
      final ing = result["ingredients_with_quantity"] ?? [];

      _ingredients = ing.map<IngredientModel>((item) {
        final id = DateTime.now().microsecondsSinceEpoch.toString();

        _priceMap[id] =
            double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
        _quantityMap[id] =
            int.tryParse(item["quantity"]?.toString() ?? "1") ?? 1;

        return IngredientModel(
          id: id,
          emoji: "🍎",
          name: item["item"]?.toString() ?? "",
          match: 100,
        );
      }).toList();

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
    final id = _ingredients[index].id;
    setState(() {
      _priceMap.remove(id);
      _quantityMap.remove(id);
      _ingredients.removeAt(index);
    });
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
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
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
        final price = _priceMap[item.id] ?? 0.0;
        final qty = _quantityMap[item.id] ?? 1;

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
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Price: ₹$price   |   Quantity: $qty",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
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
