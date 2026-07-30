import 'package:fruitripe/core/enums.dart';

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.invId,
    required this.userId,
    required this.type,
    required this.message,
    required this.sentAt,
    required this.isRead,
    required this.isDelivered,
  });

  final int notificationId;
  final int invId;
  final String userId;
  final NotificationType type;
  final String message;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      notificationId: (map['notification_id'] as num).toInt(),
      invId: (map['inv_id'] as num).toInt(),
      userId: map['user_id'] as String,
      type: NotificationType.fromWire(map['type'] as String),
      message: map['message'] as String,
      sentAt: DateTime.parse(map['sent_at'] as String),
      isRead: map['is_read'] as bool? ?? false,
      isDelivered: map['is_delivered'] as bool? ?? false,
    );
  }
}
