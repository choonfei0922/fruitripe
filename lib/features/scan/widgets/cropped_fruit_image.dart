import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fruitripe/models/fruit.dart';

class CroppedFruitImage extends StatelessWidget {
  const CroppedFruitImage({
    super.key,
    required this.imageFile,
    required this.box,
    this.fallbackColor = const Color(0x1F000000),
    this.padding = 0.12,
  });

  final File? imageFile;

  final BoundingBox box;

  final Color fallbackColor;

  final double padding;

  static double _alignFor(double start, double extent) {
    if (extent >= 1.0) return 0.0;
    return ((2 * start / (1 - extent)) - 1).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final file = imageFile;
    if (file == null) {
      return Container(
        color: fallbackColor,
        child: const Center(
          child: Icon(Icons.eco, size: 48, color: Colors.white54),
        ),
      );
    }

    final padX = box.width * padding;
    final padY = box.height * padding;
    final left = (box.x - padX).clamp(0.0, 1.0);
    final top = (box.y - padY).clamp(0.0, 1.0);
    final w = (box.width + padX * 2).clamp(0.01, 1.0 - left);
    final h = (box.height + padY * 2).clamp(0.01, 1.0 - top);

    return ClipRect(
      child: Align(
        alignment: Alignment(_alignFor(left, w), _alignFor(top, h)),
        widthFactor: w,
        heightFactor: h,
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}