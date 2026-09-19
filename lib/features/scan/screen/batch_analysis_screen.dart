import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/providers/batch_analysis_provider.dart';
import 'package:fruitripe/services/fruit_label_parser.dart';
import 'package:fruitripe/services/fruit_result_builder.dart';
import 'package:fruitripe/features/scan/widgets/add_all_to_harvest_button.dart';
import 'package:fruitripe/features/scan/widgets/add_to_harvest_button.dart';
import 'package:fruitripe/features/scan/widgets/confidence_badge.dart';
import 'package:fruitripe/features/scan/widgets/correct_prediction_button.dart';
import 'package:fruitripe/features/scan/widgets/cropped_fruit_image.dart';
import 'package:fruitripe/features/scan/widgets/detection_spotlight.dart';
import 'package:fruitripe/features/scan/widgets/fruit_guide_button.dart';
import 'package:fruitripe/features/scan/widgets/longevity_section.dart';
import 'package:fruitripe/features/scan/widgets/ripeness_gradient_bar.dart';
import 'package:fruitripe/features/scan/widgets/status_pill.dart';

class BatchResultsView extends StatelessWidget {
  final BatchAnalysisProvider session;
  const BatchResultsView({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // UC401 takes over once a fruit is picked from the list.
    if (session.selectedIndex != null) {
      return _FruitDetailView(session: session);
    }

    return switch (session.status) {
      BatchSessionStatus.imageSelected ||
      BatchSessionStatus.processing =>
      const _BatchProcessingView(),
      BatchSessionStatus.success => _BatchListView(session: session),
      BatchSessionStatus.noFruitDetected => _BatchMessageView(
        icon: Icons.search_off,
        message: 'No fruit detected',
        onRetry: session.reset,
      ),
      BatchSessionStatus.error => _BatchMessageView(
        icon: Icons.error_outline,
        message: session.errorMessage ?? 'Something went wrong',
        onRetry: session.reset,
      ),
      BatchSessionStatus.idle => const SizedBox.shrink(),
    };
  }
}

class _BatchProcessingView extends StatelessWidget {
  const _BatchProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Detecting all fruit in image...'),
        ],
      ),
    );
  }
}

class _BatchListView extends StatelessWidget {
  final BatchAnalysisProvider session;
  const _BatchListView({required this.session});

  @override
  Widget build(BuildContext context) {
    final results = session.results;
    final image = session.capturedImage;

    return Column(
      children: [
        if (image != null)
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(image, fit: BoxFit.cover),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: StatusPill(
                      label: '${results.length} DETECTED',
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${results.length} fruit detected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: session.reset,
                child: const Text('New Scan'),
              ),
            ],
          ),
        ),
        // Adds every non-rotten fruit in one action, so a batch doesn't
        // mean tapping into each fruit individually.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: AddAllToHarvestButton(
            results: results,
            imageFile: image,
            originalStages: session.originalStages,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = results[index];
              final saved = session.isSavedAt(index);
              return _FruitListTile(
                result: result,
                image: image,
                saved: saved,
                onTap: saved ? null : () => session.selectFruit(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FruitListTile extends StatelessWidget {
  final FruitResult result;
  final File? image;
  final bool saved;
  final VoidCallback? onTap;
  const _FruitListTile({
    required this.result,
    required this.image,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stage = result.analysisResult.ripenessStage;
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: saved ? 0.45 : 1.0,
                child: CroppedFruitImage(
                  imageFile: image,
                  box: result.fruit.boundingBox,
                  fallbackColor: _ripenessColor(stage).withOpacity(0.15),
                ),
              ),
            ),
            if (saved)
              const Positioned(
                right: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.check_circle,
                      size: 18, color: Color(0xFF1B5E3F)),
                ),
              ),
          ],
        ),
      ),
      // Species only — the YOLO label carries the stage suffix.
      title: Text(parseFruitLabel(result.fruit.type).fruitType),
      subtitle: Text(
        saved
            ? 'In your harvest'
            : '${_ripenessLabel(stage)} · '
            '${(result.analysisResult.confidenceScore * 100).toStringAsFixed(0)}% · '
            '${result.prediction.daysUntilSpoil}d left',
        style: saved
            ? const TextStyle(color: Color(0xFF1B5E3F))
            : null,
      ),
      trailing: saved ? null : const Icon(Icons.chevron_right),
    );
  }
}

class _FruitDetailView extends StatelessWidget {
  final BatchAnalysisProvider session;
  const _FruitDetailView({required this.session});

  @override
  Widget build(BuildContext context) {
    final index = session.selectedIndex!;
    final alreadySaved = session.isSavedAt(index);
    final result = session.selectedResult!;
    final analysis = result.analysisResult;
    final image = session.capturedImage;
    final speciesName = parseFruitLabel(result.fruit.type).fruitType;

    return Column(
      children: [
        // Mirrors the single-scan photo half, but clipped to this one
        // fruit's bounding box instead of the whole frame.
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Whole frame with everything but this fruit dimmed, so
                // you can see which one it picked and where it sat.
                DetectionSpotlight(
                  imageFile: image,
                  box: result.fruit.boundingBox,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                          tooltip: 'Back to batch',
                          onPressed: session.clearSelection,
                        ),
                        StatusPill(
                          label:
                          '${(result.identificationConfidence * 100).toStringAsFixed(0)}% MATCH',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      speciesName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black87),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF3F7F4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _ripenessLabel(analysis.ripenessStage),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Same entry point as the single-scan card.
                      ConfidenceBadge(
                        analysisResult: analysis,
                        fruitType: speciesName,
                      ),
                      const Spacer(),
                      Icon(Icons.eco,
                          color: _ripenessColor(analysis.ripenessStage)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  RipenessGradientBar(stage: analysis.ripenessStage),
                  const SizedBox(height: 20),
                  LongevitySection(prediction: result.prediction),
                  const SizedBox(height: 16),

                  if (alreadySaved) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF1B5E3F), size: 20),
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
                    ),
                  ] else ...[
                    CorrectPredictionButton(
                      currentStage: analysis.ripenessStage,
                      originalStage: session.originalStageAt(index),
                      onCorrected: (stage) =>
                          session.applyCorrection(index, stage),
                    ),
                    const SizedBox(height: 10),
                    AddToHarvestButton(
                      fruitName: speciesName,
                      stage: analysis.ripenessStage,
                      daysUntilSpoil: result.prediction.daysUntilSpoil,
                      confidence: result.identificationConfidence,
                      justification: analysis.justification,
                      imageFile: image,
                      originalStage: session.originalStageAt(index),
                      onSaved: () => session.markSavedAt(index),
                    ),
                  ],

                  const SizedBox(height: 10),

                  FruitGuideButton(
                    fruitTypeName: speciesName,
                    stage: analysis.ripenessStage,
                  ),

                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: session.clearSelection,
                      child: const Text('Back to Batch'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BatchMessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _BatchMessageView({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

String _ripenessLabel(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => 'Unripe',
  RipenessStage.ripe => 'Ripe',
  RipenessStage.overripe => 'Overripe',
  RipenessStage.rotten => 'Rotten',
};

Color _ripenessColor(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => Colors.lightGreen,
  RipenessStage.ripe => Colors.green,
  RipenessStage.overripe => Colors.orange,
  RipenessStage.rotten => Colors.brown,
};