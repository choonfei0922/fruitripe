import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/models/scan_history_entry.dart';

class ScanHistoryFailure implements Exception {
  const ScanHistoryFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class ScanHistoryService {
  ScanHistoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _graph = '''
        scan_id,
        image_url,
        scan_date,
        is_batch,
        fruit (
          fruit_id,
          bounding_box,
          fruit_type:fruit_type_id ( name ),
          analysis_result (
            result_id,
            ripeness_stage,
            confidence_score,
            justification,
            prediction ( days_until_spoil, best_consume_date ),
            user_feedback ( corrected_stage, submitted_at )
          )
        )
      ''';

  Future<List<ScanHistoryEntry>> fetchHistory({int limit = 50}) async {
    final uid = _uid;
    if (uid == null) {
      throw const ScanHistoryFailure('You need to be signed in.');
    }

    try {
      final rows = await _client
          .from('scan')
          .select(_graph)
          .eq('user_id', uid)
          .order('scan_date', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => ScanHistoryEntry.fromMap(r as Map<String, dynamic>))
          .where((e) => e.fruits.isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      throw ScanHistoryFailure('Could not load your history: ${e.message}');
    }
  }
}