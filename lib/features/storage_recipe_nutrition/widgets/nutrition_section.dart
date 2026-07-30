import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_reference.dart';
import 'package:fruitripe/widgets/nutrition_chart.dart';

class NutritionSection extends StatelessWidget {
  const NutritionSection({super.key, required this.reference});

  final FruitReference reference;

  @override
  Widget build(BuildContext context) {
    final current = reference.nutritionForStage;
    final all = reference.allNutrition;

    if (current == null && all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_heart_outlined,
                  size: 56, color: Theme.of(context).disabledColor),
              const SizedBox(height: 16),
              const Text('No nutrition data yet',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Nutrition has not been recorded for '
                    '${reference.fruitType.name.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    /// Builds a stage -> value map for one nutrient, skipping
    /// stages where it was not recorded.
    Map<RipenessStage, double> series(double? Function(dynamic n) pick) {
      final map = <RipenessStage, double>{};
      for (final n in all) {
        final v = pick(n);
        if (v != null) map[n.ripenessStage] = v;
      }
      return map;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- FR 4.1: figures for the current stage ----
        if (current != null) ...[
          Text(
            'At the ${reference.stage.label.toLowerCase()} stage',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Per ${current.servingSizeG.toStringAsFixed(0)} g serving',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _StatTile(
                label: 'Calories',
                value: current.caloriesKcal,
                unit: 'kcal',
                icon: Icons.local_fire_department_outlined,
              ),
              _StatTile(
                label: 'Sugar',
                value: current.sugarG,
                unit: 'g',
                icon: Icons.cookie_outlined,
              ),
              _StatTile(
                label: 'Fibre',
                value: current.fibreG,
                unit: 'g',
                icon: Icons.grass_outlined,
              ),
              _StatTile(
                label: 'Vitamin C',
                value: current.vitaminCMg,
                unit: 'mg',
                icon: Icons.local_pharmacy_outlined,
              ),
              _StatTile(
                label: 'Potassium',
                value: current.potassiumMg,
                unit: 'mg',
                icon: Icons.bolt_outlined,
              ),
            ],
          ),

          // ---- FR 4.3: health advice ----
          if (current.healthNote != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        current.healthNote!,
                        style: const TextStyle(height: 1.5, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],

        // ---- FR 4.2: maturation comparison ----
        if (all.length > 1) ...[
          const SizedBox(height: 24),
          const Text(
            'How this changes as it ripens',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'The highlighted bar is the stage you are viewing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          NutrientBarChart(
            title: 'Sugar',
            unit: 'grams',
            values: series((n) => n.sugarG),
            highlightStage: reference.stage,
            colour: const Color(0xFFEF6C00),
          ),
          NutrientBarChart(
            title: 'Fibre',
            unit: 'grams',
            values: series((n) => n.fibreG),
            highlightStage: reference.stage,
            colour: const Color(0xFF2E7D32),
          ),
          NutrientBarChart(
            title: 'Vitamin C',
            unit: 'milligrams',
            values: series((n) => n.vitaminCMg),
            highlightStage: reference.stage,
            colour: const Color(0xFF1565C0),
          ),
          NutrientBarChart(
            title: 'Calories',
            unit: 'kcal',
            values: series((n) => n.caloriesKcal),
            highlightStage: reference.stage,
            colour: const Color(0xFF6A1B9A),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final double? value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            // Em dash rather than "0" when a nutrient was never
            // recorded - zero would be a lie.
            value == null ? '—' : '${_fmt(value!)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}