import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListService extends ChangeNotifier {
  static const _storageKey = 'shopping_list_items';

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  ShoppingListService() {
    _loadFromStorage();
  }

  // -------- LOAD --------
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _items
        ..clear()
        ..addAll(List<Map<String, dynamic>>.from(decoded));
      notifyListeners();
    }
  }

  // -------- SAVE --------
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_items));
  }

  // -------- ADD ITEM --------
  void addItem({
    required String name,
    required dynamic quantity,
    required String unit,
    required String category,
  }) {
    final index = _items.indexWhere((e) => e['name'] == name);

    if (index >= 0) {
      _items[index]['quantity'] = quantity.toString();
    } else {
      _items.add({
        'name': name,
        'quantity': quantity.toString(),
        'unit': unit,
        'category': category,
      });
    }

    _saveToStorage();
    notifyListeners();
  }

  // -------- REMOVE --------
  void removeItem(String name) {
    _items.removeWhere((e) => e['name'] == name);
    _saveToStorage();
    notifyListeners();
  }

  // -------- CLEAR --------
  void clearAll() {
    _items.clear();
    _saveToStorage();
    notifyListeners();
  }

  bool isAdded(String name) {
    return _items.any((e) => e['name'] == name);
  }
}
