import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pantry_review_ingredients_screen.dart';
import '../../data/services/pantry_add_service.dart';

class IngredientEntryScreen extends StatefulWidget {
  final Function? onItemsAdded;
  
  const IngredientEntryScreen({
    super.key,
    this.onItemsAdded,
  });

  @override
  State<IngredientEntryScreen> createState() => _IngredientEntryScreenState();
}

class _IngredientEntryScreenState extends State<IngredientEntryScreen> {
  final ImagePicker _picker = ImagePicker();
  final PantryAddService _pantryService = PantryAddService();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
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
          const SnackBar(content: Text('Failed to capture image')),
        );
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final addedItems = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantryReviewIngredientsScreen(capturedImage: image),
        ),
      );

      if (addedItems != null && addedItems.isNotEmpty) {
        // Save to pantry
        final success = await _pantryService.saveToPantry(addedItems);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Items added to pantry')),
            );
            widget.onItemsAdded?.call();
            if (mounted) Navigator.pop(context, addedItems);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save items')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Pantry'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_camera,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Take a photo of your receipt',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                    child: Text(
                      'Make sure the receipt is well-lit and all items are clearly visible',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                      child: Text('TAKE PHOTO', style: TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
