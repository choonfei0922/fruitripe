import 'package:fruitripe/core/enums.dart';

class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.scanId,
    required this.imageUrl,
    required this.scanDate,
    required this.isBatch,
    required this.fruits,
  });

  final int scanId;
  final String imageUrl;
  final DateTime scanDate;
  final bool isBatch;
  final List<ScanHistoryFruit> fruits;

  bool get hasPhoto => imageUrl.startsWith('http');

  int get correctionCount => fruits.where((f) => f.wasCorrected).length;

  factory ScanHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawFruits = (map['fruit'] as List?) ?? const [];

    return ScanHistoryEntry(
      scanId: (map['scan_id'] as num).toInt(),
      imageUrl: map['image_url'] as String? ?? '',
      scanDate: DateTime.parse(map['scan_date'] as String).toLocal(),
      isBatch: map['is_batch'] as bool? ?? false,
      fruits: rawFruits
          .map((f) => ScanHistoryFruit.fromMap(f as Map<String, dynamic>))
          .where((f) => f != null)
          .cast<ScanHistoryFruit>()
          .toList(),
    );
  }
}

class ScanHistoryFruit {
  const ScanHistoryFruit({
    required this.fruitId,
    required this.resultId,
    required this.fruitName,
    required this.stage,
    required this.confidence,
    required this.daysUntilSpoil,
    required this.bestConsumeDate,
    required this.correctedStage,
  });

  final int fruitId;
  final int resultId;

  /// Null when the scan hit an unsupported type, which the schema
  /// allows via a nullable fruit_type_id.
  final String? fruitName;

  /// What the model said. A correction never overwrites this - see
  /// [correctedStage].
  final RipenessStage stage;

  /// 0-100 as stored, not the 0-1 the model reports.
  final double confidence;

  final int? daysUntilSpoil;
  final DateTime? bestConsumeDate;

  /// What the user said instead, or null if they agreed.
  final RipenessStage? correctedStage;

  bool get wasCorrected => correctedStage != null;

  /// What to show: the user's answer wins over the model's.
  RipenessStage get displayedStage => correctedStage ?? stage;

  /// PostgREST returns a to-one relationship as an object, but a
  /// to-many as a list. analysis_result, prediction and user_feedback
  /// are all to-one here because their foreign keys are UNIQUE -
  /// still worth handling both, since losing the constraint would
  /// otherwise turn a parse into a silent empty history.
  static Map<String, dynamic>? _one(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  static ScanHistoryFruit? fromMap(Map<String, dynamic> map) {
    final analysis = _one(map['analysis_result']);
    // A fruit row with no analysis means the save chain broke partway.
    // Nothing useful to show, so drop it rather than render a blank.
    if (analysis == null) return null;

    final prediction = _one(analysis['prediction']);
    final feedback = _one(analysis['user_feedback']);
    final type = _one(map['fruit_type']);

    return ScanHistoryFruit(
      fruitId: (map['fruit_id'] as num).toInt(),
      resultId: (analysis['result_id'] as num).toInt(),
      fruitName: type?['name'] as String?,
      stage: RipenessStage.values
          .byName(analysis['ripeness_stage'] as String),
      confidence: (analysis['confidence_score'] as num?)?.toDouble() ?? 0,
      daysUntilSpoil: (prediction?['days_until_spoil'] as num?)?.toInt(),
      bestConsumeDate: prediction?['best_consume_date'] == null
          ? null
          : DateTime.parse(prediction!['best_consume_date'] as String),
      correctedStage: feedback?['corrected_stage'] == null
          ? null
          : RipenessStage.values
          .byName(feedback!['corrected_stage'] as String),
    );
  }
}