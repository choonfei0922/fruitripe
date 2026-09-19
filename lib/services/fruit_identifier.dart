import 'dart:io';
import 'dart:math';

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

/// Contract for fruit identification. Swap [MockFruitIdentifier] for a real
/// TFLite/YOLOv8-backed implementation once the trained model is ready —
/// ScanService, the provider, and the UI don't need to change.
abstract class FruitIdentifier {
  /// Preprocesses and detects fruit in [image]. Returns one candidate per
  /// detected fruit — a single-scan flow uses candidates.first, while the
  /// batch_analysis module can iterate over all of them later.
  Future<List<FruitCandidate>> identify(File image);
}

/// Temporary stand-in until the CNN/YOLOv8 model is trained and bundled.
/// Simulates processing latency and cycles through canned outcomes —
/// including both alternative flows — so the UI can be built and tested now.
class MockFruitIdentifier implements FruitIdentifier {
  final Random _random;
  int _callCount = 0;

  MockFruitIdentifier({Random? random}) : _random = random ?? Random();

  static const _supportedSamples = [
    ('Avocado Hass', 0.89),
    ('Apple', 0.94),
    ('Banana', 0.91),
  ];

  @override
  Future<List<FruitCandidate>> identify(File image) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _callCount++;

    // Every 5th call simulates "no fruit detected" so that flow can be tested.
    if (_callCount % 5 == 0) {
      throw NoFruitDetectedException();
    }
    // Every 7th call simulates an unsupported fruit type.
    if (_callCount % 7 == 0) {
      throw UnsupportedFruitTypeException('Dragon Fruit');
    }

    final sample = _supportedSamples[_random.nextInt(_supportedSamples.length)];
    return [
      FruitCandidate(
        type: sample.$1,
        confidence: sample.$2,
        boundingBox: const BoundingBox(x: 0.2, y: 0.25, width: 0.6, height: 0.5),
      ),
    ];
  }
}

/// Trivial identifier for the current MVP scope: FruitRipe only supports
/// bananas for now, so there's no real multi-species detection happening —
/// this just assumes every scanned image is a banana and hands off
/// immediately to RipenessAnalyzer for the actual classification work.
/// Swap this for a real multi-species model later; ScanService, the
/// provider, and the UI won't need to change.
class BananaOnlyIdentifier implements FruitIdentifier {
  @override
  Future<List<FruitCandidate>> identify(File image) async {
    return [
      FruitCandidate(
        type: 'Banana',
        confidence: 1.0,
        boundingBox: const BoundingBox(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
      ),
    ];
  }
}