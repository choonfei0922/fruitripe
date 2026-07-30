import 'package:flutter/foundation.dart';

import 'package:fruitripe/models/waste_summary.dart';
import 'package:fruitripe/services/analytics_service.dart';

enum AnalyticsPeriod {
  month(1, 'This month'),
  threeMonths(3, 'Last 3 months'),
  sixMonths(6, 'Last 6 months'),
  allTime(null, 'All time');

  const AnalyticsPeriod(this.monthsBack, this.label);

  final int? monthsBack;
  final String label;
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({AnalyticsService? service})
      : _service = service ?? AnalyticsService();

  final AnalyticsService _service;

  WasteSummary _summary = WasteSummary.empty;
  AnalyticsPeriod _period = AnalyticsPeriod.sixMonths;
  bool _loading = false;
  String? _error;
  bool _loadedOnce = false;

  WasteSummary get summary => _summary;
  AnalyticsPeriod get period => _period;
  bool get loading => _loading;
  String? get error => _error;
  bool get loadedOnce => _loadedOnce;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loadedOnce && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _service.fetchSummary(monthsBack: _period.monthsBack);
      _loadedOnce = true;
    } on AnalyticsFailure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Something went wrong loading your summary.';
      debugPrint('AnalyticsProvider.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (period == _period) return;
    _period = period;
    await load(force: true);
  }

  Future<void> refresh() => load(force: true);

  void reset() {
    _summary = WasteSummary.empty;
    _loadedOnce = false;
    _error = null;
    notifyListeners();
  }
}