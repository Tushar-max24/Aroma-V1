import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'lib/state/pantry_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check what's in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final pantryData = prefs.getString('pantry_data');
  
  print('🔍 Pantry data from SharedPreferences:');
  if (pantryData != null) {
    print('Raw data: $pantryData');
    final decoded = jsonDecode(pantryData) as List<dynamic>;
    print('Decoded items: ${decoded.length}');
    for (final item in decoded) {
      print('- ${item['name']} (${item['quantity']} ${item['unit']})');
    }
  } else {
    print('No pantry data found in SharedPreferences');
  }
  
  // Test PantryState directly
  final pantryState = PantryState();
  await pantryState.loadPantry();
  print('🔍 PantryState items: ${pantryState.items.length}');
  for (final item in pantryState.items) {
    print('- ${item.name} (${item.quantity} ${item.unit})');
  }
}
