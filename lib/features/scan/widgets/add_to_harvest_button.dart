import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/providers/inventory_provider.dart';

/// FR 3.1 (Shelf-Life) — logs a whole batch into the inventory.
class AddToHarvestButton extends StatefulWidget {
  const AddToHarvestButton({
    super.key,
    required this.fruitName,
    required this.stage,
    required this.daysUntilSpoil,
    this.confidence,
    this.justification,
    this.imageFile,
    this.onSaved,
    this.originalStage,
  });

  final String fruitName;
  final RipenessStage stage;
  final int daysUntilSpoil;
  final double? confidence;
  final String? justification;
  final RipenessStage? originalStage;
  final VoidCallback? onSaved;

  final File? imageFile;

  @override
  State<AddToHarvestButton> createState() => _AddToHarvestButtonState();
}

class _AddToHarvestButtonState extends State<AddToHarvestButton> {
  bool _busy = false;
  bool _added = false;
  int _quantity = 1;

  Future<void> _add() async {
    setState(() => _busy = true);

    final inv = context.read<InventoryProvider>();
    final ok = await inv.addFromScan(
      fruitName: widget.fruitName,
      stage: widget.stage,
      daysUntilSpoil: widget.daysUntilSpoil,
      confidence: widget.confidence,
      justification: widget.justification,
      imageFile: widget.imageFile,
      quantity: _quantity,
      originalStage: widget.originalStage,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _added = ok;
    });

    if (ok) widget.onSaved?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '$_quantity ${widget.fruitName} added to your harvest.'
            : inv.errorMessage ?? 'Could not add to your harvest.'),
        backgroundColor: ok ? const Color(0xFF1B5E3F) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stage == RipenessStage.rotten) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This fruit has spoiled and should be discarded rather '
                    'than tracked.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_added) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1B5E3F), size: 20),
          const SizedBox(width: 8),
          Text(
            'Added to your harvest',
            style: TextStyle(
              color: const Color(0xFF1B5E3F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Quantity', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: (_busy || _quantity <= 1)
                  ? null
                  : () => setState(() => _quantity--),
            ),
            Text(
              '$_quantity',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: (_busy || _quantity >= 20)
                  ? null
                  : () => setState(() => _quantity++),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _add,
            icon: _busy
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.add_shopping_cart),
            label: Text(_busy ? 'Adding...' : 'Add to My Harvest'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}