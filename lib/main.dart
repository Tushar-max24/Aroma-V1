// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flavoryx/ui/screens/auth/login_screen.dart';
import 'core/config/app_config.dart';
import 'state/pantry_state.dart';
import 'state/home_provider.dart';
import 'data/services/gemini_recipe_service.dart';
import 'ui/screens/home/home_screen.dart';
import 'data/services/shopping_list_service.dart';


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
    
    runApp(
      MultiProvider(
        providers: [
          // Add all your providers here
          ChangeNotifierProvider(create: (_) => ShoppingListService()),
          ChangeNotifierProvider(create: (_) => PantryState()..loadPantry()),
          ChangeNotifierProvider(create: (_) => HomeProvider()..loadRecipes()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Enhanced error handling with stack trace
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    // Restart the app
                    main();
                  },
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
      home: const LoginScreen(),
    );
  }
}