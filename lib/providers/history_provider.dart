// lib/providers/history_provider.dart
//
// UC601: Ripeness History.
//
// Replaces the in-memory version written before the app had a
// backend. History now reads the same rows the harvest writes, so it
// survives a restart and can't disagree with the inventory.

import 'package:flutter/foundation.dart';

import 'package:fruitripe/models/scan_history_entry.dart';
import 'package:fruitripe/services/scan_history_service.dart';

enum HistoryStatus { idle, loading, loaded, error }

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({ScanHistoryService? service})
      : _service = service ?? ScanHistoryService();

  final ScanHistoryService _service;

  String _userId = '';
  HistoryStatus _status = HistoryStatus.idle;
  List<ScanHistoryEntry> _entries = const [];
  String? _errorMessage;

  HistoryStatus get status => _status;
  List<ScanHistoryEntry> get entries => _entries;
  String? get errorMessage => _errorMessage;

  int get totalScans => _entries.length;
  int get totalFruit =>
      _entries.fold(0, (sum, e) => sum + e.fruits.length);
  int get totalCorrections =>
      _entries.fold(0, (sum, e) => sum + e.correctionCount);

  /// Wired through the auth proxy in main.dart. Clears on a user
  /// change so the next account never sees the previous one's scans
  /// in the gap before its own load finishes.
  void onUserChanged(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _entries = const [];
    _status = HistoryStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    if (_userId.isEmpty) return;

    _status = HistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.fetchHistory();
      _status = HistoryStatus.loaded;
    } on ScanHistoryFailure catch (e) {
      _errorMessage = e.message;
      _status = HistoryStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();
}