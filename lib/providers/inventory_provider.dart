import 'package:flutter/foundation.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/inventory_fruit.dart';
import 'package:fruitripe/services/inventory_service.dart';
import 'package:fruitripe/services/notification_service.dart';

enum ShelfLifeSort { expirySoonest, expiryLatest, recentlyAdded }

class InventoryProvider extends ChangeNotifier {
  InventoryProvider({
    InventoryService? service,
    NotificationService? notifications,
  })  : _service = service ?? InventoryService(),
        _notifications = notifications ?? NotificationService();

  final InventoryService _service;
  final NotificationService _notifications;

  List<InventoryFruit> _items = const [];
  bool _loading = false;
  String? _errorMessage;

  String? _categoryFilter; // fruit name; null = all
  ShelfLifeSort _sort = ShelfLifeSort.expirySoonest;

  AlertPreference _alertPreference = AlertPreference.before24h;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  ShelfLifeSort get sort => _sort;
  String? get categoryFilter => _categoryFilter;
  AlertPreference get alertPreference => _alertPreference;

  List<String> get categories {
    final set = <String>{for (final i in _items) i.fruitName};
    final list = set.toList()..sort();
    return list;
  }

  List<InventoryFruit> get visibleItems {
    var list = _items.where((i) => i.isActive).toList();

    if (_categoryFilter != null) {
      list = list.where((i) => i.fruitName == _categoryFilter).toList();
    }

    switch (_sort) {
      case ShelfLifeSort.expirySoonest:
        list.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        break;
      case ShelfLifeSort.expiryLatest:
        list.sort((a, b) => b.daysRemaining.compareTo(a.daysRemaining));
        break;
      case ShelfLifeSort.recentlyAdded:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
    }
    return list;
  }

  List<InventoryFruit> get criticalItems =>
      _items.where((i) => i.isCritical).toList();

  int get criticalCount => criticalItems.length;

  void setAlertPreference(AlertPreference pref) {
    _alertPreference = pref;
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _items = await _service.fetchInventory();
      await _notifications.reconcileDelivered();
      await _notifications.rescheduleAll(
        _items.where((i) => i.isActive).toList(),
        _alertPreference,
      );
    } on InventoryFailure catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Something went wrong loading your inventory.';
      debugPrint('InventoryProvider.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<InventoryFruit?> resolve(int invId, InventoryStatus status) async {
    final idx = _items.indexWhere((i) => i.invId == invId);
    if (idx == -1) return null;
    final previous = _items[idx];

    try {
      final updated = await _service.resolve(invId, status);
      _items[idx] = updated;
      await _notifications.cancelForItem(invId); // task 58
      notifyListeners();
      return previous;
    } on InventoryFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> undoResolve(int invId) async {
    final idx = _items.indexWhere((i) => i.invId == invId);
    if (idx == -1) return false;

    try {
      final updated = await _service.unresolve(invId);
      _items[idx] = updated;
      await _notifications.scheduleForItem(updated, _alertPreference);
      notifyListeners();
      return true;
    } on InventoryFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addFromPrediction({
    required int predictId,
    required DateTime expiryDate,
    int quantity = 1,
    double? estimatedWeightG,
  }) async {
    try {
      final item = await _service.addToInventory(
        predictId: predictId,
        expiryDate: expiryDate,
        quantity: quantity,
        estimatedWeightG: estimatedWeightG,
      );
      _items = [item, ..._items];
      await _notifications.scheduleForItem(item, _alertPreference);
      notifyListeners();
      return true;
    } on InventoryFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> seedFakeItem() async {
    try {
      final item = await _service.seedFakeInventoryItem();
      _items = [item, ..._items];
      await _notifications.scheduleForItem(item, _alertPreference);
      notifyListeners();
      return true;
    } on InventoryFailure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void setSort(ShelfLifeSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setCategoryFilter(String? fruitName) {
    _categoryFilter = fruitName;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  InventoryFruit? itemById(int invId) {
    final idx = _items.indexWhere((i) => i.invId == invId);
    return idx == -1 ? null : _items[idx];
  }
}
