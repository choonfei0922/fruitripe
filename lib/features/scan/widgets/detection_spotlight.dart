import 'dart:io';

import 'package:flutter/material.dart';

import 'package:fruitripe/models/fruit.dart';

class DetectionSpotlight extends StatefulWidget {
  const DetectionSpotlight({
    super.key,
    required this.imageFile,
    required this.box,
    this.dim = 0.62,
    this.accent = const Color(0xFF69F0AE),
  });

  final File? imageFile;
  final BoundingBox box;

  final double dim;

  final Color accent;

  @override
  State<DetectionSpotlight> createState() => _DetectionSpotlightState();
}

class _DetectionSpotlightState extends State<DetectionSpotlight> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspect;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(DetectionSpotlight old) {
    super.didUpdateWidget(old);
    if (old.imageFile?.path != widget.imageFile?.path) {
      _aspect = null;
      _resolve();
    }
  }

  void _resolve() {
    final file = widget.imageFile;
    if (file == null) return;

    _detach();
    final stream = FileImage(file).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _aspect = info.image.width / info.image.height;
      });
    }, onError: (_, __) {
      if (mounted) setState(() => _aspect = null);
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.imageFile;
    final aspect = _aspect;

    if (file == null) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.eco, size: 48, color: Colors.white54),
        ),
      );
    }

    // Still measuring - show the photo plainly rather than flashing
    // brackets into the wrong spot.
    if (aspect == null) {
      return Image.file(file, fit: BoxFit.contain);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.fill),
            CustomPaint(
              painter: _SpotlightPainter(
                box: widget.box,
                dim: widget.dim,
                accent: widget.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.box,
    required this.dim,
    required this.accent,
  });

  final BoundingBox box;
  final double dim;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      box.x * size.width,
      box.y * size.height,
      box.width * size.width,
      box.height * size.height,
    );

    final rounded = RRect.fromRectAndRadius(
      rect.inflate(4),
      const Radius.circular(10),
    );

    // Dim everything except the detection: fill the whole canvas, then
    // punch the box out with evenOdd.
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rounded)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = Colors.black.withOpacity(dim));

    // Corner brackets, matching the scan viewfinder.
    final stroke = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Short enough not to meet on a small box.
    final len = (rect.shortestSide * 0.22).clamp(8.0, 28.0);
    final r = rounded.outerRect;

    void corner(Offset pivot, double dx, double dy) {
      canvas.drawLine(pivot, pivot.translate(dx * len, 0), stroke);
      canvas.drawLine(pivot, pivot.translate(0, dy * len), stroke);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.box.x != box.x ||
          old.box.y != box.y ||
          old.box.width != box.width ||
          old.box.height != box.height ||
          old.dim != dim ||
          old.accent != accent;
}