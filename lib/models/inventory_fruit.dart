import 'package:fruitripe/core/enums.dart';

class InventoryFruit {
  const InventoryFruit({
    required this.invId,
    required this.userId,
    required this.predictId,
    required this.addedDate,
    required this.expiryDate,
    required this.status,
    required this.quantity,
    required this.fruitName,
    required this.ripenessStage,
    this.estimatedWeightG,
    this.resolvedAt,
    this.daysUntilSpoilAtPrediction,
    this.bestConsumeDate,
    this.confidenceScore,
    this.imageUrl,
  });

  final int invId;
  final String userId; // UUID
  final int predictId;
  final DateTime addedDate;

  final DateTime expiryDate;

  final InventoryStatus status;
  final int quantity;
  final double? estimatedWeightG;
  final DateTime? resolvedAt;

  final String fruitName;
  final RipenessStage ripenessStage;
  final int? daysUntilSpoilAtPrediction;
  final DateTime? bestConsumeDate;
  final double? confidenceScore;
  final String? imageUrl;

  bool get isActive => status == InventoryStatus.active;

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  bool get isExpired => daysRemaining < 0;

  /// FR 3.2 "critical window" - active and due within 24h (today or already past).
  bool get isCritical => isActive && daysRemaining <= 1;

  int get totalShelfLifeDays {
    final start = DateTime(addedDate.year, addedDate.month, addedDate.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final span = exp.difference(start).inDays;
    return span < 1 ? 1 : span;
  }

  double get lifeElapsedFraction {
    final used = totalShelfLifeDays - daysRemaining;
    final f = used / totalShelfLifeDays;
    if (f.isNaN) return 1.0;
    return f.clamp(0.0, 1.0);
  }

  factory InventoryFruit.fromMap(Map<String, dynamic> map) {
    // The nested select returns prediction as an object (or null),
    // with analysis_result nested inside, and fruit -> fruit_type inside that.
    final prediction = map['prediction'] as Map<String, dynamic>?;
    final analysis =
    prediction?['analysis_result'] as Map<String, dynamic>?;
    final fruit = analysis?['fruit'] as Map<String, dynamic>?;
    final fruitType = fruit?['fruit_type'] as Map<String, dynamic>?;

    final stageWire = analysis?['ripeness_stage'] as String?;

    return InventoryFruit(
      invId: (map['inv_id'] as num).toInt(),
      userId: map['user_id'] as String,
      predictId: (map['predict_id'] as num).toInt(),
      addedDate: DateTime.parse(map['added_date'] as String),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      status: InventoryStatus.fromWire(map['status'] as String),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      estimatedWeightG: (map['estimated_weight_g'] as num?)?.toDouble(),
      resolvedAt: map['resolved_at'] == null
          ? null
          : DateTime.parse(map['resolved_at'] as String),
      fruitName: (fruitType?['name'] as String?) ?? 'Unknown fruit',
      ripenessStage: stageWire == null
          ? RipenessStage.ripe
          : RipenessStage.fromWire(stageWire),
      daysUntilSpoilAtPrediction:
      (prediction?['days_until_spoil'] as num?)?.toInt(),
      bestConsumeDate: prediction?['best_consume_date'] == null
          ? null
          : DateTime.parse(prediction!['best_consume_date'] as String),
      confidenceScore: (analysis?['confidence_score'] as num?)?.toDouble(),
      imageUrl: fruit?['scan'] is Map
          ? (fruit!['scan'] as Map)['image_url'] as String?
          : null,
    );
  }
}
