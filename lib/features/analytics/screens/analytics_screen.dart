import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/models/waste_summary.dart';
import 'package:fruitripe/providers/analytics_provider.dart';
import 'package:fruitripe/features/analytics/widgets/consumption_chart.dart';
import 'package:fruitripe/features/analytics/widgets/fruit_breakdown.dart';
import 'package:fruitripe/features/analytics/widgets/impact_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame - calling a provider that
    // notifies listeners during build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AnalyticsProvider>().load();
    });
  }

  Future<void> _pickPeriod() async {
    final provider = context.read<AnalyticsProvider>();

    final choice = await showModalBottomSheet<AnalyticsPeriod>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Show data for',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...AnalyticsPeriod.values.map(
                  (p) => ListTile(
                title: Text(p.label),
                trailing: p == provider.period
                    ? const Icon(Icons.check, color: Color(0xFF1B5E3F))
                    : null,
                onTap: () => Navigator.of(context).pop(p),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice != null) await provider.setPeriod(choice);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FruitRipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: provider.loading ? null : provider.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: _buildBody(context, provider, summary),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      AnalyticsProvider provider,
      WasteSummary summary,
      ) {
    if (provider.loading && !provider.loadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.cloud_off,
                      size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Harvest Insights',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E3F),
          ),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            label: Text(provider.period.label),
            avatar: const Icon(Icons.calendar_today_outlined, size: 15),
            onPressed: provider.loading ? null : _pickPeriod,
          ),
        ),
        const SizedBox(height: 20),

        if (summary.isEmpty) ...[
          const _EmptyState(),
        ] else ...[
          // FR 6.2
          ImpactCard(summary: summary),
          const SizedBox(height: 14),
          EfficiencyCard(summary: summary),
          const SizedBox(height: 24),

          // FR 6.1
          if (summary.byMonth.isNotEmpty) ...[
            ConsumptionChart(months: summary.byMonth),
            const SizedBox(height: 24),
          ],

          // FR 6.3
          FruitBreakdown(summary: summary),
          const SizedBox(height: 24),

          // FR 6.4
          _BatchSummary(summary: summary),
        ],
      ],
    );
  }
}

class _BatchSummary extends StatelessWidget {
  const _BatchSummary({required this.summary});

  final WasteSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalScanCount;
    final batch = summary.batchScanCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scanning summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Text(
              'No scans recorded yet. Once scanning is connected, your '
                  'single and multi-fruit scan counts will appear here.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Total scans',
                    value: '$total',
                    icon: Icons.center_focus_strong_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Batch scans',
                    value: '$batch',
                    icon: Icons.burst_mode_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Avg per batch',
                    value: batch == 0
                        ? '—'
                        : (summary.totalResolved / batch).toStringAsFixed(1),
                    icon: Icons.calculate_outlined,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.insights_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          const Text(
            'No insights yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Your summary builds up as you use the app. Add fruit to your '
                  'inventory, then mark each item as consumed or discarded — '
                  'those choices are what this page measures.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}