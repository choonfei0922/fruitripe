import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/inventory_fruit.dart';
import 'package:fruitripe/features/inventory/widgets/fruit_image.dart';
import 'package:fruitripe/features/inventory/widgets/shelf_life_bar.dart';

class FruitCard extends StatelessWidget {
  const FruitCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final InventoryFruit item;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF14261C);
  static const _muted = Color(0xFF6B7F70);
  static const _critical = Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    final days = item.daysRemaining;
    final accent = item.isCritical
        ? _critical
        : ShelfLifeBar.colorForFraction(item.lifeElapsedFraction);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: item.isCritical
                    ? const Color(0xFFF0C4BE)
                    : const Color(0xFFE2EADF),
                width: item.isCritical ? 1.4 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    children: [
                      FruitImage(item: item, size: 132),
                      if (item.isCritical)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: _critical,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.priority_high,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fruitName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.quantity > 1
                                ? '${item.ripenessStage.label}  ·  ×${item.quantity}'
                                : item.ripenessStage.label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _expiryCaption(days),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _expiryValue(days),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ShelfLifeBar(item: item, height: 6, showLabel: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _expiryCaption(int days) {
    if (days < 0) return 'EXPIRED';
    if (days == 0) return 'EAT';
    return 'EXPIRES IN';
  }

  static String _expiryValue(int days) {
    if (days < 0) return 'Past best';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day';
    return '$days days';
  }
}