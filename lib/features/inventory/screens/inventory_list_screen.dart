import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/providers/auth_provider.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/features/inventory/screens/inventory_detail_screen.dart';
import 'package:fruitripe/features/inventory/widgets/critical_window_banner.dart';
import 'package:fruitripe/features/inventory/widgets/fruit_card.dart';
import 'package:fruitripe/features/notifications/screens/notification_list_screen.dart';

/// Module 3 — Your Harvest.
///
/// No AppBar: the title block scrolls with the content, which is what
/// gives the screen its editorial feel. The bell moved into that block,
/// and the sort menu now lives behind the "Shelf-life" pill.
///
/// The debug "Seed fruit" FAB is gone. The FAB here goes to the Scan tab.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key, this.onScanRequested});

  /// Jumps to the Scan tab. HomeShell owns the tab index, so it passes
  /// this in rather than this screen reaching up into the navigation.
  final VoidCallback? onScanRequested;

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  static const _bg = Color(0xFFEFF5EC);
  static const _green = Color(0xFF1B5E3F);
  static const _ink = Color(0xFF14261C);
  static const _muted = Color(0xFF6B7F70);

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
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: inv.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _brandRow(context),
              const SizedBox(height: 28),
              _titleBlock(),
              const SizedBox(height: 22),
              _filterRow(context, inv),
              const SizedBox(height: 24),
              CriticalWindowBanner(
                count: inv.criticalCount,
                onTap: inv.criticalCount == 0
                    ? null
                    : () => inv.setSort(ShelfLifeSort.expirySoonest),
              ),
              ..._content(context, inv),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.onScanRequested == null
          ? null
          : FloatingActionButton(
        onPressed: widget.onScanRequested,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _brandRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.eco, color: _green, size: 22),
        const SizedBox(width: 8),
        const Text(
          'FruitRipe',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: _green,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _ink),
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIVE ECOSYSTEM',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: _green,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Your Harvest.',
          style: TextStyle(
            fontSize: 38,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: _ink,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Tracking the ripeness and shelf life of everything '
              'you have scanned.',
          style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
        ),
      ],
    );
  }

  Widget _filterRow(BuildContext context, InventoryProvider inv) {
    return Row(
      children: [
        _Pill(
          label: inv.categoryFilter ?? 'Category',
          icon: Icons.expand_more,
          filled: inv.categoryFilter != null,
          onTap: () => _pickCategory(context, inv),
        ),
        const SizedBox(width: 10),
        _Pill(
          label: _sortLabel(inv.sort),
          icon: Icons.swap_vert,
          filled: true,
          onTap: () => _pickSort(context, inv),
        ),
      ],
    );
  }

  static String _sortLabel(ShelfLifeSort sort) => switch (sort) {
    ShelfLifeSort.expirySoonest => 'Shelf-life',
    ShelfLifeSort.expiryLatest => 'Longest first',
    ShelfLifeSort.recentlyAdded => 'Recently added',
  };

  /// All eight fruits are listed here, not just the ones owned, so the
  /// list is long enough to need scrolling. isScrollControlled lifts
  /// the sheet's default height cap and Flexible lets the list take
  /// whatever is left after the title — without both, the Column
  /// overflows the sheet.
  Future<void> _pickCategory(
      BuildContext context,
      InventoryProvider inv,
      ) async {
    final cats = inv.categories;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const _SheetTitle('Filter by fruit'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    title: const Text('All fruits'),
                    trailing: inv.categoryFilter == null
                        ? const Icon(Icons.check, color: _green)
                        : null,
                    onTap: () {
                      inv.setCategoryFilter(null);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  for (final c in cats)
                    ListTile(
                      title: Text(c),
                      trailing: inv.categoryFilter == c
                          ? const Icon(Icons.check, color: _green)
                          : null,
                      onTap: () {
                        inv.setCategoryFilter(c);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSort(BuildContext context, InventoryProvider inv) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const _SheetTitle('Sort by'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final s in ShelfLifeSort.values)
                    ListTile(
                      title: Text(_sortDescription(s)),
                      trailing: inv.sort == s
                          ? const Icon(Icons.check, color: _green)
                          : null,
                      onTap: () {
                        inv.setSort(s);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static String _sortDescription(ShelfLifeSort sort) => switch (sort) {
    ShelfLifeSort.expirySoonest => 'Expiring soonest',
    ShelfLifeSort.expiryLatest => 'Expiring latest',
    ShelfLifeSort.recentlyAdded => 'Recently added',
  };

  List<Widget> _content(BuildContext context, InventoryProvider inv) {
    if (inv.loading && inv.visibleItems.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (inv.errorMessage != null && inv.visibleItems.isEmpty) {
      return [_ErrorState(message: inv.errorMessage!, onRetry: inv.load)];
    }

    final items = inv.visibleItems;
    if (items.isEmpty) {
      return [_EmptyState(hasFilter: inv.categoryFilter != null)];
    }

    return [
      for (final item in items)
        FruitCard(
          item: item,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InventoryDetailScreen(invId: item.invId),
            ),
          ),
        ),
    ];
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : const Color(0xFF14261C);

    return Material(
      color: filled ? const Color(0xFF1B5E3F) : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: filled ? Colors.transparent : const Color(0xFFDCE5DA),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE5DA),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14261C),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE3EDDF),
            ),
            child: const Icon(Icons.eco_outlined,
                size: 44, color: Color(0xFF8FA98D)),
          ),
          const SizedBox(height: 20),
          Text(
            hasFilter ? 'Nothing in this category' : 'Your harvest is empty',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14261C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try a different fruit, or clear the filter.'
                : 'Scan a fruit to start tracking its shelf life.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7F70), height: 1.4),
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
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 52, color: Color(0xFF8FA98D)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7F70), height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}