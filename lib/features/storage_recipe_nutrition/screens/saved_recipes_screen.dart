import 'package:flutter/material.dart';

import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/recipe_detail_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/recipe_card.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  final _service = InformationService();
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchSavedRecipes();
  }

  void _reload() {
    setState(() => _future = _service.fetchSavedRecipes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      body: FutureBuilder<List<Recipe>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(snap.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final recipes = snap.data ?? [];

          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 56, color: Theme.of(context).disabledColor),
                    const SizedBox(height: 16),
                    const Text('No saved recipes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart on any recipe to save it here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, i) {
                final r = recipes[i];
                return RecipeCard(
                  recipe: r,
                  // Removing a favourite here should drop it from
                  // the list immediately.
                  onSavedChanged: _reload,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: r),
                  ))
                      .then((_) => _reload()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}