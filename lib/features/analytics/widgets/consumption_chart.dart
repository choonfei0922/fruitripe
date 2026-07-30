import 'package:flutter/material.dart';

import 'package:fruitripe/models/waste_summary.dart';

class ConsumptionChart extends StatelessWidget {
  const ConsumptionChart({super.key, required this.months});

  final List<MonthTally> months;

  static const _consumedColour = Color(0xFF2E7D32);
  static const _discardedColour = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();

    final maxTotal =
    months.fold<int>(0, (a, m) => m.totalCount > a ? m.totalCount : a);
    final safeMax = maxTotal <= 0 ? 1 : maxTotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consumption over time',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Items you finished versus items that spoiled.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final consumedH = (m.consumedCount / safeMax) * 105;
                final discardedH = (m.discardedCount / safeMax) * 105;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          m.totalCount == 0 ? '' : '${m.totalCount}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) => Column(
                            children: [
                              Container(
                                height: discardedH * t,
                                decoration: const BoxDecoration(
                                  color: _discardedColour,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              Container(
                                height: consumedH * t,
                                decoration: BoxDecoration(
                                  color: _consumedColour,
                                  borderRadius: discardedH == 0
                                      ? const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  )
                                      : null,
                                ),
                              ),
                              if (m.totalCount == 0)
                                Container(
                                  height: 3,
                                  color: Theme.of(context).disabledColor,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.shortLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: const [
              _Legend(colour: _consumedColour, label: 'Consumed'),
              SizedBox(width: 16),
              _Legend(colour: _discardedColour, label: 'Discarded'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}