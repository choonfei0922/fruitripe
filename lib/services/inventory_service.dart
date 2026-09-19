import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/inventory_fruit.dart';

class InventoryFailure implements Exception {
  const InventoryFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class BatchScanItem {
  const BatchScanItem({
    required this.fruitName,
    required this.stage,
    required this.daysUntilSpoil,
    this.confidence,
    this.justification,
    this.originalStage,
    this.boundingBox,
    this.quantity = 1,
  });

  final String fruitName;
  final RipenessStage stage;
  final int daysUntilSpoil;
  final double? confidence;
  final String? justification;
  final RipenessStage? originalStage;

  final Map<String, dynamic>? boundingBox;

  final int quantity;
}

class BatchSaveResult {
  const BatchSaveResult({required this.saved, required this.failures});

  final List<InventoryFruit> saved;
  final List<String> failures;

  int get savedCount => saved.length;
  bool get hasFailures => failures.isNotEmpty;
}

class InventoryService {
  InventoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _scanBucket = 'scan-images';

  static const String _selectGraph = '''
        inv_id,
        user_id,
        predict_id,
        added_date,
        expiry_date,
        status,
        quantity,
        estimated_weight_g,
        resolved_at,
        prediction:predict_id (
          days_until_spoil,
          best_consume_date,
          analysis_result:result_id (
            ripeness_stage,
            confidence_score,
            fruit:fruit_id (
              bounding_box,
              scan:scan_id ( image_url ),
              fruit_type:fruit_type_id ( name, average_weight_g )
            )
          )
        )
      ''';

  Future<List<InventoryFruit>> fetchInventory({
    bool includeResolved = false,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const InventoryFailure('You need to be signed in.');
    }
    try {
      var query =
      _client.from('inventory_tracking').select(_selectGraph).eq('user_id', uid);

      if (!includeResolved) {
        query = query.eq('status', InventoryStatus.active.wire);
      }

      final rows = await query.order('expiry_date', ascending: true);

      return (rows as List)
          .map((r) => InventoryFruit.fromMap(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not load your inventory: ${e.message}');
    }
  }

  Future<List<String>> fetchFruitTypeNames() async {
    try {
      final rows = await _client
          .from('fruit_type')
          .select('name')
          .eq('is_supported', true)
          .order('name');

      return (rows as List)
          .map((r) => (r as Map<String, dynamic>)['name'] as String)
          .toList();
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not load the fruit list: ${e.message}');
    }
  }

  Future<List<InventoryFruit>> fetchExpiringSoon({int withinDays = 1}) async {
    final uid = _uid;
    if (uid == null) {
      throw const InventoryFailure('You need to be signed in.');
    }
    try {
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month, now.day)
          .add(Duration(days: withinDays));
      final cutoffDate =
          '${cutoff.year.toString().padLeft(4, '0')}-'
          '${cutoff.month.toString().padLeft(2, '0')}-'
          '${cutoff.day.toString().padLeft(2, '0')}';

      final rows = await _client
          .from('inventory_tracking')
          .select(_selectGraph)
          .eq('user_id', uid)
          .eq('status', InventoryStatus.active.wire)
          .lte('expiry_date', cutoffDate)
          .order('expiry_date', ascending: true);

      return (rows as List)
          .map((r) => InventoryFruit.fromMap(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not check expiring items: ${e.message}');
    }
  }

  Future<InventoryFruit> fetchOne(int invId) async {
    try {
      final row = await _client
          .from('inventory_tracking')
          .select(_selectGraph)
          .eq('inv_id', invId)
          .maybeSingle();
      if (row == null) {
        throw const InventoryFailure('That item no longer exists.');
      }
      return InventoryFruit.fromMap(row);
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not load the item: ${e.message}');
    }
  }

  Future<InventoryFruit> addToInventory({
    required int predictId,
    required DateTime expiryDate,
    int quantity = 1,
    double? estimatedWeightG,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const InventoryFailure('You need to be signed in.');
    }
    try {
      final inserted = await _client
          .from('inventory_tracking')
          .insert({
        'user_id': uid,
        'predict_id': predictId,
        'expiry_date': _dateOnly(expiryDate),
        'quantity': quantity,
        'estimated_weight_g': estimatedWeightG,
      })
          .select(_selectGraph)
          .single();
      return InventoryFruit.fromMap(inserted);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const InventoryFailure('That fruit is already being tracked.');
      }
      throw InventoryFailure('Could not add to inventory: ${e.message}');
    }
  }

  Future<InventoryFruit> resolve(int invId, InventoryStatus status) async {
    if (status == InventoryStatus.active) {
      throw const InventoryFailure(
        'Use unresolve() to move an item back to active.',
      );
    }
    try {
      final updated = await _client
          .from('inventory_tracking')
          .update({
        'status': status.wire,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('inv_id', invId)
          .select(_selectGraph)
          .single();
      return InventoryFruit.fromMap(updated);
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not update the item: ${e.message}');
    }
  }

  Future<InventoryFruit> unresolve(int invId) async {
    try {
      final updated = await _client
          .from('inventory_tracking')
          .update({
        'status': InventoryStatus.active.wire,
        'resolved_at': null,
      })
          .eq('inv_id', invId)
          .select(_selectGraph)
          .single();
      return InventoryFruit.fromMap(updated);
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not undo: ${e.message}');
    }
  }

  Future<InventoryFruit> addScannedFruit({
    required String fruitName,
    required RipenessStage stage,
    required int daysUntilSpoil,
    double? confidence,
    String? justification,
    String? imageUrl,
    File? imageFile,
    RipenessStage? originalStage,
    int quantity = 1,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const InventoryFailure('You need to be signed in.');
    }

    final uploadedUrl =
    imageFile == null ? null : await _uploadScanImage(imageFile, uid);

    try {
      final ft = await _client
          .from('fruit_type')
          .select('fruit_type_id, average_weight_g')
          .ilike('name', fruitName.trim())
          .maybeSingle();

      if (ft == null) {
        throw InventoryFailure(
          '$fruitName is not in the fruit list yet, so it cannot be tracked.',
        );
      }

      final fruitTypeId = (ft['fruit_type_id'] as num).toInt();
      final avgWeight = (ft['average_weight_g'] as num?)?.toDouble();

      final scan = await _client
          .from('scan')
          .insert({
        'user_id': uid,
        'image_url': uploadedUrl ?? imageUrl ?? 'scan://$fruitName',
        'is_batch': false,
      })
          .select('scan_id')
          .single();
      final scanId = (scan['scan_id'] as num).toInt();

      final fruit = await _client
          .from('fruit')
          .insert({
        'scan_id': scanId,
        'fruit_type_id': fruitTypeId,
        'bounding_box': {'x': 0, 'y': 0, 'w': 1, 'h': 1},
      })
          .select('fruit_id')
          .single();
      final fruitId = (fruit['fruit_id'] as num).toInt();

      final analysis = await _client
          .from('analysis_result')
          .insert({
        'fruit_id': fruitId,
        'ripeness_stage': stage.wire,
        'confidence_score':
        confidence == null ? 90.0 : (confidence * 100).clamp(0, 100),
        'justification':
        justification ?? 'Identified by on-device image analysis.',
      })
          .select('result_id')
          .single();
      final resultId = (analysis['result_id'] as num).toInt();

      if (originalStage != null && originalStage != stage) {
        try {
          await _client.from('user_feedback').upsert({
            'result_id': resultId,
            'user_id': uid,
            'corrected_stage': stage.wire,
            'is_processed': false,
          }, onConflict: 'result_id');
        } on PostgrestException {
        }
      }
      final best = DateTime.now().add(Duration(days: daysUntilSpoil));

      final prediction = await _client
          .from('prediction')
          .insert({
        'result_id': resultId,
        'days_until_spoil': daysUntilSpoil,
        'best_consume_date': _dateOnly(best),
      })
          .select('predict_id')
          .single();
      final predictId = (prediction['predict_id'] as num).toInt();

      return addToInventory(
        predictId: predictId,
        expiryDate: best,
        quantity: quantity,
        estimatedWeightG: avgWeight == null ? null : avgWeight * quantity,
      );
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not save to your harvest: ${e.message}');
    }
  }

  Future<BatchSaveResult> addScannedBatch({
    required List<BatchScanItem> items,
    File? imageFile,
    String? imageUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const InventoryFailure('You need to be signed in.');
    }
    if (items.isEmpty) {
      return const BatchSaveResult(saved: [], failures: []);
    }

    final uploadedUrl =
    imageFile == null ? null : await _uploadScanImage(imageFile, uid);

    final int scanId;
    try {
      final scan = await _client
          .from('scan')
          .insert({
        'user_id': uid,
        'image_url': uploadedUrl ?? imageUrl ?? 'scan://batch',
        'is_batch': true,
      })
          .select('scan_id')
          .single();
      scanId = (scan['scan_id'] as num).toInt();
    } on PostgrestException catch (e) {
      throw InventoryFailure('Could not start the batch save: ${e.message}');
    }

    final saved = <InventoryFruit>[];
    final failures = <String>[];

    for (final item in items) {
      try {
        final ft = await _client
            .from('fruit_type')
            .select('fruit_type_id, average_weight_g')
            .ilike('name', item.fruitName.trim())
            .maybeSingle();

        if (ft == null) {
          failures.add(item.fruitName);
          continue;
        }

        final fruitTypeId = (ft['fruit_type_id'] as num).toInt();
        final avgWeight = (ft['average_weight_g'] as num?)?.toDouble();

        final fruit = await _client
            .from('fruit')
            .insert({
          'scan_id': scanId,
          'fruit_type_id': fruitTypeId,
          'bounding_box':
          item.boundingBox ?? {'x': 0, 'y': 0, 'w': 1, 'h': 1},
        })
            .select('fruit_id')
            .single();
        final fruitId = (fruit['fruit_id'] as num).toInt();

        final analysis = await _client
            .from('analysis_result')
            .insert({
          'fruit_id': fruitId,
          'ripeness_stage': item.stage.wire,
          'confidence_score': item.confidence == null
              ? 90.0
              : (item.confidence! * 100).clamp(0, 100),
          'justification': item.justification ??
              'Identified by on-device image analysis.',
        })
            .select('result_id')
            .single();
        final resultId = (analysis['result_id'] as num).toInt();

        if (item.originalStage != null && item.originalStage != item.stage) {
          try {
            await _client.from('user_feedback').upsert({
              'result_id': resultId,
              'user_id': uid,
              'corrected_stage': item.stage.wire,
              'is_processed': false,
            }, onConflict: 'result_id');
          } on PostgrestException {
          }
        }

        final best = DateTime.now().add(Duration(days: item.daysUntilSpoil));

        final prediction = await _client
            .from('prediction')
            .insert({
          'result_id': resultId,
          'days_until_spoil': item.daysUntilSpoil,
          'best_consume_date': _dateOnly(best),
        })
            .select('predict_id')
            .single();
        final predictId = (prediction['predict_id'] as num).toInt();

        saved.add(await addToInventory(
          predictId: predictId,
          expiryDate: best,
          quantity: item.quantity,
          estimatedWeightG:
          avgWeight == null ? null : avgWeight * item.quantity,
        ));
      } on InventoryFailure {
        failures.add(item.fruitName);
      } on PostgrestException {
        failures.add(item.fruitName);
      }
    }

    return BatchSaveResult(saved: saved, failures: failures);
  }

  Future<String?> _uploadScanImage(File file, String uid) async {
    try {
      if (!await file.exists()) return null;

      final raw = file.path.split('.').last.toLowerCase();
      final ext = switch (raw) {
        'png' => 'png',
        'webp' => 'webp',
        'jpeg' || 'jpg' => 'jpg',
        _ => 'jpg',
      };
      final contentType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

      final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from(_scanBucket).upload(
        path,
        file,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );

      return _client.storage.from(_scanBucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}