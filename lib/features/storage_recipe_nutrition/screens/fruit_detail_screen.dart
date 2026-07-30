import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_reference.dart';
import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/stage_picker_screen.dart'
    show stageColour;
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/nutrition_section.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/recipe_list_section.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/storage_section.dart';

class FruitDetailScreen extends StatefulWidget {
  const FruitDetailScreen({
    super.key,
    required this.fruitType,
    required this.stage,
  });

  final FruitType fruitType;
  final RipenessStage stage;

  @override
  State<FruitDetailScreen> createState() => _FruitDetailScreenState();
}

class _FruitDetailScreenState extends State<FruitDetailScreen> {
  final _service = InformationService();
  late Future<FruitReference> _future;
  late RipenessStage _stage;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _load();
  }

  void _load() {
    _future = _service.fetchReference(
      fruitType: widget.fruitType,
      stage: _stage,
    );
  }

  /// Lets you flip between stages without going back. Handy for a
  /// demo, and it is how the maturation comparison is explored.
  void _changeStage(RipenessStage stage) {
    setState(() {
      _stage = stage;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colour = stageColour(_stage);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fruitType.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.kitchen_outlined), text: 'Storage'),
              Tab(icon: Icon(Icons.monitor_heart_outlined), text: 'Nutrition'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Recipes'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Stage selector strip.
            Container(
              width: double.infinity,
              color: colour.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colour,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currently viewing: ${_stage.label}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colour,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    alignment: WrapAlignment.center,
                    children: RipenessStage.values.map((s) {
                      final selected = s == _stage;
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: selected,
                        onSelected: (_) => _changeStage(s),
                        selectedColor: stageColour(s).withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<FruitReference>(
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
                            Text(
                              snap.error.toString(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => setState(_load),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final ref = snap.data!;
                  return TabBarView(
                    children: [
                      StorageSection(reference: ref),
                      NutritionSection(reference: ref),
                      RecipeListSection(
                        reference: ref,
                        onChanged: () => setState(_load),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}