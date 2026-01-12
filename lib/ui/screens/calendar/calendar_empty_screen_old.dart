import 'package:flutter/material.dart';
import 'package:flavoryx/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../widgets/cached_image.dart';
import 'package:flavoryx/ui/screens/add_ingredients/ingredient_entry_screen.dart';
import 'package:flavoryx/ui/screens/profile/profile_screen.dart';
import 'package:flavoryx/ui/screens/home/home_screen.dart';
import 'package:flavoryx/ui/screens/home/generate_recipe_screen.dart';
import 'select_ingredients_screen.dart';
import '../../../core/enums/scan_mode.dart';
import '../../../core/utils/category_engine.dart';

const Color kAccent = Color(0xFFFF7A4A);

class CalendarEmptyScreen extends StatefulWidget {
  final String phoneNumber;
  
  const CalendarEmptyScreen({super.key, this.phoneNumber = ''});

  @override
  State<CalendarEmptyScreen> createState() => _CalendarEmptyScreenState();
}

class _CalendarEmptyScreenState extends State<CalendarEmptyScreen> {
  bool _isLoading = false;
  List<String> _pantryIngredients = [];

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get pantry items from shared preferences using the correct key
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pantry_data');
      
      final pantryIngredients = <String>[];
      
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        
        for (final item in decoded) {
          final name = item['name'] as String;
          pantryIngredients.add(name);
        }
      }

      setState(() {
        _pantryIngredients = pantryIngredients;
        _isLoading = false;
      });

      print("🔍 DEBUG: Loaded ${pantryIngredients.length} pantry ingredients: $pantryIngredients");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error loading pantry ingredients: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Illustration + text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 220,
                    child: CachedImage(
                      imageUrl: 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Your cooking calendar\nis empty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Start planning delicious meals for the week based on your pantry and preferences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Generate Weekly Recipe button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => _openGenerateSheet(context),
                  child: const Text(
                    'Generate Weekly Recipe',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),

      // 🔥 Same Footer Navigation as HomeScreen
      bottomNavigationBar: _buildFooter(context),
    );
  }

  // --------------------------------------------------------------------------
  // 🔥 EXACT SAME FOOTER AS HOME SCREEN (copied & adapted)
  // --------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // HOME
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(phoneNumber: widget.phoneNumber),
                ),
              );
            },
            icon: const Icon(Icons.home_filled, color: Color(0xFFB0B0B0)),
          ),

          // SEARCH
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Color(0xFFB0B0B0)),
          ),

          // CENTER ORANGE BUTTON
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IngredientEntryScreen(
                    mode: ScanMode.cooking,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFC6E3C),
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.restaurant_menu, color: Colors.white),
            ),
          ),

          // CALENDAR → ACTIVE PAGE
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFFC6E3C),
            ),
          ),

          // PROFILE
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(phoneNumber: ''),
                ),
              );
            },
            icon: const Icon(Icons.person_outline, color: Color(0xFFB0B0B0)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Sheet
  // --------------------------------------------------------------------------
  void _openGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hey there!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'How do you want to add ingredients\nfor your weekly recipe?',
                  style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Let me select ingredients
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kAccent, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectIngredientsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Let me select my ingredients',
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Include pantry items
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      print("🔍 DEBUG: Using pantry ingredients: $_pantryIngredients");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenerateRecipeScreen(
                            usePantryIngredients: true,
                            pantryIngredients: _pantryIngredients,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      _isLoading 
                          ? 'Loading pantry items...' 
                          : 'Include all my pantry items (${_pantryIngredients.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
