import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/scan_history_entry.dart';
import 'package:fruitripe/providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: SafeArea(
        child: Consumer<HistoryProvider>(
          builder: (context, history, _) {
            return switch (history.status) {
              HistoryStatus.idle ||
              HistoryStatus.loading =>
              const Center(child: CircularProgressIndicator()),
              HistoryStatus.error => _ErrorView(history: history),
              HistoryStatus.loaded => history.entries.isEmpty
                  ? const _EmptyView()
                  : _HistoryList(history: history),
            };
          },
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});
  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: history.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.entries.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _Totals(history: history);
          return _ScanCard(entry: history.entries[i - 1]);
        },
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.history});
  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _Total(label: 'Scans', value: '${history.totalScans}'),
          const SizedBox(width: 10),
          _Total(label: 'Fruit', value: '${history.totalFruit}'),
          const SizedBox(width: 10),
          _Total(
            label: 'Corrections',
            value: '${history.totalCorrections}',
            highlight: history.totalCorrections > 0,
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.blue.withOpacity(0.10)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.blue.shade700 : null,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.entry});
  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final d = entry.scanDate;
    final date = '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: entry.hasPhoto
                        ? Image.network(
                      entry.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _NoPhoto(),
                    )
                        : const _NoPhoto(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.isBatch
                            ? 'Batch scan · ${entry.fruits.length} fruit'
                            : 'Single scan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...entry.fruits.map((f) => _FruitRow(fruit: f)),
          ],
        ),
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: const Icon(Icons.eco, color: Colors.white70),
    );
  }
}

class _FruitRow extends StatelessWidget {
  const _FruitRow({required this.fruit});
  final ScanHistoryFruit fruit;

  @override
  Widget build(BuildContext context) {
    final stage = fruit.displayedStage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: _color(stage)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fruit.fruitName ?? 'Unsupported fruit',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (fruit.wasCorrected) ...[
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_label(fruit.stage)} → ${_label(stage)}',
                style: const TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
          ] else
            Text(
              '${_label(stage)} · ${fruit.confidence.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No scans yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Fruit you scan and add to your harvest will show up '
                  'here, along with any corrections you make.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.history});
  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              history.errorMessage ?? 'Could not load your history',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: history.load,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _label(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => 'Unripe',
  RipenessStage.ripe => 'Ripe',
  RipenessStage.overripe => 'Overripe',
  RipenessStage.rotten => 'Rotten',
};

Color _color(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => Colors.lightGreen,
  RipenessStage.ripe => Colors.green,
  RipenessStage.overripe => Colors.orange,
  RipenessStage.rotten => Colors.brown,
};