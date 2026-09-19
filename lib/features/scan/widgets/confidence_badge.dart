import 'package:flutter/material.dart';

import 'package:fruitripe/models/analysis_result.dart';
import 'package:fruitripe/features/scan/screen/confidence_explanation_screen.dart';
import 'package:fruitripe/services/justification_generator.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.analysisResult,
    required this.fruitType,
  });

  final AnalysisResult analysisResult;

  final String fruitType;

  @override
  Widget build(BuildContext context) {
    final confidence = analysisResult.confidenceScore;
    final stage = analysisResult.ripenessStage;

    // Either a low score or a species/stage pair the evaluation showed
    // is unreliable. Same rule the explanation screen uses to decide
    // whether to show a disclaimer, so the chip and the screen agree.
    final flagged = JustificationGenerator.isLowConfidence(confidence) ||
        JustificationGenerator.isKnownWeak(fruitType, stage);

    final fg = flagged ? Colors.orange.shade900 : Colors.black87;
    final bg = flagged
        ? Colors.amber.withOpacity(0.22)
        : Colors.black.withOpacity(0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfidenceExplanationScreen(
              analysisResult: analysisResult,
              fruitType: fruitType,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flagged) ...[
                Icon(Icons.warning_amber_rounded, size: 15, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.w600, color: fg),
              ),
              const SizedBox(width: 3),
              Icon(Icons.info_outline, size: 15, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}