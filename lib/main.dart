import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fruitripe/core/supabase_config.dart';
import 'package:fruitripe/features/analytics/screens/analytics_screen.dart';
import 'package:fruitripe/features/auth/auth_controller.dart';
import 'package:fruitripe/features/auth/screen/profile_screen.dart';
import 'package:fruitripe/features/inventory/screens/inventory_list_screen.dart';
import 'package:fruitripe/features/scan/screen/scan_screen.dart';
import 'package:fruitripe/providers/analytics_provider.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/providers/batch_analysis_provider.dart';
import 'package:fruitripe/providers/history_provider.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/providers/scan_session_provider.dart';
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

        // Every provider that holds per-user data is a proxy on
        // AuthProvider. These live above AuthGate, so they survive a
        // sign-out - which means without this they would hand the next
        // account the previous account's data.
        ChangeNotifierProxyProvider<AuthProvider, InventoryProvider>(
          create: (_) => InventoryProvider(),
          update: (_, auth, inv) {
            (inv ??= InventoryProvider())
                .onUserChanged(auth.profile?.userId ?? '');
            return inv;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
          update: (_, auth, analytics) {
            (analytics ??= AnalyticsProvider())
                .onUserChanged(auth.profile?.userId ?? '');
            return analytics;
          },
        ),

        // Module 3 (scan). Kept decoupled from the auth module: the scan
        // provider never imports AuthProvider, it just gets told who is
        // logged in. This proxy does the telling, and re-fires whenever
        // AuthProvider notifies — so signing out and back in as someone
        // else updates the id and wipes the old session instead of
        // leaving the previous user's result on screen.
        ChangeNotifierProxyProvider<AuthProvider, ScanSessionProvider>(
          create: (_) => ScanSessionProvider(),
          update: (_, auth, scan) {
            (scan ??= ScanSessionProvider())
                .updateUserId(auth.profile?.userId ?? '');
            return scan;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, BatchAnalysisProvider>(
          create: (_) => BatchAnalysisProvider(),
          update: (_, auth, batch) {
            (batch ??= BatchAnalysisProvider())
                .updateUserId(auth.profile?.userId ?? '');
            return batch;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, HistoryProvider>(
          create: (_) => HistoryProvider(),
          update: (_, auth, history) {
            (history ??= HistoryProvider())
                .onUserChanged(auth.profile?.userId ?? '');
            return history;
          },
        ),
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

  static const _scanTab = 1;

  void _goTo(int i) {
    setState(() => _index = i);
    if (i == 2) context.read<AnalyticsProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Built in build(), not a const field: the Orchard's "+" button has
    // to be able to switch tabs, so it needs a callback from here.
    final tabs = <Widget>[
      InventoryListScreen(onScanRequested: () => _goTo(_scanTab)),
      const ScanScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
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