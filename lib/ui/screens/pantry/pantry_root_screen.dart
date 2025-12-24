import 'package:flutter/material.dart';
import '../../../data/services/pantry_list_service.dart';
import 'pantry_empty_screen.dart';
import 'pantry_home_screen.dart';

class PantryRootScreen extends StatefulWidget {
  const PantryRootScreen({super.key});

  @override
  State<PantryRootScreen> createState() => _PantryRootScreenState();
}

class _PantryRootScreenState extends State<PantryRootScreen> {
  final PantryListService _service = PantryListService();

  bool loading = true;
  bool isEmpty = true;

  @override
  void initState() {
    super.initState();
    _checkPantry();
  }

  Future<void> _checkPantry() async {
    try {
      final items = await _service.fetchPantryItems();
      isEmpty = items.isEmpty;
    } catch (e) {
      debugPrint("❌ Pantry root error: $e");
      isEmpty = true;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return isEmpty
        ? const PantryEmptyScreen()
        : const PantryHomeScreen();
  }
}
