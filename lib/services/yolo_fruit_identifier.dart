import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/fruit.dart';
import 'fruit_identifier.dart';

/// FR 1.2, FR 1.3 (Identification) — YOLO detection, 8 species × 4 stages.
class IdentifierUnavailable implements Exception {
  const IdentifierUnavailable(this.message, [this.technical]);
  final String message;
  final String? technical;
  @override
  String toString() => message;
}

class YoloFruitIdentifier implements FruitIdentifier {
  static const _modelAsset = 'assets/fruit_detector.tflite';

  final YOLO _yolo;
  bool _loaded = false;

  IdentifierUnavailable? _loadFailure;

  YoloFruitIdentifier() : _yolo = YOLO(modelPath: _modelAsset);

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (_loadFailure != null) throw _loadFailure!;

    try {
      await _yolo.loadModel();
      _loaded = true;
    } catch (e) {
      final raw = e.toString().toLowerCase();

      if (raw.contains('asset not found') ||
          raw.contains('unable to load asset') ||
          raw.contains('modelloading')) {
        _loadFailure = IdentifierUnavailable(
          'Scanning is unavailable right now. The recognition model '
              'could not be loaded.',
          e.toString(),
        );
      } else if (raw.contains('platform') || raw.contains('unsupported')) {
        // dart:io and the native model do not exist on web.
        _loadFailure = IdentifierUnavailable(
          'Scanning only works on a phone. Please run the app on an '
              'Android device.',
          e.toString(),
        );
      } else if (raw.contains('memory') || raw.contains('oom')) {
        _loadFailure = IdentifierUnavailable(
          'Not enough memory to start scanning. Close some apps and '
              'try again.',
          e.toString(),
        );
      } else {
        _loadFailure = IdentifierUnavailable(
          'Scanning could not start. Please try again.',
          e.toString(),
        );
      }

      debugPrint('YoloFruitIdentifier load failed: $e');
      throw _loadFailure!;
    }
  }

  @override
  Future<List<FruitCandidate>> identify(File image) async {
    await _ensureLoaded();

    try {
      final imageBytes = await image.readAsBytes();
      final resultMap = await _yolo.predict(imageBytes);

      final rawDetections = resultMap['detections'] as List<dynamic>? ?? [];

      if (rawDetections.isEmpty) {
        return [];
      }

      final results = rawDetections
          .map((d) => YOLOResult.fromMap(d as Map<String, dynamic>))
          .toList();

      return results.map((r) {
        final box = r.normalizedBox;

        return FruitCandidate(
          type: r.className,
          confidence: r.confidence,
          boundingBox: BoundingBox(
            x: box.left,
            y: box.top,
            width: box.width,
            height: box.height,
          ),
        );
      }).toList();
    } on IdentifierUnavailable {
      rethrow;
    } catch (e) {
      debugPrint('YoloFruitIdentifier predict failed: $e');
      throw const IdentifierUnavailable(
        'Could not analyse that photo. Try taking another one in '
            'better light.',
      );
    }
  }
}