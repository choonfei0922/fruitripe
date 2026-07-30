import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/features/inventory/screens/inventory_detail_screen.dart';
import 'package:fruitripe/features/inventory/widgets/critical_window_banner.dart';
import 'package:fruitripe/features/inventory/widgets/fruit_card.dart';
import 'package:fruitripe/features/notifications/screens/notification_list_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final inv = context.read<InventoryProvider>();
      // Seed the schedule with the user's Module 1 alert preference.
      if (auth.profile != null) {
        inv.setAlertPreference(auth.profile!.alertPreference);
      }
      inv.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text('Your Harvest'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationListScreen(),
              ),
            ),
          ),
          PopupMenuButton<ShelfLifeSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: inv.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ShelfLifeSort.expirySoonest,
                child: Text('Expiring soonest'),
              ),
              PopupMenuItem(
                value: ShelfLifeSort.expiryLatest,
                child: Text('Expiring latest'),
              ),
              PopupMenuItem(
                value: ShelfLifeSort.recentlyAdded,
                child: Text('Recently added'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: inv.load,
        child: _body(context, inv),
      ),

      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
        onPressed: () async {
          final ok = await inv.seedFakeItem();
          if (context.mounted && !ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(inv.errorMessage ?? 'Seed failed.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Seed item'),
      )
          : null,
    );
  }

  Widget _body(BuildContext context, InventoryProvider inv) {
    if (inv.loading && inv.visibleItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (inv.errorMessage != null && inv.visibleItems.isEmpty) {
      return _ErrorState(message: inv.errorMessage!, onRetry: inv.load);
    }

    final items = inv.visibleItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        CriticalWindowBanner(
          count: inv.criticalCount,
          onTap: inv.criticalCount == 0
              ? null
              : () => inv.setSort(ShelfLifeSort.expirySoonest),
        ),
        _CategoryChips(inv: inv),
        const SizedBox(height: 4),
        if (items.isEmpty)
          _EmptyState(hasFilter: inv.categoryFilter != null)
        else
          ...items.map(
                (item) => FruitCard(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InventoryDetailScreen(invId: item.invId),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.inv});
  final InventoryProvider inv;

  @override
  Widget build(BuildContext context) {
    final cats = inv.categories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, label: 'All', selected: inv.categoryFilter == null,
              onTap: () => inv.setCategoryFilter(null)),
          for (final c in cats)
            _chip(context,
                label: c,
                selected: inv.categoryFilter == c,
                onTap: () => inv.setCategoryFilter(c)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label,
        required bool selected,
        required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFF1B5E3F),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1E3527),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDCE5DA)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 64, color: Color(0xFFB6C7B4)),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Nothing in this category' : 'Your harvest is empty',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3527)),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try a different category.'
                : 'Scan a fruit to start tracking its shelf life.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5F7264)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off, size: 56, color: Color(0xFFB6C7B4)),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5F7264))),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
