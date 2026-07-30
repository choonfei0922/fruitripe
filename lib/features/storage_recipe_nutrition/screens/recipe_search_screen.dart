import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/services/information_service.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/recipe_detail_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/widgets/recipe_card.dart';

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final _service = InformationService();
  final _searchCtrl = TextEditingController();

  Timer? _debounce;
  List<Recipe> _results = [];
  bool _loading = true;
  String? _error;

  bool _rescueOnly = true;
  RipenessStage? _stageFilter;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Waits 350ms after the last keystroke before querying, so
  /// typing "banana" fires one request rather than six.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _service.searchRecipes(
        keyword: _searchCtrl.text,
        stage: _stageFilter,
        rescueOnly: _rescueOnly,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on InformationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Recipes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search by recipe name',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search();
                  },
                ),
              ),
            ),
          ),

          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('Imperfect produce'),
                  avatar: const Icon(Icons.recycling, size: 16),
                  selected: _rescueOnly,
                  onSelected: (v) {
                    setState(() => _rescueOnly = v);
                    _search();
                  },
                ),
                const SizedBox(width: 8),
                ...RipenessStage.values.map((s) {
                  final selected = _stageFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.label),
                      selected: selected,
                      onSelected: (v) {
                        setState(() => _stageFilter = v ? s : null);
                        _search();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 16),

          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
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
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _search,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 56,
                              color: Theme.of(context).disabledColor),
                          const SizedBox(height: 16),
                          const Text('No recipes found',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            'Try clearing a filter or searching for '
                                'something else.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return RecipeCard(
                      recipe: r,
                      onSavedChanged: _search,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: r),
                      ))
                          .then((_) => _search()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}