import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/widgets/auth_error_banner.dart';

/// MUST match Authentication -> Email -> "Email OTP length".
const int kOtpLength = 6;

/// Supabase rate-limits resend requests. 60s is the default.
const int kResendCooldownSeconds = 60;

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();

  Timer? _timer;
  int _secondsLeft = kResendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    // A code was just sent when this screen opened, so start the
    // cooldown immediately.
    _startCooldown();
    // Rebuild on every keystroke so the counter and border update.
    _otpCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.removeListener(_onChanged);
    _otpCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    // Auto-submit once the last digit lands - saves the user
    // reaching for the button.
    if (_otpCtrl.text.length == kOtpLength) {
      FocusScope.of(context).unfocus();
      _verify();
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = kResendCooldownSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok =
    await context.read<AuthProvider>().verifySignUpOtp(_otpCtrl.text);

    if (!mounted) return;

    if (!ok) {
      // Wrong code - clear it so they are not editing around a
      // stale value.
      _otpCtrl.clear();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified! Please login to continue.'),
        backgroundColor: Color(0xFF1B5E3F),
      ),
    );
  }

  Future<void> _resend() async {
    final ok = await context.read<AuthProvider>().resendSignUpOtp();
    if (!mounted) return;

    if (ok) {
      _otpCtrl.clear();
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingEmail ?? 'your email';
    final canResend = _secondsLeft <= 0 && !auth.busy;

    final entered = _otpCtrl.text.length;
    final complete = entered == kOtpLength;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 56, color: Color(0xFF1B5E3F)),
                    const SizedBox(height: 16),

                    Text(
                      'Check your email',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(
                              text: 'We sent a $kOtpLength-digit code to\n'),
                          TextSpan(
                            text: email,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: kOtpLength,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        // No hintText. A row of zeros reads like the
                        // field is already filled in.
                        border: const OutlineInputBorder(),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: complete
                                ? const Color(0xFF1B5E3F)
                                : Colors.grey.shade400,
                            width: complete ? 2 : 1,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          Validators.otp(v, length: kOtpLength),
                    ),

                    const SizedBox(height: 8),
                    // Shows progress honestly instead of a fake value.
                    Text(
                      complete
                          ? 'Checking your code...'
                          : '$entered of $kOtpLength digits entered',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: complete ? const Color(0xFF1B5E3F) : null,
                        fontWeight:
                        complete ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      AuthErrorBanner(message: auth.errorMessage!),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (auth.busy || !complete) ? null : _verify,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.busy
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Verify'),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: canResend
                          ? TextButton(
                        onPressed: _resend,
                        child: const Text('Resend code'),
                      )
                          : Text(
                        'Resend available in ${_secondsLeft}s',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                    const Divider(height: 32),
                    Text(
                      'No email? Check your spam folder. The code expires '
                          'after 1 hour.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.busy
                          ? null
                          : () {
                        context.read<AuthProvider>().clearError();
                        context
                            .read<AuthProvider>()
                            .clearPendingEmail();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text('Use a different email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}