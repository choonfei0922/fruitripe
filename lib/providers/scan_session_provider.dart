import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fruitripe/models/analysis_result.dart';
import 'package:fruitripe/models/fruit.dart';
import 'package:fruitripe/models/prediction.dart';
import 'package:fruitripe/models/scan.dart';
import 'package:fruitripe/services/scan_service.dart';
import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/services/shelf_life_predictor.dart';

enum ScanSessionStatus {
  idle,
  imageSelected,
  processing,
  success,
  noFruitDetected,
  unsupportedFruitType,
  error,
}

class ScanSessionProvider extends ChangeNotifier {
  final ScanService _scanService;
  final ImagePicker _picker;
  final ShelfLifePredictor _shelfLifePredictor = ShelfLifePredictor();
  String _userId;

  ScanSessionProvider({
    ScanService? scanService,
    ImagePicker? imagePicker,
    String userId = '',
  })  : _scanService = scanService ?? ScanService(),
        _picker = imagePicker ?? ImagePicker(),
        _userId = userId;

  void updateUserId(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _clear();
  }

  ScanSessionStatus _status = ScanSessionStatus.idle;
  File? _capturedImage;
  Scan? _scan;
  Fruit? _identifiedFruit;
  double? _identificationConfidence;
  AnalysisResult? _analysisResult;
  RipenessStage? _originalStage;
  Prediction? _prediction;
  String? _errorMessage;
  String? _unsupportedLabel;

  ScanSessionStatus get status => _status;
  File? get capturedImage => _capturedImage;
  Scan? get scan => _scan;
  Fruit? get identifiedFruit => _identifiedFruit;
  double? get identificationConfidence => _identificationConfidence;
  AnalysisResult? get analysisResult => _analysisResult;
  RipenessStage? get originalStage => _originalStage;
  bool get wasCorrected => _originalStage != null;
  Prediction? get prediction => _prediction;
  String? get errorMessage => _errorMessage;
  String? get unsupportedLabel => _unsupportedLabel;

  Future<void> captureFromCamera() => _pickImage(ImageSource.camera);

  Future<void> pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return; // user cancelled — stay on current state

    _capturedImage = File(picked.path);
    _status = ScanSessionStatus.imageSelected;
    notifyListeners();

    await _runIdentification();
  }

  Future<void> _runIdentification() async {
    final image = _capturedImage;
    if (image == null) return;

    _status = ScanSessionStatus.processing;
    notifyListeners();

    final outcome = await _scanService.processImage(
      image: image,
      userId: _userId,
    );

    // The account could have changed while the model was running.
    // Dropping the result is better than showing it to the wrong user.
    if (_capturedImage != image) return;

    switch (outcome) {
      case ScanSuccess(
          :final scan,
          :final fruit,
          :final identificationConfidence,
          :final analysisResult,
          :final prediction
      ):
        _scan = scan;
        _identifiedFruit = fruit;
        _identificationConfidence = identificationConfidence;
        _analysisResult = analysisResult;
        _prediction = prediction;
        _status = ScanSessionStatus.success;
        break;
      case ScanNoFruitDetected():
        _status = ScanSessionStatus.noFruitDetected;
        break;
      case ScanUnsupportedFruitType(:final detectedLabel):
        _unsupportedLabel = detectedLabel;
        _status = ScanSessionStatus.unsupportedFruitType;
        break;
      case ScanFailed(:final message):
        _errorMessage = message;
        _status = ScanSessionStatus.error;
        break;
    }

    notifyListeners();
  }

  Future<void> retry() => _runIdentification();

  void applyCorrection(RipenessStage correctedStage) {
    final current = _analysisResult;
    final fruit = _identifiedFruit;
    if (current == null || fruit == null) return;
    if (current.ripenessStage == correctedStage && _originalStage == null) {
      return;
    }

    // Only record the first correction as the original. Correcting
    // twice shouldn't make the second correction the "model's answer".
    _originalStage ??= current.ripenessStage;

    // If they land back on what the model said, it's no longer a
    // correction at all.
    if (_originalStage == correctedStage) {
      _originalStage = null;
    }

    _analysisResult = AnalysisResult(
      resultId: current.resultId,
      ripenessStage: correctedStage,
      // The model's confidence described its own answer, not this one.
      // Carrying it over would show "94% confident" next to a stage the
      // model never picked.
      confidenceScore: _originalStage == null ? current.confidenceScore : 1.0,
      justification: _originalStage == null
          ? current.justification
          : 'Corrected by you from '
          '${_label(_originalStage!)} to ${_label(correctedStage)}.',
      fruitId: current.fruitId,
    );

    _prediction = _shelfLifePredictor.predict(
      predictId: _prediction?.predictId ??
          'predict_${DateTime.now().microsecondsSinceEpoch}',
      fruitType: fruit.type,
      ripenessStage: correctedStage,
      resultId: current.resultId,
    );

    notifyListeners();
  }

  String _label(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 'Unripe',
    RipenessStage.ripe => 'Ripe',
    RipenessStage.overripe => 'Overripe',
    RipenessStage.rotten => 'Rotten',
  };
  
  /// Returns to the scan screen's initial state — both UC101 alternative
  /// flows end with a button back to "SCAN FRUIT".
  void reset() {
    _clear();
    notifyListeners();
  }

  void _clear() {
    _status = ScanSessionStatus.idle;
    _capturedImage = null;
    _scan = null;
    _identifiedFruit = null;
    _identificationConfidence = null;
    _analysisResult = null;
    _originalStage = null;
    _prediction = null;
    _errorMessage = null;
    _unsupportedLabel = null;
  }
}