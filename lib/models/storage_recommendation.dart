import 'package:fruitripe/core/enums.dart';

class StorageRecommendation {
  const StorageRecommendation({
    required this.storageId,
    required this.fruitTypeId,
    required this.storageMethod,
    this.ripenessStage,
    this.isolationMethod,
    this.ripeningControlTip,
    this.sourceReference,
  });

  final int storageId;
  final int fruitTypeId;

  final RipenessStage? ripenessStage;

  final String storageMethod;

  final String? isolationMethod;

  final String? ripeningControlTip;

  final String? sourceReference;

  bool get isGeneral => ripenessStage == null;

  factory StorageRecommendation.fromMap(Map<String, dynamic> map) {
    final stage = map['ripeness_stage'] as String?;
    return StorageRecommendation(
      storageId: map['storage_id'] as int,
      fruitTypeId: map['fruit_type_id'] as int,
      ripenessStage: stage == null ? null : RipenessStage.fromWire(stage),
      storageMethod: map['storage_method'] as String,
      isolationMethod: map['isolation_method'] as String?,
      ripeningControlTip: map['ripening_control_tip'] as String?,
      sourceReference: map['source_reference'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'fruit_type_id': fruitTypeId,
    'ripeness_stage': ripenessStage?.wire,
    'storage_method': storageMethod,
    'isolation_method': isolationMethod,
    'ripening_control_tip': ripeningControlTip,
    'source_reference': sourceReference,
  };
}