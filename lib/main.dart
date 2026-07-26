import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';

Future<void> main() async {
  // Required before any plugin work, including Supabase's local
  // session storage.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const FruitRipeApp());
}

/// Global shorthand for the Supabase client.
/// Use as: `await supabase.from('fruit_type').select();`
final supabase = Supabase.instance.client;

class FruitRipeApp extends StatelessWidget {
  const FruitRipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FruitRipe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E3F)),
        useMaterial3: true,
      ),
      // TODO: replace with your LoginScreen once it is written.
      home: const PlaceholderHome(),
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FruitRipe')),
      body: const Center(
        child: Text('Supabase connected. Ready to build.'),
      ),
    );
  }
}