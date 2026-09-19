import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';

class CorrectPredictionButton extends StatelessWidget {
  const CorrectPredictionButton({
    super.key,
    required this.currentStage,
    required this.originalStage,
    required this.onCorrected,
  });

  final RipenessStage currentStage;

  final RipenessStage? originalStage;

  final ValueChanged<RipenessStage> onCorrected;

  bool get _wasCorrected => originalStage != null;

  @override
  Widget build(BuildContext context) {
    if (_wasCorrected) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Changed from ${_label(originalStage!)} '
                    'to ${_label(currentStage)}',
                style: const TextStyle(fontSize: 13, color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => _pick(context),
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text("That's not right"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<RipenessStage>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'What stage is it actually at?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Your correction is used to improve future scans.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            ...RipenessStage.values.map(
                  (stage) => ListTile(
                leading: Icon(Icons.eco, color: _color(stage)),
                title: Text(_label(stage)),
                trailing: stage == currentStage
                    ? const Chip(
                  label:
                  Text('Current', style: TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                )
                    : null,
                onTap: () => Navigator.pop(sheetContext, stage),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null) return;
    onCorrected(selected);
  }

  static String _label(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 'Unripe',
    RipenessStage.ripe => 'Ripe',
    RipenessStage.overripe => 'Overripe',
    RipenessStage.rotten => 'Rotten',
  };

  static Color _color(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => Colors.lightGreen,
    RipenessStage.ripe => Colors.green,
    RipenessStage.overripe => Colors.orange,
    RipenessStage.rotten => Colors.brown,
  };
}