import 'package:flutter/material.dart';
import '../data/services/mongo_ingredient_service.dart';

class TestMongoScreen extends StatefulWidget {
  @override
  _TestMongoScreenState createState() => _TestMongoScreenState();
}

class _TestMongoScreenState extends State<TestMongoScreen> {
  String _status = "Ready to test MongoDB connection";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MongoDB Test"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _status,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _testConnection,
                    child: Text("Test Connection"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _testStoreIngredient,
                    child: Text("Test Store Ingredient"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _testStoreMultiple,
                    child: Text("Test Store Multiple Ingredients"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = "Testing connection...";
    });

    try {
      final connected = await MongoIngredientService.testConnection();
      setState(() {
        _status = connected ? "✅ Connected successfully!" : "❌ Connection failed";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _testStoreIngredient() async {
    setState(() {
      _isLoading = true;
      _status = "Testing single ingredient storage...";
    });

    try {
      final testIngredient = {
        "item": "Test Carrot",
        "quantity": 2,
        "metrics": "pcs",
        "imageURL": "http://example.com/carrot.jpg",
        "match%": 95,
      };

      final success = await MongoIngredientService.storeScanBillIngredients([testIngredient]);
      setState(() {
        _status = success ? "✅ Ingredient stored successfully!" : "❌ Failed to store ingredient";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _testStoreMultiple() async {
    setState(() {
      _isLoading = true;
      _status = "Testing multiple ingredient storage...";
    });

    try {
      final testIngredients = [
        {
          "item": "Test Tomato",
          "quantity": 3,
          "metrics": "pcs",
          "imageURL": "http://example.com/tomato.jpg",
          "match%": 90,
        },
        {
          "item": "Test Onion",
          "quantity": 1,
          "metrics": "pcs",
          "imageURL": "http://example.com/onion.jpg",
          "match%": 88,
        },
      ];

      final success = await MongoIngredientService.storeScanBillIngredients(testIngredients);
      setState(() {
        _status = success ? "✅ Multiple ingredients stored successfully!" : "❌ Failed to store ingredients";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error: $e";
        _isLoading = false;
      });
    }
  }
}
