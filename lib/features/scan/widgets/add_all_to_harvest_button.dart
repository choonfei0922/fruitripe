import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/providers/batch_analysis_provider.dart';
import 'package:fruitripe/providers/inventory_provider.dart';
import 'package:fruitripe/services/fruit_label_parser.dart';
import 'package:fruitripe/services/fruit_result_builder.dart';
import 'package:fruitripe/services/inventory_service.dart';

class AddAllToHarvestButton extends StatefulWidget {
  const AddAllToHarvestButton({
    super.key,
    required this.results,
    this.imageFile,
    this.originalStages = const [],
  });

  final List<FruitResult> results;

  final File? imageFile;

  final List<RipenessStage?> originalStages;

  @override
  State<AddAllToHarvestButton> createState() => _AddAllToHarvestButtonState();
}

class _AddAllToHarvestButtonState extends State<AddAllToHarvestButton> {
  bool _busy = false;

  List<FruitResult> get _addable => widget.results
      .where((r) => r.analysisResult.ripenessStage != RipenessStage.rotten)
      .toList();

  int get _rottenCount => widget.results.length - _addable.length;

  Future<void> _addAll() async {
    setState(() => _busy = true);

    // Indexed rather than _addable.map: filtering first loses the
    // position, and originalStages is keyed by position in results.
    // Mapping over the filtered list would line corrections up against
    // the wrong fruit as soon as one rotten item is skipped.
    final items = <BatchScanItem>[];
    for (var i = 0; i < widget.results.length; i++) {
      final r = widget.results[i];
      if (r.analysisResult.ripenessStage == RipenessStage.rotten) continue;

      final box = r.fruit.boundingBox;
      items.add(BatchScanItem(
        // Species only — the YOLO label carries the stage suffix.
        fruitName: parseFruitLabel(r.fruit.type).fruitType,
        stage: r.analysisResult.ripenessStage,
        daysUntilSpoil: r.prediction.daysUntilSpoil,
        confidence: r.identificationConfidence,
        justification: r.analysisResult.justification,
        originalStage:
        i < widget.originalStages.length ? widget.originalStages[i] : null,
        // Schema uses w/h; BoundingBox exposes width/height.
        boundingBox: {
          'x': box.x,
          'y': box.y,
          'w': box.width,
          'h': box.height,
        },
        // One detection is one fruit, so no quantity picker here.
        quantity: 1,
      ));
    }

    final result = await context
        .read<InventoryProvider>()
        .addBatchFromScan(items: items, imageFile: widget.imageFile);

    if (!mounted) return;

    if (result == null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save to your harvest.')),
      );
      return;
    }

    setState(() => _busy = false);

    // Recorded on the session, not here: this widget is destroyed and
    // rebuilt whenever the user opens a fruit and comes back, which
    // would otherwise re-enable the button and let them save the same
    // batch twice.
    if (result.savedCount > 0) {
      context.read<BatchAnalysisProvider>().markAllSavedToHarvest();
    }

    final message = result.hasFailures
        ? '${result.savedCount} added. Could not save: '
        '${result.failures.toSet().join(', ')}.'
        : '${result.savedCount} fruit added to your harvest.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result.hasFailures ? null : const Color(0xFF1B5E3F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<BatchAnalysisProvider>().savedToHarvest;

    if (saved) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF1B5E3F), size: 20),
          SizedBox(width: 8),
          Text(
            'Added to your harvest',
            style: TextStyle(
              color: Color(0xFF1B5E3F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (_addable.isEmpty) {
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
                'All detected fruit has spoiled and should be discarded '
                    'rather than tracked.',
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

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // Null while busy, so a double tap can't fire two saves
            // before the first returns.
            onPressed: _busy ? null : _addAll,
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
        if (_rottenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$_rottenCount spoiled ${_rottenCount == 1 ? 'fruit' : 'fruits'} '
                  'will be skipped',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }
}