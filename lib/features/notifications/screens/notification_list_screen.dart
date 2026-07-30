import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/app_notification.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/services/notification_service.dart';
import 'package:fruitripe/features/inventory/screens/inventory_detail_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _service = NotificationService();
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNotifications();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.fetchNotifications());
    await _future;
  }

  Future<void> _open(AppNotification n) async {
    await _service.markRead(n.notificationId);
    if (!mounted) return;

    final inv = context.read<InventoryProvider>();
    if (inv.itemById(n.invId) == null) {
      await inv.load();
    }
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryDetailScreen(invId: n.invId),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () async {
              await _service.markAllRead();
              _refresh();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.notifications_none,
                      size: 64, color: Color(0xFFB6C7B4)),
                  SizedBox(height: 16),
                  Center(
                    child: Text('No notifications yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3527))),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Text("You'll be reminded before fruit spoils.",
                        style: TextStyle(color: Color(0xFF5F7264))),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotificationTile(
                n: items[i],
                onTap: () => _open(items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(n.type);
    return Material(
      color: n.isRead ? Colors.white : const Color(0xFFEFF6EE),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE5DA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.type.label,
                            style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: const Color(0xFF1E3527),
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B5E3F),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.message,
                        style: const TextStyle(color: Color(0xFF5F7264))),
                    const SizedBox(height: 4),
                    Text(_ago(n.sentAt),
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF9AA89B))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _visual(NotificationType t) {
    switch (t) {
      case NotificationType.peakRipeness:
        return (Icons.local_florist, const Color(0xFF4CAF6D));
      case NotificationType.nearSpoilage:
        return (Icons.access_time_filled, const Color(0xFFE8933D));
      case NotificationType.spoiled:
        return (Icons.warning_amber_rounded, const Color(0xFF8C4A2F));
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}
