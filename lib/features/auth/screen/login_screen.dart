import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/validators.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/screen/forgot_password_screen.dart';
import 'package:fruitripe/features/auth/screen/register_screen.dart';
import 'package:fruitripe/features/auth/screen/verify_otp_screen.dart';
import 'package:fruitripe/features/auth/widgets/auth_error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<AuthProvider>().signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
  }

  void _goVerify() {
    final auth = context.read<AuthProvider>();
    auth.setPendingEmail(_emailCtrl.text);
    auth.clearError();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VerifyOtpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
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
                    const SizedBox(height: 32),
                    const Icon(Icons.eco, size: 56, color: Color(0xFF1B5E3F)),
                    const SizedBox(height: 12),
                    Text(
                      'FruitRipe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to your fruit assistant',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      // Not Validators.password - an existing account
                      // may predate the current rules. Only check that
                      // something was typed; the server decides.
                      validator: (v) => (v ?? '').isEmpty
                          ? 'Please enter your password.'
                          : null,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.busy
                            ? null
                            : () {
                          context.read<AuthProvider>().clearError();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                              const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    // Alternate flow A1 / M2: Err Login Failed
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      AuthErrorBanner(message: auth.errorMessage!),
                      // Registered but never verified - give them a
                      // way forward rather than a dead end.
                      if (auth.errorIsUnconfirmedEmail)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: auth.busy ? null : _goVerify,
                            child: const Text('Enter verification code'),
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),
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
                          : const Text('Sign In'),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: auth.busy
                              ? null
                              : () {
                            context.read<AuthProvider>().clearError();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ],
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