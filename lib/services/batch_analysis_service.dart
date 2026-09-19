import 'dart:io';

import '../models/scan.dart';
import 'fruit_identifier.dart';
import 'fruit_result_builder.dart';
import 'ripeness_analyzer.dart';
import 'shelf_life_predictor.dart';
import 'yolo_fruit_identifier.dart';

sealed class BatchOutcome {
  const BatchOutcome();
}

class BatchSuccess extends BatchOutcome {
  final Scan scan;
  final List<FruitResult> results;
  const BatchSuccess({required this.scan, required this.results});
}

class BatchNoFruitDetected extends BatchOutcome {
  const BatchNoFruitDetected();
}

class BatchFailed extends BatchOutcome {
  final String message;
  const BatchFailed(this.message);
}

/// Orchestrates the Multi-Fruit Batch Analysis Module (UC400/UC401).
class BatchAnalysisService {
  final FruitIdentifier _identifier;
  final FruitResultBuilder _resultBuilder;

  BatchAnalysisService({
    FruitIdentifier? identifier,
    RipenessAnalyzer? ripenessAnalyzer,
    ShelfLifePredictor? shelfLifePredictor,
  })  : _identifier = identifier ?? YoloFruitIdentifier(),
        _resultBuilder = FruitResultBuilder(
          ripenessAnalyzer: ripenessAnalyzer,
          shelfLifePredictor: shelfLifePredictor,
        );

  Future<BatchOutcome> processBatchImage({
    required File image,
    required String userId,
  }) async {
    final scanId = _generateId('scan');

    try {
      final candidates = await _identifier.identify(image);

      if (candidates.isEmpty) {
        return const BatchNoFruitDetected();
      }

      final scan = Scan(
        scanId: scanId,
        imageUrl: image.path,
        timestamp: DateTime.now(),
        userId: userId,
      );

      final results = <FruitResult>[];

      for (var i = 0; i < candidates.length; i++) {
        try {
          final result = await _resultBuilder.build(
            candidate: candidates[i],
            image: image,
            scanId: scanId,
            idSuffix: '$i',
          );
          results.add(result);
        } on FruitResultBuildException {
          continue;
        }
      }

      if (results.isEmpty) {
        return const BatchNoFruitDetected();
      }

      return BatchSuccess(scan: scan, results: results);
    } on NoFruitDetectedException {
      return const BatchNoFruitDetected();
    } on UnsupportedFruitTypeException catch (e) {
      return BatchFailed('Unsupported fruit type detected: ${e.detectedLabel}');
    } catch (e) {
      return BatchFailed(e.toString());
    }
  }

  String _generateId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}