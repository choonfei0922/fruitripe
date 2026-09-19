import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/widgets/auth_error_banner.dart';

const int kResetOtpLength = 6;
const int kResetResendCooldownSeconds = 60;

class ResetPasswordOtpScreen extends StatefulWidget {
  const ResetPasswordOtpScreen({super.key});

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  Timer? _timer;
  int _secondsLeft = kResetResendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    // A code was sent just before this screen opened.
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = kResetResendCooldownSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().resetPasswordWithOtp(
      token: _otpCtrl.text,
      newPassword: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!ok) {
      // Keep the password fields, clear the code - a wrong or
      // expired code is the usual failure.
      _otpCtrl.clear();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. Please sign in with your new password.'),
        backgroundColor: Color(0xFF1B5E3F),
      ),
    );
  }

  Future<void> _resend() async {
    final ok = await context.read<AuthProvider>().resendPasswordResetOtp();
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
    final email = auth.recoveryEmail ?? 'your email';
    final canResend = _secondsLeft <= 0 && !auth.busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
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
                    const SizedBox(height: 8),
                    const Icon(Icons.password_outlined,
                        size: 56, color: Color(0xFF1B5E3F)),
                    const SizedBox(height: 16),

                    Text(
                      'Enter your code',
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
                            text: 'We sent a $kResetOtpLength-digit code to\n',
                          ),
                          TextSpan(
                            text: email,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: kResetOtpLength,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 26,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                      ),
                      validator: (v) =>
                          Validators.otp(v, length: kResetOtpLength),
                    ),

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          Validators.confirmPassword(v, _passwordCtrl.text),
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: auth.errorMessage!),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.busy ? null : _submit,
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
                          : const Text('Set New Password'),
                    ),

                    const SizedBox(height: 12),
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