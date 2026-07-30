import 'package:flutter/material.dart';

import 'package:fruitripe/models/fruit_reference.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/recipe_detail_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/recipe_card.dart';

class RecipeListSection extends StatelessWidget {
  const RecipeListSection({
    super.key,
    required this.reference,
    required this.onChanged,
  });

  final FruitReference reference;

  /// Called after a save toggle so the parent can refetch.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final matching = reference.recipesForStage;
    final others = reference.otherRecipes;

    if (matching.isEmpty && others.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu,
                  size: 56, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              const Text('No recipes yet',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'No recipes have been added for '
                    '${reference.fruitType.name.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    void open(recipe) {
      Navigator.of(context)
          .push(MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      ))
          .then((_) => onChanged());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (matching.isNotEmpty) ...[
          Text(
            'Best for ${reference.stage.label.toLowerCase()} '
                '${reference.fruitType.name.toLowerCase()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...matching.map(
                (r) => RecipeCard(
              recipe: r,
              onTap: () => open(r),
              onSavedChanged: onChanged,
            ),
          ),
        ],

        // Alternate flow A1: nothing matched this stage.
        if (matching.isEmpty && others.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No recipes specifically for the '
                        '${reference.stage.label.toLowerCase()} stage. '
                        'Here is everything else for '
                        '${reference.fruitType.name.toLowerCase()}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

        if (others.isNotEmpty) ...[
          if (matching.isNotEmpty) const SizedBox(height: 20),
          Text(
            matching.isEmpty ? 'All recipes' : 'At other ripeness stages',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...others.map(
                (r) => RecipeCard(
              recipe: r,
              onTap: () => open(r),
              onSavedChanged: onChanged,
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}