import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/item_image_resolver.dart';
import '../../../data/services/shopping_list_service.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../../state/pantry_state.dart';
import '../../../data/services/scan_bill_service.dart';
import '../../../data/services/pantry_add_service.dart';

import 'pantry_item_details_screen.dart';
import 'pantry_search_add_screen.dart';
import 'pantry_home_screen.dart';
enum ReviewState { confirm, scanning, failed }

class PantryReviewIngredientsScreen extends StatefulWidget {
  final XFile capturedImage;
  final ScanMode mode;

  const PantryReviewIngredientsScreen({
    super.key,
    required this.capturedImage,
    this.mode = ScanMode.pantry,
  });

  @override
  State<PantryReviewIngredientsScreen> createState() =>
      _PantryReviewIngredientsScreenState();
}

class _PantryReviewIngredientsScreenState
    extends State<PantryReviewIngredientsScreen> {
  ReviewState _state = ReviewState.confirm;
  final PantryAddService _pantryService = PantryAddService();

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case ReviewState.confirm:
        return _ConfirmPhotoView(
          capturedImage: widget.capturedImage,
          onLooksGood: () async {
            setState(() => _state = ReviewState.scanning);

            try {
              final result = await ScanBillService().scanBill(widget.capturedImage!);

              if (!mounted) return;

              if (widget.mode == ScanMode.pantry) {
                // PANTRY FLOW - Process and route to pantry review
                debugPrint(" PANTRY MODE - Raw scan result: $result");
                
                // Check if scan result has ingredients data directly
                if (result.containsKey("ingredients_with_quantity")) {
                  final ingredients = result["ingredients_with_quantity"];
                  if (ingredients is List && ingredients.isNotEmpty) {
                    debugPrint(" PANTRY MODE - Direct ingredients found: $ingredients");
                    
                    if (!mounted) return;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ScannedIngredientsListScreen(
                          items: List<Map<String, dynamic>>.from(ingredients),
                        ),
                      ),
                    );
                    return;
                  }
                }
                
                // Fallback: Try to process raw text if no direct ingredients found
                final rawText = result["raw_text"];
                debugPrint(" PANTRY MODE - Raw text: $rawText");
                
                try {
                  final pantryResult = await PantryAddService().processRawText(rawText);
                  debugPrint(" PANTRY MODE - Pantry result: $pantryResult");
                  
                  final items = pantryResult["ingredients_with_quantity"];
                  debugPrint(" PANTRY MODE - Items extracted: $items");

                  if (!mounted) return;
                  
                  if (items != null && items.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ScannedIngredientsListScreen(
                          items: List<Map<String, dynamic>>.from(items),
                        ),
                      ),
                    );
                  } else {
                    // Fallback: Try to extract ingredients directly from scan result
                    try {
                      final List<Map<String, dynamic>> fallbackItems = [];
                      
                      // Check if scan result has ingredients data directly
                      if (result.containsKey("ingredients_with_quantity")) {
                        final ingredients = result["ingredients_with_quantity"];
                        if (ingredients is List) {
                          for (var item in ingredients) {
                            if (item is Map && item.containsKey("item")) {
                              fallbackItems.add({
                                "item": item["item"] ?? "Unknown",
                                "quantity": item["quantity"] ?? 1,
                                "unit": item["unit"] ?? "pcs",
                              });
                            }
                          }
                        }
                      }
                      
                      debugPrint(" PANTRY MODE - Fallback items: $fallbackItems");
                      
                      if (fallbackItems.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _ScannedIngredientsListScreen(
                              items: fallbackItems,
                            ),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        setState(() => _state = ReviewState.failed);
                      }
                    } catch (fallbackError) {
                      debugPrint(" PANTRY MODE - Fallback also failed: $fallbackError");
                      if (!mounted) return;
                      setState(() => _state = ReviewState.failed);
                    }
                  }
                } catch (processingError) {
                  debugPrint(" PANTRY MODE - Processing error: $processingError");
                  if (!mounted) return;
                  setState(() => _state = ReviewState.failed);
                }
              }
            } catch (scanError) {
              debugPrint('General scanning error: $scanError');
              if (!mounted) return;
              setState(() => _state = ReviewState.failed);
            }
          },
          onRetake: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PantrySearchAddScreen(),
                    ),
                    (route) => false,
                  ),
        );

      case ReviewState.scanning:
        return _ScanningView(
          capturedImage: widget.capturedImage,
          onCancel: () => setState(() => _state = ReviewState.failed),
        );

      case ReviewState.failed:
        return const _UploadFailedView();
    }
  }
}

///// 1️⃣ Confirm Screen UI
class _ConfirmPhotoView extends StatelessWidget {
  final XFile capturedImage;
  final VoidCallback onLooksGood;
  final VoidCallback onRetake;

  const _ConfirmPhotoView({
    required this.capturedImage,
    required this.onLooksGood,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button at top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: onRetake,
                ),
              ),
            ),

            // Vertical rectangular image preview
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.file(
                    File(capturedImage.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),

            // Text content below image
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Great! Is the photo clear enough to see ingredients?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 26),
                      onPressed: onRetake,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: onLooksGood,
                        child: const Text(
                          "Yes, Looks Good",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///// 2️⃣ Scanning UI
class _ScanningView extends StatelessWidget {
  final VoidCallback onCancel;
  final XFile capturedImage;

  const _ScanningView({required this.onCancel, required this.capturedImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Receipt background image
          Positioned.fill(
            child: Image.file(
              File(capturedImage.path),
              fit: BoxFit.cover,
            ),
          ),
          
          // Back button at top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
          
          // Headphone icon at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones, color: Colors.black, size: 24),
            ),
          ),

          // Center magnifying glass icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          // Scanner Frame Overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 120, 40, 200),
              child: CustomPaint(painter: _ScanningFrame()),
            ),
          ),

          // Bottom text
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Just a few more seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const Text(
                    'and your pantry will be up to date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///// 3️⃣ Failed UI Sheet
class _UploadFailedView extends StatelessWidget {
  const _UploadFailedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),

      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),

              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Failed!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Oops! Something went wrong.\nTry Uploading image again!",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFFF7A4A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Retry Upload",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningFrame extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 40.0;
    const stroke = 3.0;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw four L-shaped corners at the edges of the screen
    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Screen to display list of scanned ingredients with review UI
class _ScannedIngredientsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const _ScannedIngredientsListScreen({
    super.key,
    required this.items,
  });

  @override
  State<_ScannedIngredientsListScreen> createState() => _ScannedIngredientsListScreenState();
}

class _ScannedIngredientsListScreenState extends State<_ScannedIngredientsListScreen> {

  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _removeItem(int index) {
    setState(() {
      _filteredItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
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
                    onTap: () {
                      // TODO: Navigate to add more ingredients
                    },
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final name = item['item'] ?? item['name'] ?? 'Unknown Item';
                final price = item['price']?.toString() ?? '1.0';
                final quantity = item['quantity']?.toString() ?? '1';

                if (kDebugMode) {
                  print('🔍 ReviewIngredients: Building item with name: "$name"');
                }

                return Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Profile image
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: ItemImageResolver.getImageWidget(
                                    name,
                                    size: 30,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 14),
                              
                              // Name + match text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 19,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'match: 100%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black.withOpacity(0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Remove button (x)
                              GestureDetector(
                                onTap: () => _removeItem(index),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFE5E5),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFFFF6A6A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Price: ₹$price   |   Quantity: $quantity",
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
            ),
          ),
          
          // Add to Pantry button at bottom
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
              onTap: () async {
                  // Add ingredients to pantry using actual service
                  try {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF7A4A)),
                      ),
                    );

                    // Prepare items for pantry service
                    final pantryItems = _filteredItems.map((item) {
                      return {
                        'name': item['item'] ?? item['name'] ?? 'Unknown Item',
                        'quantity': double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0,
                        'unit': item['unit'] ?? 'pcs',
                      };
                    }).toList();

                    // Call pantry service to save items
                    final pantryService = PantryAddService();
                    var backendSuccess = false;
                    var backendError = '';
                    
                    try {
                      backendSuccess = await pantryService.saveToPantry(pantryItems);
                    } catch (e) {
                      debugPrint('Backend error: $e');
                      backendError = e.toString();
                      backendSuccess = false;
                    }

                    // Close loading indicator
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      
                      // Always update local state
                      final pantryState = Provider.of<PantryState>(context, listen: false);
                      final shoppingListService = Provider.of<ShoppingListService>(context, listen: false);
                      
                      int duplicateCount = 0;
                      int addedCount = 0;
                      
                      // Add each item to local pantry state with duplicate check
                      for (var item in pantryItems) {
                        final itemName = item['name'] as String;
                        
                        // Check if item already exists in pantry
                        final existingItem = pantryState.pantryItems.firstWhere(
                          (pantryItem) => pantryItem.name.toLowerCase() == itemName.toLowerCase(),
                          orElse: () => PantryItem(name: '', quantity: 0, unit: ''),
                        );
                        
                        if (existingItem.name.isNotEmpty) {
                          // Item already exists, update quantity instead of adding duplicate
                          await pantryState.setItem(
                            itemName,
                            existingItem.quantity + (item['quantity'] as double),
                            item['unit'] as String,
                          );
                          duplicateCount++;
                        } else {
                          // New item, add to pantry
                          await pantryState.setItem(
                            itemName,
                            item['quantity'] as double,
                            item['unit'] as String,
                          );
                          addedCount++;
                        }
                        
                        // Also add to shopping list (only if not already there)
                        if (!shoppingListService.isAdded(itemName)) {
                          shoppingListService.addItem(
                            name: itemName,
                            quantity: item['quantity'].toString(),
                            unit: item['unit'] as String,
                            category: 'scanned',
                          );
                        }
                      }
                      
                      // Show detailed success message
                      String message = 'Items Added successfully';
                      if (duplicateCount > 0 && addedCount > 0) {
                        message = 'Added $addedCount new items, updated $duplicateCount duplicates';
                      } else if (duplicateCount > 0) {
                        message = 'Updated $duplicateCount existing items';
                      } else if (addedCount > 0) {
                        message = 'Added $addedCount new items';
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      
                      // Navigate to pantry page to show the items
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantryHomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (error) {
                    debugPrint('Error adding to pantry: $error');
                    
                    // Close loading indicator
                    if (mounted) {
                      Navigator.pop(context); // Close loading dialog
                      
                      // Still try to save locally even on error
                      try {
                        final pantryItems = _filteredItems.map((item) {
                          return {
                            'name': item['item'] ?? item['name'] ?? 'Unknown Item',
                            'quantity': double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0,
                            'unit': item['unit'] ?? 'pcs',
                          };
                        }).toList();
                        
                        final pantryState = Provider.of<PantryState>(context, listen: false);
                        final shoppingListService = Provider.of<ShoppingListService>(context, listen: false);
                        
                        int duplicateCount = 0;
                        int addedCount = 0;
                        
                        for (var item in pantryItems) {
                          final itemName = item['name'] as String;
                          
                          // Check if item already exists in pantry
                          final existingItem = pantryState.pantryItems.firstWhere(
                            (pantryItem) => pantryItem.name.toLowerCase() == itemName.toLowerCase(),
                            orElse: () => PantryItem(name: '', quantity: 0, unit: ''),
                          );
                          
                          if (existingItem.name.isNotEmpty) {
                            // Item already exists, update quantity instead of adding duplicate
                            await pantryState.setItem(
                              itemName,
                              existingItem.quantity + (item['quantity'] as double),
                              item['unit'] as String,
                            );
                            duplicateCount++;
                          } else {
                            // New item, add to pantry
                            await pantryState.setItem(
                              itemName,
                              item['quantity'] as double,
                              item['unit'] as String,
                            );
                            addedCount++;
                          }
                          
                          // Also add to shopping list (only if not already there)
                          if (!shoppingListService.isAdded(itemName)) {
                            shoppingListService.addItem(
                              name: itemName,
                              quantity: item['quantity'].toString(),
                              unit: item['unit'] as String,
                              category: 'scanned',
                            );
                          }
                        }
                        
                        // Show detailed success message
                        String message = 'Items Added successfully';
                        if (duplicateCount > 0 && addedCount > 0) {
                          message = 'Added $addedCount new items, updated $duplicateCount duplicates';
                        } else if (duplicateCount > 0) {
                          message = 'Updated $duplicateCount existing items';
                        } else if (addedCount > 0) {
                          message = 'Added $addedCount new items';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        
                        // Navigate to pantry page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PantryHomeScreen(),
                          ),
                          (route) => false,
                        );
                      } catch (localError) {
                        // Show error message if even local save fails
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add items to pantry: $error'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A4A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Add to Pantry',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for UI components
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
            const Border.fromBorderSide(BorderSide(color: Color(0xFFFF7A4A))),
      ),
      child: const Center(
        child: Text(
          "Add more",
          style: TextStyle(
              color: Color(0xFFFF7A4A),
              fontWeight: FontWeight.w600,
              fontSize: 14.5),
        ),
      ),
    );
  }
}
