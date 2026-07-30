// lib/services/information_service.dart
//
// Data access for Modules 2, 4 and 5:
//   FR 2.1 - 2.3  storage recommendations
//   FR 4.1 - 4.3  nutrition profiles
//   FR 5.1 - 5.3  recipes and favourites
//
// Also carries the ADMIN WRITE methods at the bottom. Those calls
// only succeed for a user whose app_user.role is 'admin' - the RLS
// policies from 01_rls_app_user.sql enforce that server-side, so a
// non-admin cannot bypass it by calling the method directly.
//
// NOTE: none of this depends on the scan pipeline. Given a fruit
// type and a ripeness stage, everything here resolves from lookup
// tables, which is why these modules can be built before your
// teammate's scanner exists.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/fruit_reference.dart';
import 'package:fruitripe/models/fruit_type.dart';
import 'package:fruitripe/models/nutrition_profile.dart';
import 'package:fruitripe/models/recipe.dart';
import 'package:fruitripe/models/storage_recommendation.dart';

class InformationFailure implements Exception {
  const InformationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class InformationService {
  InformationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  // ==========================================================
  // READ
  // ==========================================================

  /// All supported fruits, alphabetical. Currently just Banana.
  Future<List<FruitType>> fetchFruitTypes({bool supportedOnly = true}) async {
    try {
      var query = _client.from('fruit_type').select();
      if (supportedOnly) query = query.eq('is_supported', true);

      final rows = await query.order('name');
      return (rows as List)
          .map((r) => FruitType.fromMap(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw InformationFailure('Could not load fruit list: ${e.message}');
    }
  }

  Future<FruitReference> fetchReference({
    required FruitType fruitType,
    required RipenessStage stage,
  }) async {
    try {
      final results = await Future.wait<dynamic>([
        _client
            .from('storage_recommendation')
            .select()
            .eq('fruit_type_id', fruitType.fruitTypeId),
        _client
            .from('nutrition_profile')
            .select()
            .eq('fruit_type_id', fruitType.fruitTypeId),
        _client
            .from('recipe')
            .select()
            .eq('fruit_type_id', fruitType.fruitTypeId)
            .order('is_rescue_recipe')
            .order('title'),
        _fetchSavedRecipeIds(),
      ]);

      // ---- storage ----
      final storageRows = (results[0] as List)
          .map((r) => StorageRecommendation.fromMap(r as Map<String, dynamic>))
          .toList();

      StorageRecommendation? forStage;
      StorageRecommendation? general;
      for (final s in storageRows) {
        if (s.ripenessStage == stage) forStage = s;
        if (s.isGeneral) general = s;
      }

      // ---- nutrition ----
      final nutritionRows = (results[1] as List)
          .map((r) => NutritionProfile.fromMap(r as Map<String, dynamic>))
          .toList();

      nutritionRows.sort((a, b) => a.ripenessStage.index
          .compareTo(b.ripenessStage.index));

      NutritionProfile? nutritionForStage;
      for (final n in nutritionRows) {
        if (n.ripenessStage == stage) nutritionForStage = n;
      }

      final savedIds = results[3] as Set<int>;
      final allRecipes = (results[2] as List)
          .map((r) => Recipe.fromMap(
        r as Map<String, dynamic>,
        isSaved: savedIds.contains(r['recipe_id'] as int),
      ))
          .toList();

      final matching =
      allRecipes.where((r) => r.suitableStage == stage).toList();
      final others =
      allRecipes.where((r) => r.suitableStage != stage).toList();

      return FruitReference(
        fruitType: fruitType,
        stage: stage,
        storageForStage: forStage,
        generalStorage: general,
        nutritionForStage: nutritionForStage,
        allNutrition: nutritionRows,
        recipesForStage: matching,
        otherRecipes: others,
      );
    } on PostgrestException catch (e) {
      throw InformationFailure('Could not load fruit information: ${e.message}');
    }
  }

  Future<List<Recipe>> searchRecipes({
    String? keyword,
    int? fruitTypeId,
    RipenessStage? stage,
    bool rescueOnly = false,
  }) async {
    try {
      var query = _client.from('recipe').select();

      if (fruitTypeId != null) query = query.eq('fruit_type_id', fruitTypeId);
      if (stage != null) query = query.eq('suitable_stage', stage.wire);
      if (rescueOnly) query = query.eq('is_rescue_recipe', true);

      final trimmed = keyword?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        query = query.ilike('title', '%$trimmed%');
      }

      final rows = await query.order('title');
      final savedIds = await _fetchSavedRecipeIds();

      return (rows as List)
          .map((r) => Recipe.fromMap(
        r as Map<String, dynamic>,
        isSaved: savedIds.contains(r['recipe_id'] as int),
      ))
          .toList();
    } on PostgrestException catch (e) {
      throw InformationFailure('Search failed: ${e.message}');
    }
  }

  Future<Set<int>> _fetchSavedRecipeIds() async {
    final uid = _uid;
    if (uid == null) return <int>{};

    try {
      final rows = await _client
          .from('saved_recipe')
          .select('recipe_id')
          .eq('user_id', uid);

      return (rows as List).map((r) => r['recipe_id'] as int).toSet();
    } on PostgrestException {
      return <int>{};
    }
  }

  Future<List<Recipe>> fetchSavedRecipes() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('saved_recipe')
          .select('recipe:recipe_id(*)')
          .eq('user_id', uid)
          .order('saved_at', ascending: false);

      return (rows as List)
          .map((r) => r['recipe'])
          .whereType<Map<String, dynamic>>()
          .map((m) => Recipe.fromMap(m, isSaved: true))
          .toList();
    } on PostgrestException catch (e) {
      throw InformationFailure('Could not load favourites: ${e.message}');
    }
  }

  Future<void> saveRecipe(int recipeId) async {
    final uid = _uid;
    if (uid == null) throw const InformationFailure('Not signed in.');

    try {
      await _client.from('saved_recipe').insert({
        'user_id': uid,
        'recipe_id': recipeId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw InformationFailure('Could not save recipe: ${e.message}');
    }
  }

  Future<void> unsaveRecipe(int recipeId) async {
    final uid = _uid;
    if (uid == null) throw const InformationFailure('Not signed in.');

    try {
      await _client
          .from('saved_recipe')
          .delete()
          .eq('user_id', uid)
          .eq('recipe_id', recipeId);
    } on PostgrestException catch (e) {
      throw InformationFailure('Could not remove recipe: ${e.message}');
    }
  }

  Future<bool> toggleSaved(Recipe recipe) async {
    if (recipe.isSaved) {
      await unsaveRecipe(recipe.recipeId);
      return false;
    }
    await saveRecipe(recipe.recipeId);
    return true;
  }

  Future<FruitType> createFruitType(FruitType fruit) async {
    try {
      final row = await _client
          .from('fruit_type')
          .insert(fruit.toInsertMap())
          .select()
          .single();
      return FruitType.fromMap(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const InformationFailure('A fruit with that name already exists.');
      }
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> updateFruitType(int fruitTypeId, Map<String, dynamic> changes) async {
    try {
      await _client
          .from('fruit_type')
          .update(changes)
          .eq('fruit_type_id', fruitTypeId);
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> deleteFruitType(int fruitTypeId) async {
    try {
      // ON DELETE CASCADE removes the storage, nutrition and
      // recipe rows with it.
      await _client.from('fruit_type').delete().eq('fruit_type_id', fruitTypeId);
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> upsertStorage(StorageRecommendation storage) async {
    try {
      await _client.from('storage_recommendation').upsert(
        storage.toInsertMap(),
        onConflict: 'fruit_type_id,ripeness_stage',
      );
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> upsertNutrition(NutritionProfile nutrition) async {
    try {
      await _client.from('nutrition_profile').upsert(
        nutrition.toInsertMap(),
        onConflict: 'fruit_type_id,ripeness_stage',
      );
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final row = await _client
          .from('recipe')
          .insert(recipe.toInsertMap())
          .select()
          .single();
      return Recipe.fromMap(row);
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> updateRecipe(int recipeId, Map<String, dynamic> changes) async {
    try {
      await _client.from('recipe').update(changes).eq('recipe_id', recipeId);
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  Future<void> deleteRecipe(int recipeId) async {
    try {
      await _client.from('recipe').delete().eq('recipe_id', recipeId);
    } on PostgrestException catch (e) {
      throw InformationFailure(_adminError(e));
    }
  }

  String _adminError(PostgrestException e) {
    if (e.code == '42501' || e.message.toLowerCase().contains('policy')) {
      return 'You do not have permission to change this. Administrator access required.';
    }
    return e.message;
  }
}