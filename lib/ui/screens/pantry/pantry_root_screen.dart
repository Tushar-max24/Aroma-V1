import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pantry_list_service.dart';
import '../../widgets/base_screen.dart';
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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPantry();
  }

  Future<void> _checkPantry() async {
    try {
      final items = await _service.fetchPantryItems();
      isEmpty = items.isEmpty;
      errorMessage = null; // Clear any previous error
    } catch (e) {
      debugPrint("❌ Pantry root error: $e");
      isEmpty = true;
      errorMessage = "Failed to load pantry: $e"; // Set error message
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      isLoading: loading,
      error: errorMessage,
      onRetry: errorMessage != null ? _checkPantry : null,
      child: isEmpty ? const PantryEmptyScreen() : const PantryHomeScreen(),
    );
  }
}
