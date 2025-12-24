// lib/data/models/recipe_model.dart
class RecipeModel {
  final String id;
  final String title;
  final String cuisine;
  final String cookTime;
  final String image;
  final bool isSaved;

  RecipeModel({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.cookTime,
    required this.image,
    this.isSaved = false,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Recipe',
      cuisine: json['cuisine'] ?? 'Unknown Cuisine',
      cookTime: json['cookTime']?.toString() ?? 'N/A',
      image: json['image'] ?? '',
      isSaved: json['isSaved'] ?? false,
    );
  }

  RecipeModel copyWith({
    String? id,
    String? title,
    String? cuisine,
    String? cookTime,
    String? image,
    bool? isSaved,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      cuisine: cuisine ?? this.cuisine,
      cookTime: cookTime ?? this.cookTime,
      image: image ?? this.image,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'cuisine': cuisine,
      'cookTime': cookTime,
      'image': image,
      'isSaved': isSaved,
    };
  }
}