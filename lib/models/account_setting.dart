import '../core/enums.dart';
import 'user.dart';

class AccountSettings {
  const AccountSettings({
    required this.userId,
    required this.alertPreference,
    this.profilePicUrl,
  });

  final String userId;
  final String? profilePicUrl;
  final AlertPreference alertPreference;

  factory AccountSettings.fromUser(AppUser user) => AccountSettings(
    userId: user.userId,
    profilePicUrl: user.profilePicUrl,
    alertPreference: user.alertPreference,
  );

  Map<String, dynamic> toMap() => {
    'profile_pic_url': profilePicUrl,
    'alert_preference': alertPreference.wire,
  };

  AccountSettings copyWith({
    String? profilePicUrl,
    AlertPreference? alertPreference,
  }) =>
      AccountSettings(
        userId: userId,
        profilePicUrl: profilePicUrl ?? this.profilePicUrl,
        alertPreference: alertPreference ?? this.alertPreference,
      );
}