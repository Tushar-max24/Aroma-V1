// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flavoryx/ui/screens/auth/auth_wrapper.dart';
import 'package:flavoryx/core/config/app_config.dart';
import 'package:flavoryx/state/pantry_state.dart';
import 'package:flavoryx/state/home_provider.dart';
import 'package:flavoryx/data/services/gemini_recipe_service.dart';
import 'package:flavoryx/data/services/shopping_list_service.dart';
import 'package:flavoryx/core/services/auth_service.dart';
import 'package:flavoryx/ui/screens/auth/login_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize app configuration
    await AppConfig().init();
    
    // Initialize Gemini service
    GeminiRecipeService.initialize();
    
    // Initialize AuthService
    final authService = AuthService();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => authService..initialize(),
          ),
          ChangeNotifierProvider(create: (_) => ShoppingListService()),
          ChangeNotifierProvider(create: (_) => PantryState()..loadPantry()),
          ChangeNotifierProvider(create: (_) => HomeProvider()..loadRecipes()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error UI
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aroma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Add other theme configurations here
      ),
      home: const AuthWrapper(),
    );
  }
}