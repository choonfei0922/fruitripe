import 'dart:io';

import '../models/fruit.dart';

class FruitCandidate {
  final String type;
  final BoundingBox boundingBox;
  final double confidence;

  const FruitCandidate({
    required this.type,
    required this.boundingBox,
    required this.confidence,
  });
}

/// UC101 Alternative Flow A1: No Fruit Detected.
class NoFruitDetectedException implements Exception {}

/// UC101 Alternative Flow A2: Not Supported Fruit Type.
class UnsupportedFruitTypeException implements Exception {
  final String detectedLabel;
  UnsupportedFruitTypeException(this.detectedLabel);
}

/// FR 1.3 (Identification) — contract for fruit identification.
/// Implemented by YoloFruitIdentifier.
abstract class FruitIdentifier {
  Future<List<FruitCandidate>> identify(File image);
}
