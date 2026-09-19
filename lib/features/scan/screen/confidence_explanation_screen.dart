import 'package:flutter/material.dart';

import '../../../core/enums.dart';
import '../../../models/analysis_result.dart';
import '../../../services/justification_generator.dart';

class ConfidenceExplanationScreen extends StatelessWidget {
  final AnalysisResult analysisResult;
  final String fruitType;

  const ConfidenceExplanationScreen({
    super.key,
    required this.analysisResult,
    required this.fruitType,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = analysisResult.confidenceScore;
    final stage = analysisResult.ripenessStage;

    // FR 5.3: disclaimer for low confidence or known-weak class combinations.
    final disclaimer = JustificationGenerator.disclaimer(
      fruitType: fruitType,
      stage: stage,
      confidence: confidence,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7F4),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Ripeness Analysis'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // UC500: the confidence score itself.
                  _ConfidenceDial(
                    confidence: confidence,
                    color: _stageColor(stage),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _stageColor(stage).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stageBadge(stage),
                      style: TextStyle(
                        color: _stageColor(stage),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fruitType,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // UC501: the written justification.
                  Text(
                    analysisResult.justification,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (disclaimer != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 20, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              disclaimer,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stageBadge(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 'Not Yet Ripe',
    RipenessStage.ripe => 'Peak Ripeness Detected',
    RipenessStage.overripe => 'Past Peak Ripeness',
    RipenessStage.rotten => 'Spoilage Detected',
  };

  Color _stageColor(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => Colors.lightGreen.shade700,
    RipenessStage.ripe => Colors.green.shade700,
    RipenessStage.overripe => Colors.orange.shade800,
    RipenessStage.rotten => Colors.brown,
  };
}

/// Large circular percentage dial, matching Figure 4.3's "94% CONFIDENCE".
class _ConfidenceDial extends StatelessWidget {
  final double confidence;
  final Color color;
  const _ConfidenceDial({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'CONFIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}