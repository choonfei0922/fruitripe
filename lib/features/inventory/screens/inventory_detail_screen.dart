import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/inventory_fruit.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/features/inventory/widgets/shelf_life_bar.dart';

class InventoryDetailScreen extends StatelessWidget {
  const InventoryDetailScreen({super.key, required this.invId});

  final int invId;

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final item = inv.itemById(invId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This item is no longer available.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: Text(item.fruitName),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(item: item),
          const SizedBox(height: 16),
          _DetailCard(item: item),
          const SizedBox(height: 24),
          if (item.isActive)
            _ResolveActions(item: item)
          else
            _ResolvedNotice(item: item),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});
  final InventoryFruit item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _thumb(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.fruitName,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3527))),
                    Text('${item.ripenessStage.label} · ×${item.quantity}',
                        style: const TextStyle(color: Color(0xFF5F7264))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ShelfLifeBar(item: item, height: 10),
        ],
      ),
    );
  }

  Widget _thumb() {
    const size = 72.0;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(item.imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(size)),
      );
    }
    return _fallback(size);
  }

  Widget _fallback(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.eco, color: Color(0xFF4CAF6D), size: 32),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.item});
  final InventoryFruit item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5DA)),
      ),
      child: Column(
        children: [
          _row('Added', _date(item.addedDate)),
          _row('Best before', _date(item.expiryDate)),
          if (item.bestConsumeDate != null)
            _row('Best consumed by', _date(item.bestConsumeDate!)),
          if (item.confidenceScore != null)
            _row('Analysis confidence',
                '${item.confidenceScore!.toStringAsFixed(0)}%'),
          if (item.estimatedWeightG != null)
            _row('Estimated weight',
                '${item.estimatedWeightG!.toStringAsFixed(0)} g'),
          _row('Status', item.status.label, last: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool last = false}) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5F7264))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1E3527))),
      ],
    ),
  );

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// FR 3.4 mark consumed / discarded, with undo (tasks 54, 55).
class _ResolveActions extends StatelessWidget {
  const _ResolveActions({required this.item});
  final InventoryFruit item;

  Future<void> _resolve(
      BuildContext context, InventoryStatus status) async {
    final inv = context.read<InventoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final previous = await inv.resolve(item.invId, status);
    if (previous == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(inv.errorMessage ?? 'Could not update the item.'),
      ));
      return;
    }

    // Leave the detail screen; the item drops off the active list.
    navigator.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text(status == InventoryStatus.consumed
            ? 'Marked as consumed.'
            : 'Marked as discarded.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => inv.undoResolve(item.invId),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E3F),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.restaurant),
            label: const Text('Mark as consumed'),
            onPressed: () => _resolve(context, InventoryStatus.consumed),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8C4A2F),
              side: const BorderSide(color: Color(0xFF8C4A2F)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Mark as discarded'),
            onPressed: () => _resolve(context, InventoryStatus.discarded),
          ),
        ),
      ],
    );
  }
}

class _ResolvedNotice extends StatelessWidget {
  const _ResolvedNotice({required this.item});
  final InventoryFruit item;

  @override
  Widget build(BuildContext context) {
    final consumed = item.status == InventoryStatus.consumed;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: consumed ? const Color(0xFFEAF5EE) : const Color(0xFFF7EDE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            consumed
                ? 'You marked this as consumed.'
                : 'You marked this as discarded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: consumed
                  ? const Color(0xFF1B5E3F)
                  : const Color(0xFF8C4A2F),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.undo),
          label: const Text('Move back to active'),
          onPressed: () async {
            final inv = context.read<InventoryProvider>();
            final ok = await inv.undoResolve(item.invId);
            if (context.mounted && !ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(inv.errorMessage ?? 'Could not undo.')),
              );
            }
          },
        ),
      ],
    );
  }
}
