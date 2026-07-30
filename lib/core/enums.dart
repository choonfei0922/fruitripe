/// SQL: ripeness_stage
enum RipenessStage {
  unripe('unripe', 'Unripe'),
  ripe('ripe', 'Ripe'),
  overripe('overripe', 'Overripe'),
  rotten('rotten', 'Rotten');

  const RipenessStage(this.wire, this.label);

  /// Exact string stored in Postgres.
  final String wire;

  final String label;

  static RipenessStage fromWire(String value) => RipenessStage.values.firstWhere(
        (e) => e.wire == value,
    orElse: () => throw ArgumentError('Unknown ripeness_stage: $value'),
  );
}

/// SQL: inventory_status
enum InventoryStatus {
  active('active', 'Tracking'),
  consumed('consumed', 'Consumed'),
  discarded('discarded', 'Discarded');

  const InventoryStatus(this.wire, this.label);
  final String wire;
  final String label;

  static InventoryStatus fromWire(String value) =>
      InventoryStatus.values.firstWhere(
            (e) => e.wire == value,
        orElse: () => throw ArgumentError('Unknown inventory_status: $value'),
      );
}

enum AlertPreference {
  daily('daily', 'Daily summary'),
  before24h('before_24h', '24 hours before spoiling'),
  none('none', 'No notifications');

  const AlertPreference(this.wire, this.label);
  final String wire;
  final String label;

  static AlertPreference fromWire(String value) =>
      AlertPreference.values.firstWhere(
            (e) => e.wire == value,
        orElse: () => throw ArgumentError('Unknown alert_preference: $value'),
      );
}

/// SQL: notification_type
enum NotificationType {
  peakRipeness('peak_ripeness', 'Peak ripeness'),
  nearSpoilage('near_spoilage', 'Near spoilage'),
  spoiled('spoiled', 'Spoiled');

  const NotificationType(this.wire, this.label);
  final String wire;
  final String label;

  static NotificationType fromWire(String value) =>
      NotificationType.values.firstWhere(
            (e) => e.wire == value,
        orElse: () => throw ArgumentError('Unknown notification_type: $value'),
      );
}

/// SQL: user_role
enum UserRole {
  user('user', 'User'),
  admin('admin', 'Administrator');

  const UserRole(this.wire, this.label);
  final String wire;
  final String label;

  static UserRole fromWire(String value) => UserRole.values.firstWhere(
        (e) => e.wire == value,
    orElse: () => throw ArgumentError('Unknown user_role: $value'),
  );
}