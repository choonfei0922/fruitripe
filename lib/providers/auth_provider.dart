import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/user.dart';
import 'package:fruitripe/services/auth_service.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _bootstrap();
  }

  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _profile;
  String? _errorMessage;
  bool _busy = false;
  String? _pendingEmail;

  AuthStatus get status => _status;
  AppUser? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;
  bool get isSignedIn => _status == AuthStatus.authenticated;

  String? get pendingEmail => _pendingEmail;

  Future<void> _bootstrap() async {
    if (_service.isSignedIn) {
      try {
        _profile = await _service.fetchProfile();
        _status = _profile == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();

    _service.onAuthStateChange.listen((state) {
      if (state.session == null && _status == AuthStatus.authenticated) {
        _profile = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<RegisterOutcome?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final outcome = await _service.register(
        email: email,
        password: password,
        username: username,
      );

      if (outcome == RegisterOutcome.otpSent) {
        _pendingEmail = email.trim();
      }
      return outcome;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('AuthProvider.register: $e');
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> verifySignUpOtp(String token) async {
    final email = _pendingEmail;
    if (email == null) {
      _errorMessage = 'No pending registration. Please register again.';
      notifyListeners();
      return false;
    }

    return _run(() async {
      await _service.verifySignUpOtp(email: email, token: token);
      await _service.signOut();
      _pendingEmail = null;
      _profile = null;
      _status = AuthStatus.unauthenticated;
    });
  }

  Future<bool> resendSignUpOtp() async {
    final email = _pendingEmail;
    if (email == null) {
      _errorMessage = 'No pending registration. Please register again.';
      notifyListeners();
      return false;
    }
    return _run(() => _service.resendSignUpOtp(email));
  }

  void setPendingEmail(String email) {
    _pendingEmail = email.trim();
    notifyListeners();
  }

  void clearPendingEmail() {
    _pendingEmail = null;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool allowAdmin = false,
  }) async {
    return _run(() async {
      _profile = await _service.signIn(
        email: email,
        password: password,
        allowAdmin: allowAdmin,
      );
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> signOut() async {
    return _run(() async {
      await _service.signOut();
      _profile = null;
      _status = AuthStatus.unauthenticated;
    });
  }

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<bool> updatePassword(String newPassword) =>
      _run(() => _service.updatePassword(newPassword));

  Future<bool> updateProfile({
    String? username,
    String? phoneNumber,
    AlertPreference? alertPreference,
  }) async {
    return _run(() async {
      _profile = await _service.updateProfile(
        username: username,
        phoneNumber: phoneNumber,
        alertPreference: alertPreference,
      );
    });
  }

  Future<bool> uploadProfilePicture(File file) async {
    return _run(() async {
      await _service.uploadProfilePicture(file);
      _profile = await _service.fetchProfile();
    });
  }

  Future<void> refreshProfile() async {
    if (!_service.isSignedIn) return;
    try {
      _profile = await _service.fetchProfile();
      notifyListeners();
    } catch (_) {
    }
  }

  bool get errorIsUnconfirmedEmail =>
      _errorMessage != null &&
          _service.isUnconfirmedEmailError(_errorMessage!);

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('AuthProvider unexpected error: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}