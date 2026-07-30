import 'package:flutter/material.dart';

import 'package:fruitripe/models/inventory_fruit.dart';

class ShelfLifeBar extends StatelessWidget {
  const ShelfLifeBar({
    super.key,
    required this.item,
    this.height = 8,
    this.showLabel = true,
  });

  final InventoryFruit item;
  final double height;
  final bool showLabel;

  static const _unripe = Color(0xFF4CAF6D);
  static const _ripe = Color(0xFFE8C43D);
  static const _overripe = Color(0xFFE8933D);
  static const _rotten = Color(0xFF7A4526);

  static Color colorForFraction(double f) {
    if (f < 0.34) return _unripe;
    if (f < 0.67) return _ripe;
    if (f < 0.9) return _overripe;
    return _rotten;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = item.lifeElapsedFraction;
    final color = colorForFraction(fraction);
    final days = item.daysRemaining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: [
              Container(height: height, color: const Color(0xFFE8ECE6)),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.02, 1.0),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            _label(days),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  String _label(int days) {
    if (days < 0) return 'Past its best';
    if (days == 0) return 'Best eaten today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}
