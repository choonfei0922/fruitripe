// lib/services/auth_service.dart
//
// MODIFIED for OTP signup verification.
// Changes from the previous version:
//   * register() now reports whether the email was already taken,
//     using the identities trick (see comment below)
//   * NEW verifySignUpOtp()
//   * NEW resendSignUpOtp()
//   * signIn() now handles the "email not confirmed" case
//   * validation delegated to core/validators.dart
//
// Covers FR 1.1 - 1.6.

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/models/user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

enum RegisterOutcome {
  otpSent,

  emailAlreadyRegistered,
}

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _profilePicBucket = 'profile-pics';

  Session? get currentSession => _client.auth.currentSession;
  User? get currentAuthUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<RegisterOutcome> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final usernameError = Validators.username(username);
    if (usernameError != null) throw AuthFailure(usernameError);

    final emailError = Validators.email(email);
    if (emailError != null) throw AuthFailure(emailError);

    final passwordError = Validators.password(password);
    if (passwordError != null) throw AuthFailure(passwordError);

    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );

      final user = res.user;
      if (user == null) {
        throw const AuthFailure('Registration failed. Please try again.');
      }

      final identities = user.identities;
      if (identities != null && identities.isEmpty) {
        return RegisterOutcome.emailAlreadyRegistered;
      }

      return RegisterOutcome.otpSent;
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim(),
        token: token.trim(),
      );

      if (res.session == null) {
        throw const AuthFailure(
          'Verification failed. Please request a new code.',
        );
      }
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyOtpMessage(e));
    }
  }

  Future<void> resendSignUpOtp(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyOtpMessage(e));
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
    bool allowAdmin = false,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (res.user == null) {
        throw const AuthFailure('Incorrect email or password.');
      }

      final profile = await fetchProfile(res.user!.id);
      if (profile == null) {
        await signOut();
        throw const AuthFailure(
          'Your profile is missing. Please contact support.',
        );
      }

      if (profile.isAdmin && !allowAdmin) {
        await signOut();
        throw const AuthFailure(
          'Administrator accounts must sign in through the web dashboard.',
        );
      }

      if (!profile.isAdmin && allowAdmin) {
        await signOut();
        throw const AuthFailure('This dashboard is for administrators only.');
      }

      return profile;
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  bool isUnconfirmedEmailError(String message) =>
      message.toLowerCase().contains('not confirmed') ||
          message.toLowerCase().contains('not verified');

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  Future<void> sendPasswordReset(
      String email, {
        String redirectTo = 'io.supabase.fruitripe://reset-callback',
      }) async {
    final emailError = Validators.email(email);
    if (emailError != null) throw AuthFailure(emailError);

    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final error = Validators.password(newPassword);
    if (error != null) throw AuthFailure(error);

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthFailure(_friendlyAuthMessage(e));
    }
  }

  Future<AppUser?> fetchProfile([String? userId]) async {
    final id = userId ?? currentAuthUser?.id;
    if (id == null) return null;

    try {
      final row = await _client
          .from('app_user')
          .select()
          .eq('user_id', id)
          .maybeSingle();

      return row == null ? null : AppUser.fromMap(row);
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not load profile: ${e.message}');
    }
  }

  Future<AppUser> updateProfile({
    String? username,
    String? phoneNumber,
    String? profilePicUrl,
    AlertPreference? alertPreference,
  }) async {
    final id = currentAuthUser?.id;
    if (id == null) throw const AuthFailure('Not signed in.');

    final changes = <String, dynamic>{};

    if (username != null) {
      final error = Validators.username(username);
      if (error != null) throw AuthFailure(error);
      changes['username'] = username.trim();
    }
    if (phoneNumber != null) {
      final error = Validators.phoneOptional(phoneNumber);
      if (error != null) throw AuthFailure(error);
      changes['phone_number'] =
      phoneNumber.trim().isEmpty ? null : phoneNumber.trim();
    }
    if (profilePicUrl != null) changes['profile_pic_url'] = profilePicUrl;
    if (alertPreference != null) {
      changes['alert_preference'] = alertPreference.wire;
    }

    if (changes.isEmpty) {
      final current = await fetchProfile();
      if (current == null) throw const AuthFailure('Profile not found.');
      return current;
    }

    try {
      final row = await _client
          .from('app_user')
          .update(changes)
          .eq('user_id', id)
          .select()
          .single();

      return AppUser.fromMap(row);
    } on PostgrestException catch (e) {
      throw AuthFailure('Could not save profile: ${e.message}');
    }
  }

  Future<String> uploadProfilePicture(File file) async {
    final id = currentAuthUser?.id;
    if (id == null) throw const AuthFailure('Not signed in.');

    final ext = file.path.split('.').last.toLowerCase();
    final path = '$id/avatar.$ext';

    try {
      await _client.storage.from(_profilePicBucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url =
          '${_client.storage.from(_profilePicBucket).getPublicUrl(path)}'
          '?v=${DateTime.now().millisecondsSinceEpoch}';

      await updateProfile(profilePicUrl: url);
      return url;
    } on StorageException catch (e) {
      throw AuthFailure('Upload failed: ${e.message}');
    }
  }

  String _friendlyAuthMessage(AuthException e) {
    final raw = e.message.toLowerCase();

    if (raw.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (raw.contains('already registered') ||
        raw.contains('already been registered')) {
      return 'This email address is already in use.';
    }
    if (raw.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('unable to validate email') ||
        raw.contains('invalid format')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('rate limit') ||
        raw.contains('too many') ||
        raw.contains('security purposes')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return e.message;
  }

  String _friendlyOtpMessage(AuthException e) {
    final raw = e.message.toLowerCase();

    if (raw.contains('expired')) {
      return 'That code has expired. Please request a new one.';
    }
    if (raw.contains('invalid') || raw.contains('incorrect')) {
      return 'That code is not correct. Please check and try again.';
    }
    if (raw.contains('rate limit') ||
        raw.contains('too many') ||
        raw.contains('security purposes')) {
      return 'Please wait a moment before requesting another code.';
    }
    return e.message;
  }
}