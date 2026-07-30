import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/features/auth/screen/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.signedInBuilder});

  final WidgetBuilder signedInBuilder;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.checking:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return Builder(builder: signedInBuilder);
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 64, color: Color(0xFF1B5E3F)),
            SizedBox(height: 16),
            Text(
              'FruitRipe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E3F),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}