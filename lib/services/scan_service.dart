import 'dart:io';

import '../models/analysis_result.dart';
import '../models/fruit.dart';
import '../models/prediction.dart';
import '../models/scan.dart';
import 'fruit_identifier.dart';
import 'fruit_result_builder.dart';
import 'ripeness_analyzer.dart';
import 'shelf_life_predictor.dart';
import 'yolo_fruit_identifier.dart';

sealed class ScanOutcome {
  const ScanOutcome();
}

class ScanSuccess extends ScanOutcome {
  final Scan scan;
  final Fruit fruit;
  final double identificationConfidence;
  final AnalysisResult analysisResult;
  final Prediction prediction;

  const ScanSuccess({
    required this.scan,
    required this.fruit,
    required this.identificationConfidence,
    required this.analysisResult,
    required this.prediction,
  });
}

/// UC101 Alternative Flow A1.
class ScanNoFruitDetected extends ScanOutcome {
  const ScanNoFruitDetected();
}

/// UC101 Alternative Flow A2.
class ScanUnsupportedFruitType extends ScanOutcome {
  final String detectedLabel;
  const ScanUnsupportedFruitType(this.detectedLabel);
}

class ScanFailed extends ScanOutcome {
  final String message;
  const ScanFailed(this.message);
}

class ScanService {
  final FruitIdentifier _identifier;
  final FruitResultBuilder _resultBuilder;

  ScanService({
    FruitIdentifier? identifier,
    RipenessAnalyzer? ripenessAnalyzer,
    ShelfLifePredictor? shelfLifePredictor,
  })  : _identifier = identifier ?? YoloFruitIdentifier(),
        _resultBuilder = FruitResultBuilder(
          ripenessAnalyzer: ripenessAnalyzer,
          shelfLifePredictor: shelfLifePredictor,
        );

  Future<ScanOutcome> processImage({
    required File image,
    required String userId,
  }) async {
    final scanId = _generateId('scan');

    try {
      final candidates = await _identifier.identify(image);

      if (candidates.isEmpty) {
        return const ScanNoFruitDetected();
      }

      final scan = Scan(
        scanId: scanId,
        imageUrl: image.path,
        timestamp: DateTime.now(),
        userId: userId,
      );

      final result = await _resultBuilder.build(
        candidate: candidates.first,
        image: image,
        scanId: scanId,
        idSuffix: '0',
      );

      return ScanSuccess(
        scan: scan,
        fruit: result.fruit,
        identificationConfidence: result.identificationConfidence,
        analysisResult: result.analysisResult,
        prediction: result.prediction,
      );
    } on NoFruitDetectedException {
      return const ScanNoFruitDetected();
    } on UnsupportedFruitTypeException catch (e) {
      return ScanUnsupportedFruitType(e.detectedLabel);
    } on FruitResultBuildException catch (e) {
      return ScanFailed(e.message);
    } catch (e) {
      return ScanFailed(e.toString());
    }
  }

  String _generateId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}