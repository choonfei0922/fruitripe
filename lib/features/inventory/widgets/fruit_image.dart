import 'package:flutter/material.dart';

import 'package:fruitripe/models/inventory_fruit.dart';

class FruitImage extends StatelessWidget {
  const FruitImage({
    super.key,
    required this.item,
    this.size = 132,
    this.circle = true,
  });

  final InventoryFruit item;
  final double size;
  final bool circle;

  bool get _hasPhoto =>
      item.imageUrl != null && item.imageUrl!.startsWith('http');

  double get _radius => circle ? size / 2 : size * 0.18;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: _hasPhoto
          ? Image.network(
        item.imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : _placeholder(),
        errorBuilder: (_, __, ___) => _fallback(),
      )
          : _fallback(),
    );
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    color: const Color(0xFFEDF4EA),
  );

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDF4EA), Color(0xFFDCE9D8)],
      ),
    ),
    child: Center(
      child: Text(
        emojiFor(item.fruitName),
        style: TextStyle(fontSize: size * 0.44),
      ),
    ),
  );

  /// Stand-in for fruits with no uploaded photo.
  static String emojiFor(String name) {
    switch (name.trim().toLowerCase()) {
      case 'apple':
        return '🍎';
      case 'banana':
        return '🍌';
      case 'grape':
        return '🍇';
      case 'mango':
        return '🥭';
      case 'melon':
        return '🍈';
      case 'orange':
        return '🍊';
      case 'peach':
        return '🍑';
      case 'pear':
        return '🍐';
      default:
        return '🍏';
    }
  }
}