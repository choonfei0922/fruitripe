import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/screen/reset_password_otp_screen.dart';
import 'package:fruitripe/features/auth/widgets/auth_error_banner.dart';


/// FR 1.4 (Account) — reset password via email, request step.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok =
    await context.read<AuthProvider>().sendPasswordResetOtp(_emailCtrl.text);

    if (!mounted || !ok) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResetPasswordOtpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                    const Icon(Icons.lock_reset,
                        size: 56, color: Color(0xFF1B5E3F)),
                    const SizedBox(height: 16),
                    Text(
                      'Enter the email address for your account and we will '
                          'send you a 6-digit code to set a new password.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.email,
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
                          : const Text('Send Code'),
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