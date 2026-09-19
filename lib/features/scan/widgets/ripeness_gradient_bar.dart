import 'package:flutter/material.dart';

import '/core/enums.dart';

class RipenessGradientBar extends StatefulWidget {
  final RipenessStage stage;
  final ValueChanged<RipenessStage>? onStageChanged;

  const RipenessGradientBar({
    super.key,
    required this.stage,
    this.onStageChanged,
  });

  @override
  State<RipenessGradientBar> createState() => _RipenessGradientBarState();
}

class _RipenessGradientBarState extends State<RipenessGradientBar> {
  late double _currentPercent;

  static const double _markerWidth = 12.0;

  double _percentForStage(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 0.10,
    RipenessStage.ripe => 0.40,
    RipenessStage.overripe => 0.72,
    RipenessStage.rotten => 0.95,
  };

  RipenessStage _stageForPercent(double percent) {
    if (percent < 0.25) return RipenessStage.unripe;
    if (percent < 0.56) return RipenessStage.ripe;
    if (percent < 0.835) return RipenessStage.overripe;
    return RipenessStage.rotten;
  }

  @override
  void initState() {
    super.initState();
    _currentPercent = _percentForStage(widget.stage);
  }

  @override
  void didUpdateWidget(covariant RipenessGradientBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _currentPercent = _percentForStage(widget.stage);
    }
  }

  void _handleDrag(double localDx, double maxWidth) {
    final clampedX = localDx.clamp(0.0, maxWidth);
    final percent = clampedX / maxWidth;

    setState(() {
      _currentPercent = percent;
    });

    final newStage = _stageForPercent(percent);
    widget.onStageChanged?.call(newStage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final markerLeft = (maxWidth * _currentPercent - (_markerWidth / 2))
                  .clamp(0.0, maxWidth - _markerWidth);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragDown: (details) =>
                    _handleDrag(details.localPosition.dx, maxWidth),
                onHorizontalDragUpdate: (details) =>
                    _handleDrag(details.localPosition.dx, maxWidth),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF9C7A45), // unripe
                            Color(0xFF4CAF50), // ripe / peak
                            Color(0xFFE0703A), // overripe
                            Color(0xFF3E2723), // rotten
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: markerLeft,
                      top: -4,
                      child: Container(
                        width: _markerWidth,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.black26),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('UNRIPE', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('PEAK', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('OVERRIPE', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('ROTTEN', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}