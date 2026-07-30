import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/supabase_config.dart';
import 'package:fruitripe/features/analytics/screens/analytics_screen.dart';
import 'package:fruitripe/features/auth/auth_controller.dart';
import 'package:fruitripe/features/auth/screen/profile_screen.dart';
import 'package:fruitripe/features/inventory/screens/inventory_list_screen.dart';
import 'package:fruitripe/features/storage_recipe_nutrition/screens/stage_picker_screen.dart';
import 'package:fruitripe/providers/analytics_provider.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await NotificationService().init();

  runApp(const FruitRipeApp());
}

final supabase = Supabase.instance.client;

class FruitRipeApp extends StatelessWidget {
  const FruitRipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'FruitRipe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E3F)),
          useMaterial3: true,
        ),
        home: AuthGate(
          signedInBuilder: (_) => const HomeShell(),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    InventoryListScreen(),
    StagePickerScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 2) context.read<AnalyticsProvider>().refresh();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Orchard',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}