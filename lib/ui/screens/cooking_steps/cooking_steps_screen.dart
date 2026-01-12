import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../data/services/enhanced_ingredient_image_service.dart';
import '../../../data/repositories/recipe_cache_repository.dart';
import '../../../core/utils/item_image_resolver.dart';
import '../../../core/utils/extreme_spring_physics.dart';
import '../../../ui/widgets/shared_ingredient_icon_cache.dart';
import 'step_ingredients_bottomsheet.dart';
import 'step_timer_bottomsheet.dart';
import '../completion/completion_screen.dart';

class CookingStepsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> steps;
  final int currentStep;
  final List<Map<String, dynamic>> allIngredients;
  final String recipeName;

  const CookingStepsScreen({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.allIngredients,
    required this.recipeName,
  });

  @override
  State<CookingStepsScreen> createState() => _CookingStepsScreenState();
}

class _CookingStepsScreenState extends State<CookingStepsScreen> {
  Timer? _timer;
  int _totalSeconds = 0;
  int _secondsRemaining = 0;
  bool _isTimerRunning = false;
  bool _isTimerSet = false;

  @override
  void initState() {
    super.initState();
    // Cache loading disabled - using only backend data
    debugPrint('🚫 Cache loading disabled - using only backend data');
  }

  Future<void> _loadStepsFromCache() async {
    // Cache loading disabled - do nothing
    debugPrint('🚫 Cache loading disabled - ignoring cache request');
  }

  // Enhanced ingredient matching helper
  static bool _isIngredientMatch(String allName, String currentName) {
    // Handle common variations and plural forms
    final allWords = allName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final currentWords = currentName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    // Check if all words from allName are in currentName
    int matchCount = 0;
    for (final allWord in allWords) {
      if (currentWords.any((currentWord) => 
          currentWord.contains(allWord) || allWord.contains(currentWord))) {
        matchCount++;
      }
    }
    
    // Consider it a match if at least 50% of words match
    return matchCount >= (allWords.length / 2).ceil();
  }

  Widget _buildIngredientIcon(dynamic icon, String ingredientName) {
    if (kDebugMode) {
      final cacheStatus = SharedIngredientIconCache.getCacheStatus();
      print('🔍 CookingSteps: Building icon for "$ingredientName" (Cache has ${cacheStatus['cachedItems']} items)');
    }
    
    // If icon is a URL (image_url), use it directly for better matching
    String searchName = ingredientName;
    if (icon is String && icon.isNotEmpty && (icon.startsWith('http://') || icon.startsWith('https://'))) {
      // Try to find the matching ingredient name from allIngredients using the imageUrl
      if (widget.allIngredients.isNotEmpty) {
        for (final allIng in widget.allIngredients) {
          final allImageUrl = (allIng['image_url']?.toString() ?? 
                             allIng['imageUrl']?.toString() ?? 
                             allIng['image']?.toString() ?? '').toLowerCase().trim();
          final currentImageUrl = icon.toLowerCase().trim();
          
          if (allImageUrl == currentImageUrl) {
            searchName = (allIng['item'] ?? allIng['name'] ?? ingredientName).toString();
            if (kDebugMode) {
              print('🔍 CookingSteps: Found matching ingredient by URL: "$searchName"');
            }
            break;
          }
        }
      }
    }
    
    return SharedIngredientIconCache(
      icon: icon,
      ingredientName: searchName,
      allIngredients: widget.allIngredients,
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Text(
      ItemImageResolver.getEmojiForIngredient(ingredientName),
      style: const TextStyle(fontSize: 30),
    );
  }

  Widget _buildDefaultIngredientIcon() {
    return ItemImageResolver.getImageWidget(
      'default_ingredient',
      size: 30,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning || !_isTimerSet) return;
    
    setState(() {
      _isTimerRunning = true;
      _secondsRemaining = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining < _totalSeconds) {
        setState(() {
          _secondsRemaining++;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimerRunning = false;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _setTimer(int minutes) {
    setState(() {
      _totalSeconds = minutes * 60;
      _secondsRemaining = 0;
      _isTimerSet = true;
      _isTimerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _showTimerBottomSheet() {
    showStepTimerBottomSheet(context).then((selectedMinutes) {
      if (selectedMinutes != null) {
        _setTimer(selectedMinutes);
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only use backend widget steps, ignore cache completely
    final currentSteps = widget.steps;
    
    if (currentSteps.isEmpty) {
    return const Scaffold(
      body: Center(
        child: Text(
          'No steps available',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
    }
    
    // Validate currentStep is within bounds
    if (widget.currentStep < 1 || widget.currentStep > currentSteps.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.recipeName),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Invalid step: ${widget.currentStep}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Available steps: ${currentSteps.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    final step = currentSteps[widget.currentStep - 1];
    final String instruction = (step['instruction'] ?? '').toString();
    
    // Enhanced debug logging for step data
    if (kDebugMode) {
      print('🔍 Cooking Steps - Step ${widget.currentStep} Data:');
      print('  - Raw step data: $step');
      print('  - Step keys: ${step.keys.toList()}');
      print('  - ingredients_used: ${step['ingredients_used']}');
      print('  - ingredients_used type: ${step['ingredients_used'].runtimeType}');
    }
    
    // Enhanced ingredient extraction with multiple fallbacks
    List<Map<String, dynamic>> stepIngredients = [];
    
    // Priority 1: Try ingredients_used field
    if (step['ingredients_used'] != null) {
      final ingredientsData = step['ingredients_used'];
      if (ingredientsData is List) {
        stepIngredients = ingredientsData
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        
        if (kDebugMode && stepIngredients.isNotEmpty) {
          print('🔍 Using ingredients_used field with ${stepIngredients.length} items');
        }
      }
    }
    
    // Priority 2: Try other possible field names for step-specific ingredients
    if (stepIngredients.isEmpty) {
      for (String fieldName in ['step_ingredients', 'ingredients', 'items']) {
        if (step[fieldName] != null) {
          final data = step[fieldName];
          if (data is List) {
            stepIngredients = data
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
            
            if (stepIngredients.isNotEmpty) {
              if (kDebugMode) {
                print('🔍 Using $fieldName field with ${stepIngredients.length} items');
              }
              break;
            }
          }
        }
      }
    }
    
    // Priority 3: Only use all ingredients if NO step-specific ingredients found at all
    // This should be rare - only when backend doesn't provide step-specific ingredients
    if (stepIngredients.isEmpty && widget.allIngredients.isNotEmpty) {
      stepIngredients = widget.allIngredients;
      if (kDebugMode) {
        print('⚠️ WARNING: No step-specific ingredients found for step ${widget.currentStep}');
        print('🔍 Using all ingredients as fallback (${stepIngredients.length} items)');
      }
    }
    
    if (kDebugMode) {
      print('🔍 Final stepIngredients count: ${stepIngredients.length}');
      print('🔍 Final stepIngredients: $stepIngredients');
    }
    
    final List<String> tips =
        (step['tips'] as List?)
        ?.where((e) => e != null)
        .map((e) => e.toString())
        .toList() 
    ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ExtremeSpringPhysics(
            springStrength: 1000.0, // Very strong spring
            damping: 12.0, // Slight damping for more bounce
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- TITLE ----------------
              const Text(
                "Cooking Steps",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              // ---------------- STEP INDICATOR ----------------
              Row(
                children: [
                  Text(
                    "Step ${widget.currentStep}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF6A45),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    " / ${currentSteps.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Stack(
                children: [
                  Container(height: 4, color: Colors.grey.shade300),
                  Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width *
                        (widget.currentStep / currentSteps.length),
                    color: const Color(0xFFFF6A45),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300, thickness: 1.2),
              const SizedBox(height: 18),

              // ---------------- INSTRUCTION ----------------
              const Text(
                "Instruction",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Color(0xFFFFB99A), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // TIMER WIDGET
                    GestureDetector(
                      onTap: _isTimerRunning ? _stopTimer : (_isTimerSet ? _startTimer : _showTimerBottomSheet),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isTimerRunning 
                              ? Colors.white 
                              : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF1EC),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _isTimerRunning 
                                ? const Color(0xFFFF6A45)
                                : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFFFC1A6),
                            width: _isTimerRunning ? 2.5 : 2,
                          ),
                          boxShadow: _isTimerRunning && _secondsRemaining <= 10
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isTimerRunning 
                                  ? Icons.timer_outlined
                                  : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                      ? Icons.check_circle_outline
                                      : Icons.timer_outlined,
                              color: _isTimerRunning 
                                  ? const Color(0xFFFF6A45) 
                                  : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF555555),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isTimerRunning 
                                  ? _formatTime(_secondsRemaining)
                                  : _isTimerSet 
                                      ? (_secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                          ? 'Completed'
                                          : '00:00'
                                      : 'Add Timer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isTimerRunning 
                                    ? const Color(0xFFFF6A45)
                                    : (_isTimerSet && _secondsRemaining >= _totalSeconds && _totalSeconds > 0)
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ---------------- INGREDIENTS ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => StepIngredientsBottomSheet(
                          stepIngredients: stepIngredients,
                          allIngredients: widget.allIngredients,
                          currentStepIndex: widget.currentStep - 1,
                        ),
                      );
                    },
                    child: const Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6A45),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "This Step's Ingredients",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 14),

              // ---------------- INGREDIENTS LIST ----------------
Column(
  children: stepIngredients.map<Widget>((ingredient) {
    final name = (ingredient['item'] ?? ingredient['name'] ?? 'Ingredient').toString();
    final qty = (ingredient['quantity']?.toString() ?? ingredient['qty']?.toString() ?? '');
    
    // First try to get imageUrl from step ingredient itself
    var imageUrl = ingredient['image_url']?.toString() ?? 
                 ingredient['imageUrl']?.toString() ?? 
                 ingredient['image']?.toString() ?? '';
    
    // If no imageUrl in step ingredient, look for it in the main allIngredients list
    if (imageUrl.isEmpty && widget.allIngredients.isNotEmpty) {
      for (final allIng in widget.allIngredients) {
        final allName = (allIng['item'] ?? allIng['name'] ?? '').toString().toLowerCase().trim();
        final currentName = name.toLowerCase().trim();
        if (allName == currentName || currentName.contains(allName) || allName.contains(currentName)) {
          // Extract imageUrl from multiple possible fields in main ingredient list
          imageUrl = allIng['image_url']?.toString() ?? 
                     allIng['imageUrl']?.toString() ?? 
                     allIng['image']?.toString() ?? '';
          if (kDebugMode) {
            print('🔍 Found imageUrl in allIngredients for "$name": $imageUrl');
          }
          break;
        }
      }
    }
    
    final icon = imageUrl.isNotEmpty ? imageUrl : name; // Use imageUrl if available, otherwise name
    
    if (kDebugMode) {
      print('🔍 CookingSteps Ingredient Data:');
      print('  - Raw ingredient: $ingredient');
      print('  - Name: "$name"');
      print('  - Qty: "$qty"');
      print('  - ImageUrl: "$imageUrl"');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFDCCD),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIngredientIcon(icon, name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (qty.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    qty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7A7A7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }).toList(),
),

              const SizedBox(height: 26),

              // ---------------- TIPS ----------------
              if (tips.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tips & Doubts",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...tips.map((tip) {
                        final parts = tip.split('?');
                        final question = parts.isNotEmpty ? '${parts[0].trim()}?' : '';
                        final answer = parts.length > 1 ? parts.sublist(1).join('?').trim() : '';
                        
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                              if (answer.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  answer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // ---------------- BUTTONS ----------------
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFF6A45),
                          width: 2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Back",
                          style: TextStyle(
                            color: Color(0xFFFF6A45),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A45),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (widget.currentStep < widget.steps.length) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CookingStepsScreen(
                                  steps: widget.steps,
                                  currentStep: widget.currentStep + 1,
                                  allIngredients: widget.allIngredients,
                                  recipeName: widget.recipeName,
                                ),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompletionScreen(),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.currentStep < widget.steps.length ? "Next" : "Done",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}