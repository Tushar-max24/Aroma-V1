import 'dart:io';

void main() {
  final List<String> dirs = [
    'lib/core/theme',
    'lib/core/constants',
    'lib/core/utils',
    'lib/data/models',
    'lib/data/services',
    'lib/data/repositories',
    'lib/state',
    'lib/ui/screens/home',
    'lib/ui/screens/add_ingredients',
    'lib/ui/screens/preferences',
    'lib/ui/screens/recipes',
    'lib/ui/screens/recipe_detail',
    'lib/ui/screens/cooking_steps',
    'lib/ui/screens/completion',
    'lib/ui/widgets',
    'lib/ui/layouts',
  ];

  final List<String> files = [
    'lib/main.dart',

    'lib/core/theme/app_colors.dart',
    'lib/core/theme/app_typography.dart',
    'lib/core/theme/app_theme.dart',

    'lib/core/constants/api_endpoints.dart',
    'lib/core/constants/asset_paths.dart',

    'lib/core/utils/formatters.dart',
    'lib/core/utils/validators.dart',

    'lib/data/models/recipe_model.dart',
    'lib/data/models/ingredient_model.dart',
    'lib/data/models/nutrition_model.dart',
    'lib/data/models/cookware_model.dart',
    'lib/data/models/review_model.dart',
    'lib/data/models/preference_model.dart',

    'lib/data/services/api_client.dart',
    'lib/data/services/recipe_api_service.dart',
    'lib/data/services/preference_api_service.dart',
    'lib/data/services/ai_recipe_service.dart',

    'lib/data/repositories/recipe_repository.dart',
    'lib/data/repositories/preference_repository.dart',

    'lib/state/home_provider.dart',
    'lib/state/ingredient_scan_provider.dart',
    'lib/state/recipe_list_provider.dart',
    'lib/state/recipe_detail_provider.dart',
    'lib/state/cooking_steps_provider.dart',
    'lib/state/preferences_provider.dart',

    'lib/ui/screens/home/home_screen.dart',

    'lib/ui/screens/add_ingredients/ingredient_entry_screen.dart',
    'lib/ui/screens/add_ingredients/capture_preview_screen.dart',
    'lib/ui/screens/add_ingredients/review_ingredients_screen.dart',

    'lib/ui/screens/preferences/cooking_preference_screen.dart',

    'lib/ui/screens/recipes/recipe_list_screen.dart',
    'lib/ui/screens/recipes/recipe_filters_bottomsheet.dart',

    'lib/ui/screens/recipe_detail/recipe_detail_screen.dart',
    'lib/ui/screens/recipe_detail/nutrition_section.dart',
    'lib/ui/screens/recipe_detail/cookware_section.dart',
    'lib/ui/screens/recipe_detail/review_section.dart',
    'lib/ui/screens/recipe_detail/similar_recipes_section.dart',

    'lib/ui/screens/cooking_steps/cooking_steps_screen.dart',
    'lib/ui/screens/cooking_steps/step_timer_bottomsheet.dart',
    'lib/ui/screens/cooking_steps/step_ingredients_bottomsheet.dart',

    'lib/ui/screens/completion/completion_screen.dart',

    'lib/ui/widgets/recipe_card.dart',
    'lib/ui/widgets/primary_button.dart',
    'lib/ui/widgets/pill_filter_chip.dart',
    'lib/ui/widgets/rating_stars.dart',
    'lib/ui/widgets/ingredient_row.dart',
    'lib/ui/widgets/cookware_chip.dart',
    'lib/ui/widgets/timer_chip.dart',
    'lib/ui/widgets/text_fields.dart',

    'lib/ui/layouts/app_scaffold.dart',
  ];

  for (var dir in dirs) {
    Directory(dir).createSync(recursive: true);
  }

  for (var file in files) {
    File(file).createSync(recursive: true);
  }

  print('Project structure created successfully!');
}
