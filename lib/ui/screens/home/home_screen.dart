import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math;
import '../../../data/models/recipe_model.dart';

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
import 'recipe_detail_screen.dart';
import '../../../widgets/primary_button.dart';

class ElasticScrollPhysics extends ScrollPhysics {
  const ElasticScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  ElasticScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ElasticScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Apply elastic resistance when overscrolling
    if (position.outOfRange) {
      final double overscrollPastStart = math.max(0.0, position.minScrollExtent - position.pixels);
      final double overscrollPastEnd = math.max(0.0, position.pixels - position.maxScrollExtent);
      final double overscrollDistance = overscrollPastStart > 0 ? overscrollPastStart : overscrollPastEnd;
      final double stiffness = 0.12; // Reduced for more elastic feel
      final double resistance = stiffness * overscrollDistance;
      return offset * (1.0 - resistance);
    }
    return offset;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return true;
  }

  @override
  double carryMomentumVelocity(ScrollMetrics position, double velocity) {
    // Add slight bounce effect with reduced momentum
    return velocity * 0.85;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) {
      // Create elastic bounce simulation when out of range
      return _ElasticBounceSimulation(
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        spring: const SpringDescription(
          mass: 0.5,
          stiffness: 400.0,
          damping: 4.0,
        ),
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _ElasticBounceSimulation extends Simulation {
  final double position;
  final double velocity;
  final double leadingExtent;
  final double trailingExtent;
  final SpringDescription spring;

  _ElasticBounceSimulation({
    required this.position,
    required this.velocity,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.spring,
  });

  late final SpringSimulation _springSimulation;
  bool _isInitialized = false;

  void _initialize() {
    if (_isInitialized) return;
    
    final double target = position < leadingExtent 
        ? leadingExtent 
        : position > trailingExtent 
            ? trailingExtent 
            : position;
    
    final double distance = position - target;
    _springSimulation = SpringSimulation(
      spring,
      position,
      target,
      velocity * 0.5, // Reduce velocity for gentler bounce
    );
    _isInitialized = true;
  }

  @override
  double x(double time) {
    _initialize();
    return _springSimulation.x(time);
  }

  @override
  double dx(double time) {
    _initialize();
    return _springSimulation.dx(time);
  }

  @override
  bool isDone(double time) {
    _initialize();
    return _springSimulation.isDone(time);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.phoneNumber = '',
  });

  final String phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Auto-scroll timing constants
  static const Duration _autoScrollInterval = Duration(seconds: 3);
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 1000);
  static const Duration _resumeDelay = Duration(seconds: 3);
  
  late Timer _autoScrollTimer;
  bool _isUserScrolling = false;
  late final PageController _pageController;
  late final AnimationController _buttonController;
  late final Animation<double> _buttonAnimation;
  late final ScrollController _scrollController;
  
  double _currentPage = 0.0;
  final double _cardAspectRatio = 0.85;
  final double _cardPadding = 20.0;
  bool _showAllCategories = false;
  int _visibleRecipeCount = 2;

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController(viewportFraction: 0.9);
    _scrollController = ScrollController();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _pageController.addListener(_onPageChanged);
    _scrollController.addListener(_onScrollChanged);
    
    // Start auto-scroll when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }
  
  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0.0;
    });
  }
  
  void _onScrollChanged() {
    // When user scrolls to top, shrink the grid back to 2 cards
    if (_scrollController.offset <= 50 && _showAllCategories) {
      setState(() {
        _showAllCategories = false;
        _visibleRecipeCount = 2;
      });
    }
  }
  
  @override
  void dispose() {
    // Cancel the auto-scroll timer
    _autoScrollTimer.cancel();
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
  
  // Start auto-scroll timer
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (timer) {
      if (!mounted || _isUserScrolling) return;
      
      final nextPage = _pageController.page?.round() ?? 0;
      final itemCount = Provider.of<HomeProvider>(context, listen: false).recipes.length;
      
      if (itemCount <= 1) return; // No need to auto-scroll if there's only one item
      
      if (nextPage >= itemCount - 1) {
        _pageController.animateToPage(
          0,
          duration: _scrollAnimationDuration,
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.nextPage(
          duration: _scrollAnimationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Custom scroll physics for smooth scrolling
  final _scrollPhysics = const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  Widget _buildRecipeCarousel() {
    return SizedBox(
      height: 360.0,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            // User started scrolling, pause auto-scroll
            _isUserScrolling = true;
          } else if (notification is ScrollEndNotification) {
            // User stopped scrolling, resume auto-scroll after the delay
            Future.delayed(_resumeDelay, () {
              if (mounted) {
                setState(() {
                  _isUserScrolling = false;
                });
              }
            });
          }
          
          if (notification is ScrollUpdateNotification) {
            if (!_pageController.position.isScrollingNotifier.value) {
              _pageController.position.isScrollingNotifier.value = true;
            }
          } else if (notification is ScrollEndNotification) {
            _pageController.position.isScrollingNotifier.value = false;
          }
          return true;
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: Provider.of<HomeProvider>(context, listen: false).recipes.length,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padEnds: false,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index.toDouble();
            });
          },
          itemBuilder: (context, index) {
            return _buildRecipeCard(
              Provider.of<HomeProvider>(context, listen: false).recipes[index], 
              index
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(
          Provider.of<HomeProvider>(context, listen: false).recipes.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage.round() == index ? 24.0 : 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: _currentPage.round() == index 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[300],
              boxShadow: _currentPage.round() == index
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe, int index) {
    final double pageOffset = index - _currentPage;
    final double scaleFactor = 0.9 + (0.1 * (1 - pageOffset.abs()));
    final double opacity = (1 - (pageOffset.abs() * 0.5)).clamp(0.2, 1.0);
    
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final double rotation = pageOffset * 0.03;
        final double offsetX = pageOffset * 30;
        
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(rotation)
            ..scale(scaleFactor),
          alignment: pageOffset > 0 ? Alignment.centerLeft : Alignment.centerRight,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(offsetX, 0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToRecipeDetail(recipe),
        child: Hero(
          tag: 'recipe_${recipe.id}',
          child: RecipeCard(
            recipe: recipe,
          ),
        ),
      ),
    );
  }

  void _navigateToRecipeDetail(RecipeModel recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _loadMoreRecipes,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Load More'),
      ),
    );
  }

  Future<void> _loadMoreRecipes() async {
    // Implement your recipe loading logic here
    // For example:
    // await Provider.of<HomeProvider>(context, listen: false).loadMoreRecipes();
  }

  Widget _buildShowMoreButton() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonAnimation.value * 4 - 2), // Subtle bounce effect
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => _buttonController.stop(),
        onExit: (_) => _buttonController.repeat(reverse: true),
        child: GestureDetector(
          onTapDown: (_) => _buttonController.stop(),
          onTapCancel: () => _buttonController.repeat(reverse: true),
          onTap: () {
            _buttonController.repeat(reverse: true);
            _loadMoreRecipes();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            height: 56.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColorDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Discover More Recipes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8.0),
                AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _buttonAnimation.value * 0.2 - 0.1, // Subtle wiggle
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);
    
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
        if (provider.isLoading && provider.recipes.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
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
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ElasticScrollPhysics(),
                  ),
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
                              final double screenWidth =
                                  MediaQuery.of(context).size.width;
                              final double cardWidth =
                                  screenWidth * _pageController.viewportFraction;
                              final double cardHeight =
                                  cardWidth * 3 / 2; // 3:2 ratio for old card design

                              return SizedBox(
                                height: cardHeight,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: provider.recipes.length,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  pageSnapping: true,
                                  padEnds: false,
                                  onPageChanged: (int index) {
                                    setState(() {
                                      _currentPage = index.toDouble();
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
                                            milliseconds: 30),
                                        curve: Curves.easeOut,
                                        scale: index == _currentPage
                                            ? 1.0
                                            : 0.98,
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
                          _buildPageIndicator(),
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
