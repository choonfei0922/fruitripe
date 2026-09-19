import 'dart:io';

import '../core/enums.dart';

class RipenessPrediction {
  final RipenessStage stage;
  final double confidence; // 0.0–1.0

  const RipenessPrediction({required this.stage, required this.confidence});
}

abstract class RipenessAnalyzer {
  Future<RipenessPrediction> analyze({
    required File image,
    required String fruitType,
  });
}