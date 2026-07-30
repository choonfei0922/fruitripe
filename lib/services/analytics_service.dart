import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/models/waste_summary.dart';

class AnalyticsFailure implements Exception {
  const AnalyticsFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AnalyticsService {
  AnalyticsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<WasteSummary> fetchSummary({int? monthsBack = 6}) async {
    final uid = _uid;
    if (uid == null) {
      throw const AnalyticsFailure('You need to be signed in.');
    }

    try {
      var query = _client.from('v_user_waste_summary').select();

      if (monthsBack != null) {
        final now = DateTime.now();
        final cutoff = DateTime(now.year, now.month - (monthsBack - 1));
        query = query.gte('period', cutoff.toIso8601String());
      }

      final rows = await query.order('period');

      final parsed = (rows as List)
          .map((r) => WasteSummaryRow.fromMap(r as Map<String, dynamic>))
          .toList();

      final scanCounts = await _fetchScanCounts();

      return WasteSummary.fromRows(
        parsed,
        batchScanCount: scanCounts.$1,
        totalScanCount: scanCounts.$2,
      );
    } on PostgrestException catch (e) {
      // 42P01 = relation does not exist.
      if (e.code == '42P01') {
        throw const AnalyticsFailure(
          'The analytics view is missing. Run the schema SQL in Supabase.',
        );
      }
      throw AnalyticsFailure('Could not load your summary: ${e.message}');
    }
  }

  Future<(int, int)> _fetchScanCounts() async {
    final uid = _uid;
    if (uid == null) return (0, 0);

    try {
      final rows = await _client
          .from('scan')
          .select('scan_id, is_batch')
          .eq('user_id', uid);

      final list = rows as List;
      final batch = list.where((r) => r['is_batch'] == true).length;
      return (batch, list.length);
    } on PostgrestException {
      // Table empty, missing, or blocked - not worth failing over.
      return (0, 0);
    }
  }

  Future<int> fetchScanCount() async {
    final counts = await _fetchScanCounts();
    return counts.$2;
  }
}