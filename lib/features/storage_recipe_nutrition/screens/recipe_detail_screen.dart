import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/services/information_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
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

    final previous = _saved;
    setState(() => _saved = !previous);

    try {
      if (previous) {
        await _service.unsaveRecipe(widget.recipe.recipeId);
      } else {
        await _service.saveRecipe(widget.recipe.recipeId);
      }
      if (!mounted) return;
      // M1: Msg Recipe Saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(previous
              ? 'Removed from favourites.'
              : 'Recipe added to your favourites successfully!'),
          backgroundColor: previous ? null : const Color(0xFF1B5E3F),
        ),
      );
    } on InformationFailure catch (e) {
      if (!mounted) return;
      setState(() => _saved = previous);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSource() async {
    final url = widget.recipe.recipeUrl;
    if (url == null) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final steps = r.steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe'),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (r.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                r.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (r.hasImage) const SizedBox(height: 16),

          Text(
            r.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(icon: Icons.schedule, label: r.prepTimeLabel),
              _Badge(icon: Icons.eco_outlined, label: r.suitableStage.label),
              if (r.isRescueRecipe)
                const _Badge(
                  icon: Icons.recycling,
                  label: 'Uses imperfect fruit',
                  highlight: true,
                ),
            ],
          ),

          if (r.isRescueRecipe) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.recycling, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This recipe is designed for overripe or cosmetically '
                            'imperfect fruit that might otherwise be thrown away.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Instructions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          if (steps.isEmpty)
            Text(
              'No instructions have been added for this recipe yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...steps.map(
                  (s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(s, style: const TextStyle(height: 1.6, fontSize: 14)),
              ),
            ),

          if (r.recipeUrl != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openSource,
              icon: const Icon(Icons.open_in_new),
              label: const Text('View original source'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}