import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';

class NutrientBarChart extends StatelessWidget {
  const NutrientBarChart({
    super.key,
    required this.title,
    required this.unit,
    required this.values,
    required this.highlightStage,
    this.colour = const Color(0xFF1B5E3F),
  });

  final String title;

  final String unit;

  final Map<RipenessStage, double> values;

  final RipenessStage highlightStage;

  final Color colour;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    // Guard against divide-by-zero when every value is 0.
    final maxValue = values.values.fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    // Keep the ripening order, not map insertion order.
    final ordered = RipenessStage.values
        .where((s) => values.containsKey(s))
        .toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'per 100 g',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ordered.map((stage) {
                  final value = values[stage]!;
                  final fraction = (value / safeMax).clamp(0.0, 1.0);
                  final isHighlight = stage == highlightStage;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _format(value),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isHighlight
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isHighlight
                                  ? colour
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Animates when the user switches stage.
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => Container(
                              height: 80 * t,
                              decoration: BoxDecoration(
                                color: isHighlight
                                    ? colour
                                    : colour.withValues(alpha: 0.30),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stage.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isHighlight
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 4),
            Text(
              'Measured in $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}