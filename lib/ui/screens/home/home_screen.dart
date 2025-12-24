import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../../state/home_provider.dart';
import '../../widgets/popular_recipe_tile.dart';
import '../../widgets/recipe_card.dart';
import '../add_ingredients/ingredient_entry_screen.dart';
import '../profile/profile_screen.dart';
import '../calendar/calendar_empty_screen.dart';
import '../pantry/pantry_empty_screen.dart';
import '../pantry/pantry_root_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/enums/scan_mode.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  
  const HomeScreen({
    super.key, 
    required this.phoneNumber,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  late final ScrollController _scrollController;
  int _currentPage = 0;
  int _visibleRecipeCount = 2;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset <= 50) {
      setState(() {
        // Reset back to base preview count (2 or less if fewer recipes)
        _visibleRecipeCount = 2;
      });
    }
  }

  Widget _buildRecipeGrid(HomeProvider provider) {
    // Always show the recipes, even if loading
    if (provider.recipes.isEmpty) {
      // This should never happen as we initialize with fallback recipes
      return const Center(
        child: Text('No recipes available'),
      );
    }

    final int totalRecipes = provider.recipes.length;
    final int displayCount = _showAllCategories ? totalRecipes : 2;
    
    // Always show exactly 2 recipes when not showing all categories
    final int itemCount = _showAllCategories ? _visibleRecipeCount : 2;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Recommended Recipes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Recipe grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StaggeredGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: List.generate(
                _showAllCategories ? _visibleRecipeCount : 2,
                (index) {
                  final recipe = provider.recipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    isActive: true,
                  );
                },
              ),
            ),
          ),
          
          // Show All Categories button (only when not showing all categories)
          if (!_showAllCategories)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showAllCategories = true;
                      _visibleRecipeCount = 2; // Start with 2 even after showing all categories
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A45),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Show All Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          // Show More button (only when showing all categories and there are more to show)
          else if (_visibleRecipeCount < totalRecipes)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _visibleRecipeCount = (_visibleRecipeCount + 2).clamp(0, totalRecipes);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A45),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Show More',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Consumer<HomeProvider>(
    builder: (BuildContext context, HomeProvider provider, _) {
      // Show loading indicator only on initial load
      if (provider.isLoading && provider.recipes.isEmpty) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      // Show error if any
      if (provider.error != null && provider.recipes.isEmpty) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading recipes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => provider.loadRecipes(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      // Main content with the existing implementation
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFFFBF6), // almost white with a hint of orange
                  Color(0xFFFFF3E6), // very soft pastel orange
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: Theme.of(context).textTheme.headlineMedium,
                                            children: [
                                              const TextSpan(text: 'Welcome '),
                                              const TextSpan(
                                                text: '👋',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                              TextSpan(
                                                text: '\nGuest',
                                                style: TextStyle(
                                                  color: const Color(0xFFFF4500), // Red-orange color
                                                  fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize != null 
                                                      ? Theme.of(context).textTheme.headlineMedium!.fontSize! * 1.2 
                                                      : 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: widget.phoneNumber.isEmpty ? '' : ' ${widget.phoneNumber.length > 5 ? widget.phoneNumber.replaceRange(0, 5, '*') : widget.phoneNumber}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0), // Increased top padding to align with text
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const PantryRootScreen(),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.shopping_basket_outlined,
                                              size: 24,
                                              color: Colors.black87,
                                            ),
                                          ),

                                          const SizedBox(width: 24), // Increased space between icons
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.notifications_outlined,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 4), // Additional padding from the edge
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Builder(
                                    builder: (BuildContext context) {
                                      final double screenWidth =
                                          MediaQuery.of(context).size.width;
                                      final double cardWidth =
                                          screenWidth * _pageController.viewportFraction;
                                      final double cardHeight =
                                          cardWidth * 3 / 2;

                                      return SizedBox(
                                        height: cardHeight,
                                        child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: provider.recipes.length,
                                      physics: const BouncingScrollPhysics(),
                                      onPageChanged: (int index) {
                                        setState(() {
                                          _currentPage = index;
                                        });
                                      },
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final recipe = provider.recipes[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: AnimatedScale(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            scale: index == _currentPage
                                                ? 1.0
                                                : 0.92,
                                            child: SizedBox(
                                              width: cardWidth,
                                              height: cardHeight,
                                              child: RecipeCard(
                                                recipe: recipe,
                                                isActive: index == _currentPage,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text(
                                        'Explore popular recipes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon:
                                            const Icon(Icons.search, size: 20),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.only(bottom: 8),
                              sliver: SliverMasonryGrid.count(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,

  // 👇 CONTROL HOW MANY ITEMS SHOW
  childCount: _showAllCategories
      ? _visibleRecipeCount
      : 2,

  itemBuilder: (BuildContext context, int index) {
    if (index >= provider.recipes.length) {
      return const SizedBox.shrink();
    }

    final recipe = provider.recipes[index];
    final bool isLarge = index.isEven;

    return PopularRecipeTile(
      recipe: recipe,
      isLarge: isLarge,
    );
  },
),

                            ),
                            SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _visibleRecipeCount >= provider.recipes.length
            ? null
            : () {
                setState(() {
                  if (!_showAllCategories) {
                    // 🔹 FIRST CLICK
                    _showAllCategories = true;
                    _visibleRecipeCount = 2;
                  } else {
                    // 🔹 LOAD MORE
                    final remaining =
                        provider.recipes.length - _visibleRecipeCount;
                    final step = remaining >= 2 ? 2 : remaining;
                    _visibleRecipeCount += step;
                  }
                });
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: Colors.grey.withOpacity(0.35),
            width: 1.1,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              !_showAllCategories
                  ? 'Show All Categories'
                  : _visibleRecipeCount >= provider.recipes.length
                      ? 'All Recipes Shown'
                      : 'Show More',
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    ),
  ),
),

                          ],
                        ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.home_filled,
                    color: Color(0xFFFC6E3C),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(
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
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarEmptyScreen(),
      ),
    );
  },
  icon: const Icon(
    Icons.calendar_month_outlined,
    color: Color(0xFFB0B0B0),
  ),
),

                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(
                        builder: (BuildContext context) => ProfileScreen(
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}