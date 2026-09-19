import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/providers/batch_analysis_provider.dart';
import 'package:fruitripe/providers/scan_session_provider.dart';
import 'package:fruitripe/services/fruit_label_parser.dart';
import 'package:fruitripe/features/scan/screen/batch_analysis_screen.dart';
import 'package:fruitripe/features/scan/widgets/add_to_harvest_button.dart';
import 'package:fruitripe/features/scan/widgets/confidence_badge.dart';
import 'package:fruitripe/features/scan/widgets/correct_prediction_button.dart';
import 'package:fruitripe/features/scan/widgets/fruit_guide_button.dart';
import 'package:fruitripe/features/scan/widgets/longevity_section.dart';
import 'package:fruitripe/features/scan/widgets/ripeness_gradient_bar.dart';
import 'package:fruitripe/features/scan/widgets/status_pill.dart';

enum ScanMode { single, batch }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _mode = ScanMode.single;

  void _setMode(ScanMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _mode == ScanMode.single
            ? _buildSingle(context)
            : _buildBatch(context),
      ),
    );
  }

  Widget _buildSingle(BuildContext context) {
    return Consumer<ScanSessionProvider>(
      builder: (context, session, _) {
        if (session.status == ScanSessionStatus.idle) {
          return _IdleView(
            mode: _mode,
            onModeChanged: _setMode,
            onCapture: session.captureFromCamera,
            onUpload: session.pickFromGallery,
          );
        }
        return switch (session.status) {
          ScanSessionStatus.imageSelected ||
          ScanSessionStatus.processing =>
              _ProcessingView(session: session),
          ScanSessionStatus.success => _SuccessView(session: session),
          ScanSessionStatus.noFruitDetected =>
              _NoFruitDetectedView(session: session),
          ScanSessionStatus.unsupportedFruitType =>
              _UnsupportedFruitView(session: session),
          ScanSessionStatus.error => _ErrorView(session: session),
          ScanSessionStatus.idle => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildBatch(BuildContext context) {
    return Consumer<BatchAnalysisProvider>(
      builder: (context, session, _) {
        if (session.status == BatchSessionStatus.idle) {
          return _IdleView(
            mode: _mode,
            onModeChanged: _setMode,
            onCapture: session.captureFromCamera,
            onUpload: session.pickFromGallery,
          );
        }
        return BatchResultsView(session: session);
      },
    );
  }
}

class _IdleView extends StatelessWidget {
  final ScanMode mode;
  final ValueChanged<ScanMode> onModeChanged;
  final VoidCallback onCapture;
  final VoidCallback onUpload;

  const _IdleView({
    required this.mode,
    required this.onModeChanged,
    required this.onCapture,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Text(
                      'FruitRipe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.settings, color: Colors.white70),
              ],
            ),
          ),
          _ModeToggle(mode: mode, onChanged: onModeChanged),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CustomPaint(
                    painter: _ViewfinderCornersPainter(),
                    child: const Center(
                      child: Icon(
                        Icons.center_focus_weak,
                        color: Colors.white24,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              mode == ScanMode.single
                  ? 'Position fruit within frame'
                  : 'Fit all the fruit in one frame',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.greenAccent, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Colors.white70),
                  label: const Text(
                    'Upload from Gallery',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SegmentedButton<ScanMode>(
        segments: const [
          ButtonSegment(
            value: ScanMode.single,
            icon: Icon(Icons.center_focus_strong, size: 18),
            label: Text('Single'),
          ),
          ButtonSegment(
            value: ScanMode.batch,
            icon: Icon(Icons.grid_view_rounded, size: 18),
            label: Text('Batch'),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                ? Colors.black87
                : Colors.white70,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                ? Colors.greenAccent
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 24.0;

    canvas.drawLine(Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);

    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    canvas.drawLine(
        Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(len, size.height), paint);

    canvas.drawLine(Offset(size.width - len, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// UC101 in progress — captured image with a live-feeling "DETECTING..."
/// badge, matching Figure 4.1's in-progress state.
class _ProcessingView extends StatelessWidget {
  final ScanSessionProvider session;
  const _ProcessingView({required this.session});

  @override
  Widget build(BuildContext context) {
    final image = session.capturedImage;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF121212)),
        if (image != null) Image.file(image, fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.35)),
        const Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: StatusPill(label: 'DETECTING...'),
          ),
        ),
        const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }
}

/// UC102 — scan result: photo plus status card.
class _SuccessView extends StatelessWidget {
  final ScanSessionProvider session;
  const _SuccessView({required this.session});

  @override
  Widget build(BuildContext context) {
    final fruit = session.identifiedFruit!;
    final confidence = session.identificationConfidence!;
    final analysis = session.analysisResult!;
    final image = session.capturedImage;

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.file(image, fit: BoxFit.cover)
              else
                Container(color: Colors.black12),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.6, 1.0],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatusPill(
                    label:
                    '${fruit.type.toUpperCase()} ${(confidence * 100).toStringAsFixed(0)}% MATCH',
                    color: Colors.green,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    fruit.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
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
                      ConfidenceBadge(
                        analysisResult: analysis,
                        fruitType: parseFruitLabel(fruit.type).fruitType,
                      ),
                      const Spacer(),
                      Icon(Icons.eco,
                          color: _ripenessColor(analysis.ripenessStage)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  RipenessGradientBar(stage: analysis.ripenessStage),
                  const SizedBox(height: 20),
                  LongevitySection(prediction: session.prediction!),
                  const SizedBox(height: 16),
                  CorrectPredictionButton(
                    currentStage: analysis.ripenessStage,
                    originalStage: session.originalStage,
                    onCorrected: session.applyCorrection,
                  ),
                  const SizedBox(height: 10),

                  AddToHarvestButton(
                    fruitName: parseFruitLabel(fruit.type).fruitType,
                    stage: analysis.ripenessStage,
                    daysUntilSpoil: session.prediction!.daysUntilSpoil,
                    confidence: confidence,
                    justification: analysis.justification,
                    imageFile: image,
                    originalStage: session.originalStage,
                  ),

                  const SizedBox(height: 10),

                  FruitGuideButton(
                    fruitTypeName: parseFruitLabel(fruit.type).fruitType,
                    stage: analysis.ripenessStage,
                  ),

                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: session.reset,
                      child: const Text('Scan Another Fruit'),
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
}

/// UC101 Alternative Flow A1.
class _NoFruitDetectedView extends StatelessWidget {
  final ScanSessionProvider session;
  const _NoFruitDetectedView({required this.session});

  @override
  Widget build(BuildContext context) {
    return _AlternativeFlowView(
      icon: Icons.search_off,
      title: 'No fruit detected',
      message: 'Retake image with better lighting or clearer angle.',
      onRetake: session.reset,
    );
  }
}

/// UC101 Alternative Flow A2.
class _UnsupportedFruitView extends StatelessWidget {
  final ScanSessionProvider session;
  const _UnsupportedFruitView({required this.session});

  @override
  Widget build(BuildContext context) {
    return _AlternativeFlowView(
      icon: Icons.not_interested,
      title: 'Not supported fruit type',
      message:
      '"${session.unsupportedLabel}" isn\'t supported yet. Take an image of another fruit.',
      onRetake: session.reset,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ScanSessionProvider session;
  const _ErrorView({required this.session});

  @override
  Widget build(BuildContext context) {
    return _AlternativeFlowView(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: session.errorMessage ?? 'Please try again.',
      onRetake: session.retry,
      retakeLabel: 'Try Again',
    );
  }
}

class _AlternativeFlowView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetake;
  final String retakeLabel;

  const _AlternativeFlowView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetake,
    this.retakeLabel = 'Return to scan',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetake, child: Text(retakeLabel)),
            ],
          ),
        ),
      ),
    );
  }
}