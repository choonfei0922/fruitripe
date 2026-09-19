import '../core/enums.dart';
import '../models/prediction.dart';
import 'shelf_life_reference.dart';

class ShelfLifePredictor {
  Prediction predict({
    required String predictId,
    required String fruitType,
    required RipenessStage ripenessStage,
    required String resultId,
    DateTime? now,
  }) {
    final daysRemaining =
    ShelfLifeReference.daysUntilSpoil(fruitType, ripenessStage);
    final referenceDate = now ?? DateTime.now();

    return Prediction(
      predictId: predictId,
      daysUntilSpoil: daysRemaining,
      bestConsumeDate: referenceDate.add(Duration(days: daysRemaining)),
      resultId: resultId,
    );
  }
}