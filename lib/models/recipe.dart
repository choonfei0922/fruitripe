import 'package:fruitripe/core/enums.dart';

class Recipe {
  const Recipe({
    required this.recipeId,
    required this.fruitTypeId,
    required this.suitableStage,
    required this.title,
    required this.isRescueRecipe,
    this.recipeUrl,
    this.imageUrl,
    this.instructions,
    this.prepTimeMinutes,
    this.isSaved = false,
  });

  final int recipeId;
  final int fruitTypeId;
  final RipenessStage suitableStage;
  final String title;
  final String? recipeUrl;
  final String? imageUrl;
  final String? instructions;
  final int? prepTimeMinutes;

  final bool isRescueRecipe;

  final bool isSaved;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  List<String> get steps => (instructions ?? '')
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  String get prepTimeLabel {
    final t = prepTimeMinutes;
    if (t == null) return '-';
    if (t < 60) return '$t min';
    final h = t ~/ 60;
    final m = t % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  factory Recipe.fromMap(Map<String, dynamic> map, {bool isSaved = false}) =>
      Recipe(
        recipeId: map['recipe_id'] as int,
        fruitTypeId: map['fruit_type_id'] as int,
        suitableStage: RipenessStage.fromWire(map['suitable_stage'] as String),
        title: map['title'] as String,
        recipeUrl: map['recipe_url'] as String?,
        imageUrl: map['image_url'] as String?,
        instructions: map['instructions'] as String?,
        prepTimeMinutes: (map['prep_time_minutes'] as num?)?.toInt(),
        isRescueRecipe: map['is_rescue_recipe'] as bool? ?? false,
        isSaved: isSaved,
      );

  Map<String, dynamic> toInsertMap() => {
    'fruit_type_id': fruitTypeId,
    'suitable_stage': suitableStage.wire,
    'title': title,
    'recipe_url': recipeUrl,
    'image_url': imageUrl,
    'instructions': instructions,
    'prep_time_minutes': prepTimeMinutes,
    'is_rescue_recipe': isRescueRecipe,
  };

  Recipe copyWith({bool? isSaved}) => Recipe(
    recipeId: recipeId,
    fruitTypeId: fruitTypeId,
    suitableStage: suitableStage,
    title: title,
    recipeUrl: recipeUrl,
    imageUrl: imageUrl,
    instructions: instructions,
    prepTimeMinutes: prepTimeMinutes,
    isRescueRecipe: isRescueRecipe,
    isSaved: isSaved ?? this.isSaved,
  );
}