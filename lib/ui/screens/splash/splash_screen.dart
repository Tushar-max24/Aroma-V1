import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../state/home_provider.dart';
import '../../../data/services/app_initialization_service.dart';
import '../../../data/services/splash_state_service.dart';
import '../../../data/services/app_state_service.dart';

import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  final AuthService? authService;
  
  const SplashScreen({
    super.key,
    this.authService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _initStatus = 'Initializing app...';
  double _progress = 0.0;
  
  // Dynamic engaging messages for different phases
  final List<String> _engagingMessages = [
    'Preparing your culinary journey...',
    'Discovering amazing recipes...',
    'Setting up your flavor experience...',
    'Almost ready to cook...',
    'Your kitchen awaits...',
  ];
  
  // Dynamic motivational messages
  final List<String> _motivationalMessages = [
    ' Cooking up something special...',
    ' Master chefs at work...',
    ' Crafting your perfect meal...',
    ' Your flavor adventure begins...',
    ' Something delicious is coming...',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if this is first launch of the day or needs full initialization
      final needsFullInit = await SplashStateService.needsFullInitialization();
      final initDuration = SplashStateService.getInitializationDuration();
      
      if (needsFullInit) {
        setState(() {
          _initStatus = 'Setting up cache system...';
          _progress = 0.2;
        });

        // Full initialization (first launch of the day)
        print('🚀 Performing full initialization (first launch of day)');
        
        // Phase 1: Critical Services (0-3 seconds)
        final initFuture = AppInitializationService.initializeDuringSplash();
        
        // Phase 2: Auth Service (parallel)
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Phase 3: Home Provider (parallel)
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        final hasCachedRecipes = homeProvider.recipes.isNotEmpty;

        setState(() {
          _initStatus = 'Loading recipes...';
          _progress = 0.5;
        });

        // Run all initialization in parallel with minimum splash time
        await Future.wait([
          initFuture,
          if (!hasCachedRecipes) homeProvider.loadRecipes() else Future(() {}),
          Future.delayed(const Duration(seconds: 3)), // Minimum splash time
        ]);

        setState(() {
          _initStatus = 'Finalizing setup...';
          _progress = 0.8;
        });

        // Wait for auth service if still loading
        if (authService.isLoading) {
          setState(() {
            _initStatus = 'Checking authentication...';
            _progress = 0.9;
          });
          
          await Future.doWhile(() async {
            await Future.delayed(const Duration(milliseconds: 50));
            return authService.isLoading;
          });
        }

        // Get initialization stats for debugging
        final stats = AppInitializationService.initStats;
        if (stats['success'] == true) {
          print('✅ Full initialization completed in ${stats['totalTime']}ms');
          print('📊 Cache items: ${stats['finalCacheStats']?['total'] ?? 0}');
          print('🧹 Cleanup performed: ${stats['cleanupPerformed'] ?? false}');
          print('📦 Preloaded items: ${stats['preloadedItems'] ?? 0}');
        }
        
      } else {
        // Quick initialization (same day launch)
        setState(() {
          _initStatus = 'Quick resume...';
          _progress = 0.5;
        });

        print('⚡ Performing quick initialization (same day launch)');
        
        // Quick checks only - no heavy initialization
        final authService = Provider.of<AuthService>(context, listen: false);
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        
        // Only load recipes if not already loaded
        if (homeProvider.recipes.isEmpty) {
          await homeProvider.loadRecipes();
        }
        
        // Wait for auth service if still loading
        if (authService.isLoading) {
          setState(() {
            _initStatus = 'Checking authentication...';
            _progress = 0.8;
          });
          
          await Future.doWhile(() async {
            await Future.delayed(const Duration(milliseconds: 50));
            return authService.isLoading;
          });
        }
        
        // Quick splash duration
        await Future.delayed(const Duration(seconds: 2));
        
        print('⚡ Quick initialization completed');
      }

      setState(() {
        _initStatus = 'Ready!';
        _progress = 1.0;
      });

      if (!mounted) return;

      // Check if we should restore app state (recent tabs resume)
      final shouldRestore = await AppStateService.shouldRestoreState();
      final preservedState = shouldRestore ? await AppStateService.getPreservedAppState() : null;
      
      // Navigate to next screen
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (preservedState != null && authService.isAuthenticated) {
        // Restore to previous screen for recent tabs resume
        final currentScreen = preservedState['currentScreen'] as String;
        print('🔄 Restoring app state to: $currentScreen');
        
        // Mark session as active since we're resuming
        await AppStateService.saveAppState(
          currentScreen: currentScreen,
          screenData: preservedState['screenData'] as Map<String, dynamic>?,
        );
        
        // For now, navigate to home screen - you can extend this to restore specific screens
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        // Normal navigation flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => authService.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
          ),
        );
      }

    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print('Stack trace: $stackTrace');
      
      // Still navigate to app even if initialization fails
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => authService.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Lottie animation only
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Lottie.asset(
              'assets/aroma_splash.json',
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
