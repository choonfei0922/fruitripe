import 'package:fruitripe/core/enums.dart';

class NutritionProfile {
  const NutritionProfile({
    required this.nutritionId,
    required this.fruitTypeId,
    required this.ripenessStage,
    required this.servingSizeG,
    this.caloriesKcal,
    this.sugarG,
    this.fibreG,
    this.vitaminCMg,
    this.potassiumMg,
    this.healthNote,
  });

  final int nutritionId;
  final int fruitTypeId;
  final RipenessStage ripenessStage;
  final double servingSizeG;

  // All nullable - the database allows partial data rather than
  // forcing a fake zero for a nutrient nobody measured.
  final double? caloriesKcal;
  final double? sugarG;
  final double? fibreG;
  final double? vitaminCMg;
  final double? potassiumMg;
  final String? healthNote;

  factory NutritionProfile.fromMap(Map<String, dynamic> map) => NutritionProfile(
    nutritionId: map['nutrition_id'] as int,
    fruitTypeId: map['fruit_type_id'] as int,
    ripenessStage: RipenessStage.fromWire(map['ripeness_stage'] as String),
    servingSizeG: (map['serving_size_g'] as num?)?.toDouble() ?? 100,
    caloriesKcal: (map['calories_kcal'] as num?)?.toDouble(),
    sugarG: (map['sugar_g'] as num?)?.toDouble(),
    fibreG: (map['fibre_g'] as num?)?.toDouble(),
    vitaminCMg: (map['vitamin_c_mg'] as num?)?.toDouble(),
    potassiumMg: (map['potassium_mg'] as num?)?.toDouble(),
    healthNote: map['health_note'] as String?,
  );

  Map<String, dynamic> toInsertMap() => {
    'fruit_type_id': fruitTypeId,
    'ripeness_stage': ripenessStage.wire,
    'serving_size_g': servingSizeG,
    'calories_kcal': caloriesKcal,
    'sugar_g': sugarG,
    'fibre_g': fibreG,
    'vitamin_c_mg': vitaminCMg,
    'potassium_mg': potassiumMg,
    'health_note': healthNote,
  };
}