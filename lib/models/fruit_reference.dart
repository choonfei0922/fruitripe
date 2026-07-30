import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/models/nutrition_profile.dart';
import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/models/storage_recommendation.dart';

class FruitReference {
  const FruitReference({
    required this.fruitType,
    required this.stage,
    required this.storageForStage,
    required this.generalStorage,
    required this.nutritionForStage,
    required this.allNutrition,
    required this.recipesForStage,
    required this.otherRecipes,
  });

  final FruitType fruitType;

  final RipenessStage stage;

  final StorageRecommendation? storageForStage;

  final StorageRecommendation? generalStorage;

  final NutritionProfile? nutritionForStage;

  final List<NutritionProfile> allNutrition;

  final List<Recipe> recipesForStage;

  final List<Recipe> otherRecipes;

  StorageRecommendation? get effectiveStorage =>
      storageForStage ?? generalStorage;

  bool get hasStorage => effectiveStorage != null;
  bool get hasNutrition => nutritionForStage != null;
  bool get hasRecipes => recipesForStage.isNotEmpty;

  bool get usingRecipeFallback =>
      recipesForStage.isEmpty && otherRecipes.isNotEmpty;

  List<Recipe> get rescueRecipes =>
      [...recipesForStage, ...otherRecipes].where((r) => r.isRescueRecipe).toList();
}