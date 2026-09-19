import 'dart:io';

import '../core/enums.dart';

/// Raw model output, before the caller wraps it into an AnalysisResult.
class RipenessPrediction {
  final RipenessStage stage;
  final double confidence; // 0.0–1.0

  const RipenessPrediction({required this.stage, required this.confidence});
}

/// FR 2.1–2.4 (Ripeness Analysis) — extension point, no implementation.
/// Only reached when an identifier returns a species-only label; YOLO
/// answers ripeness directly for all 8 species.
abstract class RipenessAnalyzer {
  Future<RipenessPrediction> analyze({
    required File image,
    required String fruitType,
  });
}