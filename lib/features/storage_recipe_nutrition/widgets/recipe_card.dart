import 'package:flutter/material.dart';

import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/services/information_service.dart';

class RecipeCard extends StatefulWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onSavedChanged,
  });

  final Recipe recipe;
  final VoidCallback onTap;

  final VoidCallback? onSavedChanged;

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  final _service = InformationService();
  late bool _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.recipe.isSaved;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Optimistic update - the heart responds immediately rather
    // than waiting on the network.
    final previous = _saved;
    setState(() => _saved = !previous);

    try {
      if (previous) {
        await _service.unsaveRecipe(widget.recipe.recipeId);
      } else {
        await _service.saveRecipe(widget.recipe.recipeId);
      }
      widget.onSavedChanged?.call();
    } on InformationFailure catch (e) {
      if (!mounted) return;
      setState(() => _saved = previous); // roll back
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  image: r.hasImage
                      ? DecorationImage(
                    image: NetworkImage(r.imageUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: r.hasImage
                    ? null
                    : const Icon(Icons.restaurant_menu, size: 24),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.schedule,
                          label: r.prepTimeLabel,
                        ),
                        _Chip(
                          icon: Icons.eco_outlined,
                          label: r.suitableStage.label,
                        ),
                        // FR 5.2 - flags recipes for imperfect produce.
                        if (r.isRescueRecipe)
                          const _Chip(
                            icon: Icons.recycling,
                            label: 'Rescue',
                            highlight: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  _saved ? Icons.favorite : Icons.favorite_border,
                  color: _saved ? Colors.red : null,
                ),
                tooltip: _saved ? 'Remove from favourites' : 'Save recipe',
                onPressed: _busy ? null : _toggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}