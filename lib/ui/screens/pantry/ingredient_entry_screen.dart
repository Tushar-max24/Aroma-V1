import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pantry_add_service.dart';
import '../../../state/pantry_state.dart';
import 'pantry_review_ingredients_screen.dart';

class IngredientEntryScreen extends StatefulWidget {
  final Function? onItemsAdded;
  final List<dynamic>? items;
  
  const IngredientEntryScreen({
    super.key,
    this.onItemsAdded,
    this.items,
  });

  @override
  State<IngredientEntryScreen> createState() => _IngredientEntryScreenState();
}

class _IngredientEntryScreenState extends State<IngredientEntryScreen> {
  final ImagePicker _picker = ImagePicker();
  late final PantryAddService _pantryService;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _pantryService = PantryAddService();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      
      // TODO: Implement actual image processing logic
      // For now, we'll simulate a successful scan with sample data
      await Future.delayed(const Duration(seconds: 2));
      
      // Sample data - replace with actual image processing results
      final List<Map<String, dynamic>> result = [
        {'name': 'Tomato', 'quantity': 4, 'unit': 'pcs'},
        {'name': 'Onion', 'quantity': 2, 'unit': 'pcs'},
      ];

      if (result.isNotEmpty) {
        if (!mounted) return;
        
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PantryReviewIngredientsScreen(
              items: result,
            ),
          ),
        ) ?? false;
        
        if (added && widget.onItemsAdded != null) {
          widget.onItemsAdded!();
        }
        
        if (mounted) {
          Navigator.of(context).pop(added);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ingredients found in the image')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ingredients'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isEmpty) ...[
                    // Image picker button
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take a photo of ingredients'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _isLoading ? null : () {
                        // TODO: Implement manual entry
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Enter Manually'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
