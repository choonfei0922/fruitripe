import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/fruit_detail_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/recipe_search_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/saved_recipes_screen.dart';

class StagePickerScreen extends StatefulWidget {
  const StagePickerScreen({super.key});

  @override
  State<StagePickerScreen> createState() => _StagePickerScreenState();
}

class _StagePickerScreenState extends State<StagePickerScreen> {
  final _service = InformationService();
  late Future<List<FruitType>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchFruitTypes();
  }

  void _reload() {
    setState(() => _future = _service.fetchFruitTypes());
  }

  void _open(FruitType fruit, RipenessStage stage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FruitDetailScreen(fruitType: fruit, stage: stage),
      ),
    );
  }

  Future<void> _pickStage(FruitType fruit) async {
    final stage = await showModalBottomSheet<RipenessStage>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'How ripe is your ${fruit.name.toLowerCase()}?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...RipenessStage.values.map(
                  (s) => ListTile(
                leading: Icon(_stageIcon(s), color: stageColour(s)),
                title: Text(s.label),
                subtitle: Text(_stageHint(s)),
                onTap: () => Navigator.of(context).pop(s),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (stage != null && mounted) _open(fruit, stage);
  }

  static IconData _stageIcon(RipenessStage s) => switch (s) {
    RipenessStage.unripe => Icons.hourglass_top,
    RipenessStage.ripe => Icons.check_circle,
    RipenessStage.overripe => Icons.warning_amber,
    RipenessStage.rotten => Icons.dangerous,
  };

  static String _stageHint(RipenessStage s) => switch (s) {
    RipenessStage.unripe => 'Firm, green, not ready yet',
    RipenessStage.ripe => 'Yellow and ready to eat',
    RipenessStage.overripe => 'Soft, heavily speckled or brown',
    RipenessStage.rotten => 'Mould or a fermented smell',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search recipes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipeSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Saved recipes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedRecipesScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<FruitType>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return _ErrorView(
              message: snap.error.toString(),
              onRetry: _reload,
            );
          }

          final fruits = snap.data ?? [];
          if (fruits.isEmpty) {
            return const _EmptyView();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                        'Scanning is not connected yet. Pick a fruit and its '
                            'ripeness manually to see storage advice, nutrition '
                            'and recipes.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...fruits.map(
                    (f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        f.name.isEmpty ? '?' : f.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${f.scientificName ?? ''}  •  keeps ~'
                          '${f.defaultShelfLifeDays} days when ripe',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickStage(f),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shared stage colour used across the module.
Color stageColour(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => const Color(0xFF7CB342),
  RipenessStage.ripe => const Color(0xFFF9A825),
  RipenessStage.overripe => const Color(0xFFEF6C00),
  RipenessStage.rotten => const Color(0xFF6D4C41),
};

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text(
              'No fruits available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Run 03_seed_banana.sql in the Supabase SQL Editor, or add a '
                  'fruit through the admin screens.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}