import 'dart:io';

import '../models/analysis_result.dart';
import '../models/fruit.dart';
import '../models/prediction.dart';
import 'fruit_identifier.dart';
import 'fruit_label_parser.dart';
import 'justification_generator.dart';
import 'ripeness_analyzer.dart';
import 'shelf_life_predictor.dart';

class FruitResult {
  final Fruit fruit;
  final double identificationConfidence;
  final AnalysisResult analysisResult;
  final Prediction prediction;

  const FruitResult({
    required this.fruit,
    required this.identificationConfidence,
    required this.analysisResult,
    required this.prediction,
  });
}

class FruitResultBuildException implements Exception {
  final String message;
  FruitResultBuildException(this.message);
}

/// Runs identify-label → parse → ripeness → shelf-life for a single
class FruitResultBuilder {
  final RipenessAnalyzer? _ripenessAnalyzer;
  final ShelfLifePredictor _shelfLifePredictor;

  FruitResultBuilder({
    RipenessAnalyzer? ripenessAnalyzer,
    ShelfLifePredictor? shelfLifePredictor,
  })  : _ripenessAnalyzer = ripenessAnalyzer,
        _shelfLifePredictor = shelfLifePredictor ?? ShelfLifePredictor();

  Future<FruitResult> build({
    required FruitCandidate candidate,
    required File image,
    required String scanId,
    required String idSuffix, // keeps IDs unique across fruit in one scan
  }) async {
    final parsed = parseFruitLabel(candidate.type);

    final fruit = Fruit(
      fruitId: _generateId('fruit', idSuffix),
      type: parsed.fruitType,
      boundingBox: candidate.boundingBox,
      scanId: scanId,
    );

    final AnalysisResult analysisResult;

    if (parsed.ripenessStage != null) {
      // UC200/UC201 already answered by the identifier itself.
      analysisResult = AnalysisResult(
        resultId: _generateId('result', idSuffix),
        ripenessStage: parsed.ripenessStage!,
        confidenceScore: candidate.confidence,
        justification: JustificationGenerator.generate(
          fruitType: fruit.type,
          stage: parsed.ripenessStage!,
          confidence: candidate.confidence,
        ),
        fruitId: fruit.fruitId,
      );
    } else if (_ripenessAnalyzer != null) {
      final ripenessPrediction = await _ripenessAnalyzer.analyze(
        image: image,
        fruitType: fruit.type,
      );
      analysisResult = AnalysisResult(
        resultId: _generateId('result', idSuffix),
        ripenessStage: ripenessPrediction.stage,
        confidenceScore: ripenessPrediction.confidence,
        justification: JustificationGenerator.generate(
          fruitType: fruit.type,
          stage: ripenessPrediction.stage,
          confidence: ripenessPrediction.confidence,
        ),
        fruitId: fruit.fruitId,
      );
    } else {
      throw FruitResultBuildException(
        'Identified "${fruit.type}" but got no ripeness stage, and no '
            'RipenessAnalyzer was provided to classify it separately.',
      );
    }

    // UC300: estimate remaining shelf-life and best-consume date.
    final shelfLifePrediction = _shelfLifePredictor.predict(
      predictId: _generateId('predict', idSuffix),
      fruitType: fruit.type,
      ripenessStage: analysisResult.ripenessStage,
      resultId: analysisResult.resultId,
    );

    return FruitResult(
      fruit: fruit,
      identificationConfidence: candidate.confidence,
      analysisResult: analysisResult,
      prediction: shelfLifePrediction,
    );
  }

  String _generateId(String prefix, String suffix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$suffix';
}