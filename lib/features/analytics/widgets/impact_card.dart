import 'package:flutter/material.dart';

import 'package:fruitripe/models/waste_summary.dart';

class ImpactCard extends StatelessWidget {
  const ImpactCard({super.key, required this.summary});

  final WasteSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E3F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact Score',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total fruit waste reduced: ${_formatWeight(summary.weightSavedKg)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary.totalConsumed == 0
                ? 'Start marking fruit as consumed to build your impact score.'
                : "You've saved ${summary.totalConsumed} "
                "${summary.totalConsumed == 1 ? 'item' : 'items'} "
                'from reaching the landfill.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatWeight(double kg) {
    if (kg <= 0) return '0 kg';
    if (kg < 1) return '${(kg * 1000).toStringAsFixed(0)} g';
    return '${kg.toStringAsFixed(kg < 10 ? 1 : 0)} kg';
  }
}

class EfficiencyCard extends StatelessWidget {
  const EfficiencyCard({super.key, required this.summary});

  final WasteSummary summary;

  @override
  Widget build(BuildContext context) {
    final efficiency = summary.efficiency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, size: 32, color: Color(0xFF1B5E3F)),
          const SizedBox(height: 10),
          Text(
            efficiency == null
                ? '—'
                : '${(efficiency * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E3F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Efficiency Rate',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            efficiency == null
                ? 'No items resolved yet'
                : '${summary.totalConsumed} eaten · '
                '${summary.totalDiscarded} discarded',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}