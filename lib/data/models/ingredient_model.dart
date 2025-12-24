class IngredientModel {
  final String? id;
  final String emoji;
  final String name;
  final int match;

  IngredientModel({
    this.id,
    required this.emoji,
    required this.name,
    required this.match,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMatch = json['match'];
    int parsedMatch;

    if (rawMatch is int) {
      parsedMatch = rawMatch;
    } else if (rawMatch is String) {
      parsedMatch = int.tryParse(rawMatch) ?? 0;
    } else {
      parsedMatch = 0;
    }

    return IngredientModel(
      id: json['id']?.toString(),
      emoji: (json['emoji'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      match: parsedMatch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'emoji': emoji,
      'name': name,
      'match': match,
    };
  }
}

