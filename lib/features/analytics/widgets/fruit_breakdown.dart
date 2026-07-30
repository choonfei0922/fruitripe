import 'package:flutter/material.dart';

import 'package:fruitripe/models/waste_summary.dart';

class FruitBreakdown extends StatelessWidget {
  const FruitBreakdown({super.key, required this.summary});

  final WasteSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.byFruit.isEmpty) return const SizedBox.shrink();

    final mostWasted = summary.mostWasted;
    final mostConsumed = summary.mostConsumed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By fruit type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'How much of each fruit you finished.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        ...summary.byFruit.map((f) => _FruitRow(tally: f)),

        if (mostConsumed.isNotEmpty || mostWasted.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (mostConsumed.isNotEmpty)
                Expanded(
                  child: _HighlightTile(
                    icon: Icons.emoji_events_outlined,
                    colour: const Color(0xFF2E7D32),
                    label: 'Most consumed',
                    fruitName: mostConsumed.first.fruitName,
                    count: mostConsumed.first.consumedCount,
                  ),
                ),
              if (mostConsumed.isNotEmpty && mostWasted.isNotEmpty)
                const SizedBox(width: 10),
              if (mostWasted.isNotEmpty)
                Expanded(
                  child: _HighlightTile(
                    icon: Icons.delete_outline,
                    colour: const Color(0xFFC62828),
                    label: 'Most wasted',
                    fruitName: mostWasted.first.fruitName,
                    count: mostWasted.first.discardedCount,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FruitRow extends StatelessWidget {
  const _FruitRow({required this.tally});

  final FruitTally tally;

  @override
  Widget build(BuildContext context) {
    final efficiency = tally.efficiency ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tally.fruitName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '${tally.consumedCount} eaten · ${tally.discardedCount} wasted',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (efficiency * 100).round().clamp(0, 100),
                    child: Container(color: const Color(0xFF2E7D32)),
                  ),
                  Expanded(
                    flex: (100 - efficiency * 100).round().clamp(0, 100),
                    child: Container(color: const Color(0xFFC62828)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.icon,
    required this.colour,
    required this.label,
    required this.fruitName,
    required this.count,
  });

  final IconData icon;
  final Color colour;
  final String label;
  final String fruitName;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colour),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            fruitName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            '$count ${count == 1 ? 'item' : 'items'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}