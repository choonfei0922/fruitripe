import '../core/enums.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.alertPreference,
    required this.failedLoginCount,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.profilePicUrl,
  });

  final String userId;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? profilePicUrl;
  final UserRole role;
  final AlertPreference alertPreference;
  final int failedLoginCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == UserRole.admin;
  bool get hasProfilePic =>
      profilePicUrl != null && profilePicUrl!.trim().isNotEmpty;

  /// First letter of the username, for the avatar fallback.
  String get initial =>
      username.trim().isEmpty ? '?' : username.trim()[0].toUpperCase();

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      profilePicUrl: map['profile_pic_url'] as String?,
      role: UserRole.fromWire(map['role'] as String),
      alertPreference:
      AlertPreference.fromWire(map['alert_preference'] as String),
      // int2 in Postgres arrives as int, but be defensive.
      failedLoginCount: (map['failed_login_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }


  Map<String, dynamic> toEditableMap() => {
    'username': username,
    'phone_number': phoneNumber,
    'profile_pic_url': profilePicUrl,
    'alert_preference': alertPreference.wire,
  };

  AppUser copyWith({
    String? username,
    String? phoneNumber,
    String? profilePicUrl,
    AlertPreference? alertPreference,
  }) {
    return AppUser(
      userId: userId,
      username: username ?? this.username,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      role: role,
      alertPreference: alertPreference ?? this.alertPreference,
      failedLoginCount: failedLoginCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'AppUser($username, $email, ${role.wire})';
}