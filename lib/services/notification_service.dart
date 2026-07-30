import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/app_notification.dart';
import 'package:fruitripe/models/inventory_fruit.dart';

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    SupabaseClient? client,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _client = client ?? Supabase.instance.client;

  final FlutterLocalNotificationsPlugin _plugin;
  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  static const _channelId = 'shelf_life';
  static const _channelName = 'Shelf-life alerts';
  static const _channelDesc =
      'Reminders when your tracked fruit is about to spoil.';

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleForItem(
      InventoryFruit item,
      AlertPreference preference,
      ) async {
    await init();
    if (preference == AlertPreference.none) return;
    if (!item.isActive) return;
    if (item.isExpired) return;

    final when = _fireTimeFor(item, preference);
    if (when == null || when.isBefore(DateTime.now())) return;

    final type = _typeFor(item);
    final message = _messageFor(item);
    await _writeNotificationRow(
      invId: item.invId,
      type: type,
      message: message,
    );

    await _plugin.zonedSchedule(
      item.invId,
      _titleFor(item),
      message,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'inv:${item.invId}',
    );
  }

  Future<void> cancelForItem(int invId) async {
    await init();
    await _plugin.cancel(invId);
  }

  Future<void> rescheduleAll(
      List<InventoryFruit> activeItems,
      AlertPreference preference,
      ) async {
    await init();
    await _plugin.cancelAll();
    if (preference == AlertPreference.none) return;
    for (final item in activeItems) {
      await scheduleForItem(item, preference);
    }
  }

  Future<void> reconcileDelivered() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('notification')
          .update({'is_delivered': true})
          .eq('user_id', uid)
          .eq('is_delivered', false)
          .lte('sent_at', nowIso);
    } on PostgrestException {
      // Non-fatal: reconciliation retries next launch.
    }
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('notification')
        .select()
        .eq('user_id', uid)
        .order('sent_at', ascending: false);
    return (rows as List)
        .map((r) => AppNotification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int notificationId) async {
    await _client
        .from('notification')
        .update({'is_read': true}).eq('notification_id', notificationId);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('notification')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  Future<void> _writeNotificationRow({
    required int invId,
    required NotificationType type,
    required String message,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client.from('notification').insert({
        'inv_id': invId,
        'user_id': uid,
        'type': type.wire,
        'message': message,
        'is_read': false,
        'is_delivered': false,
      });
    } on PostgrestException {
    }
  }

  DateTime? _fireTimeFor(InventoryFruit item, AlertPreference pref) {
    final exp = DateTime(
        item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);
    switch (pref) {
      case AlertPreference.before24h:
      // 24h before the expiry date, at 09:00 local.
        final day = exp.subtract(const Duration(days: 1));
        return DateTime(day.year, day.month, day.day, 9);
      case AlertPreference.daily:
        final now = DateTime.now();
        var next = DateTime(now.year, now.month, now.day, 9);
        if (next.isBefore(now)) next = next.add(const Duration(days: 1));
        return next.isAfter(exp.add(const Duration(days: 1))) ? null : next;
      case AlertPreference.none:
        return null;
    }
  }

  NotificationType _typeFor(InventoryFruit item) {
    if (item.isExpired) return NotificationType.spoiled;
    if (item.daysRemaining <= 1) return NotificationType.nearSpoilage;
    return NotificationType.peakRipeness;
  }

  String _titleFor(InventoryFruit item) {
    switch (_typeFor(item)) {
      case NotificationType.spoiled:
        return '${item.fruitName} may have spoiled';
      case NotificationType.nearSpoilage:
        return '${item.fruitName} is about to spoil';
      case NotificationType.peakRipeness:
        return '${item.fruitName} is at its best';
    }
  }

  String _messageFor(InventoryFruit item) {
    final d = item.daysRemaining;
    if (d < 0) return 'It was best eaten by ${_niceDate(item.expiryDate)}.';
    if (d == 0) return 'Eat it today for the best taste.';
    if (d == 1) return 'Best eaten within a day.';
    return 'Best eaten within $d days.';
  }

  String _niceDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
