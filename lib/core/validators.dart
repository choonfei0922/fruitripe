class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@'
    r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*'
    r'\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return 'Please enter your email.';
    if (v.length > 255) return 'Email address is too long.';
    if (v.contains(' ')) return 'Email address cannot contain spaces.';
    if (v.contains('..')) return 'Email address cannot contain "..".';
    if (v.startsWith('.') || v.startsWith('@')) {
      return 'Please enter a valid email address.';
    }
    // Catches a@b@c, which the regex alone would not.
    if (v.split('@').length != 2) {
      return 'Please enter a valid email address.';
    }
    if (v.split('@')[0].endsWith('.')) {
      return 'Please enter a valid email address.';
    }
    if (!_emailPattern.hasMatch(v)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static final RegExp _usernamePattern =
  RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._ ]*$');

  static String? username(String? value) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return 'Please enter a username.';
    if (v.length < 3) return 'Username must be at least 3 characters.';
    if (v.length > 50) return 'Username must be 50 characters or fewer.';
    if (v.contains('  ')) return 'Username cannot contain double spaces.';
    if (!_usernamePattern.hasMatch(v)) {
      return 'Use only letters, numbers, dots, underscores and spaces.';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return 'Please enter a password.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    if (v.length > 72) return 'Password must be 72 characters or fewer.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? phoneOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;

    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return 'Phone number is too short.';
    if (digits.length > 15) return 'Phone number is too long.';
    if (!RegExp(r'^\+?[0-9\s\-()]+$').hasMatch(v)) {
      return 'Use only digits, spaces, +, - and ().';
    }
    return null;
  }

  static String? otp(String? value, {required int length}) {
    final v = (value ?? '').trim();

    if (v.isEmpty) return 'Please enter the code from your email.';
    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
      return 'The code contains digits only.';
    }
    if (v.length != length) return 'The code is $length digits long.';
    return null;
  }
}