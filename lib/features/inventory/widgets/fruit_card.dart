import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/inventory_fruit.dart';
import 'package:fruitripe/features/inventory/widgets/shelf_life_bar.dart';

class FruitCard extends StatelessWidget {
  const FruitCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final InventoryFruit item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isCritical
              ? const Color(0xFFE8933D)
              : const Color(0xFFDCE5DA),
          width: item.isCritical ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumb(item: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.fruitName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3527),
                            ),
                          ),
                        ),
                        if (item.quantity > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F6EF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('×${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5F7264))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.ripenessStage.label,
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF5F7264)),
                    ),
                    const SizedBox(height: 10),
                    ShelfLifeBar(item: item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});
  final InventoryFruit item;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          item.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(size),
        ),
      );
    }
    return _fallback(size);
  }

  Widget _fallback(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6EF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.eco, color: Color(0xFF4CAF6D)),
  );
}
