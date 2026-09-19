import '../core/enums.dart';

class AnalysisResult {
  final String resultId;
  final RipenessStage ripenessStage;
  final double confidenceScore; // 0.0–1.0
  final String justification;
  final String fruitId;

  const AnalysisResult({
    required this.resultId,
    required this.ripenessStage,
    required this.confidenceScore,
    required this.justification,
    required this.fruitId,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> map) => AnalysisResult(
    resultId: map['resultId'] as String,
    ripenessStage:
    RipenessStage.values.byName(map['ripenessStage'] as String),
    confidenceScore: (map['confidenceScore'] as num).toDouble(),
    justification: map['justification'] as String,
    fruitId: map['fruitId'] as String,
  );

  Map<String, dynamic> toMap() => {
    'resultId': resultId,
    'ripenessStage': ripenessStage.name,
    'confidenceScore': confidenceScore,
    'justification': justification,
    'fruitId': fruitId,
  };
}