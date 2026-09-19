import '../core/enums.dart';

/// FR 3.2 (Time Prediction) — typical days remaining until spoilage,
/// per species and ripeness stage, at room temperature.
class ShelfLifeReference {
  static const Map<String, Map<RipenessStage, int>> _daysUntilSpoil = {
    'Apple': {
      RipenessStage.unripe: 14,
      RipenessStage.ripe: 7,
      RipenessStage.overripe: 3,
      RipenessStage.rotten: 0,
    },
    'Banana': {
      RipenessStage.unripe: 5,
      RipenessStage.ripe: 2,
      RipenessStage.overripe: 1,
      RipenessStage.rotten: 0,
    },
    'Grape': {
      RipenessStage.unripe: 5,
      RipenessStage.ripe: 4,
      RipenessStage.overripe: 2,
      RipenessStage.rotten: 0,
    },
    'Mango': {
      RipenessStage.unripe: 7,
      RipenessStage.ripe: 3,
      RipenessStage.overripe: 1,
      RipenessStage.rotten: 0,
    },
    'Melon': {
      RipenessStage.unripe: 7,
      RipenessStage.ripe: 4,
      RipenessStage.overripe: 2,
      RipenessStage.rotten: 0,
    },
    'Orange': {
      RipenessStage.unripe: 10,
      RipenessStage.ripe: 14,
      RipenessStage.overripe: 5,
      RipenessStage.rotten: 0,
    },
    'Peach': {
      RipenessStage.unripe: 4,
      RipenessStage.ripe: 2,
      RipenessStage.overripe: 1,
      RipenessStage.rotten: 0,
    },
    'Pear': {
      RipenessStage.unripe: 7,
      RipenessStage.ripe: 3,
      RipenessStage.overripe: 1,
      RipenessStage.rotten: 0,
    },
  };

  static const int _fallbackDays = 3;

  static int daysUntilSpoil(String fruitType, RipenessStage stage) {
    return _daysUntilSpoil[fruitType]?[stage] ?? _fallbackDays;
  }
}