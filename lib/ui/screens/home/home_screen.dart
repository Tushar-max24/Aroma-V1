import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../../state/home_provider.dart';
import '../../widgets/popular_recipe_tile.dart';
import '../../widgets/recipe_card.dart';
import '../add_ingredients/ingredient_entry_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../calendar/calendar_empty_screen.dart';
import '../pantry/pantry_empty_screen.dart';
import '../pantry/pantry_root_screen.dart';
import '../../../core/enums/scan_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.phoneNumber = '',
  });

  final String phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.8);
  bool _showAllCategories = false;
  int _visibleRecipeCount = 2;
  int _currentPage = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Redirect to login if not authenticated
    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

        final totalRecipes = provider.recipes.length;
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFFFFBF6),
                    Color(0xFFFFF3E6),
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
                                          color: const Color(0xFFFF4500),
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
                                padding: const EdgeInsets.only(top: 16.0),
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
                                    const SizedBox(width: 24),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (BuildContext context) {
                              final double screenWidth = MediaQuery.of(context).size.width;
                              final double cardWidth = screenWidth * 0.8;
                              final double cardHeight = cardWidth * 3 / 2;

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
                                  itemBuilder: (BuildContext context, int index) {
                                    final recipe = provider.recipes[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 200),
                                        scale: index == _currentPage ? 1.0 : 0.92,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                icon: const Icon(Icons.search, size: 20),
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
                        childCount: _showAllCategories ? _visibleRecipeCount : 2,
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
                            onPressed: _visibleRecipeCount >= totalRecipes
                                ? null
                                : () {
                                    setState(() {
                                      if (!_showAllCategories) {
                                        _showAllCategories = true;
                                        _visibleRecipeCount = 2;
                                      } else {
                                        final remaining = totalRecipes - _visibleRecipeCount;
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
                                      : _visibleRecipeCount >= totalRecipes
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