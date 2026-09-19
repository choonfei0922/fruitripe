import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/scan.dart';
import '../services/batch_analysis_service.dart';
import '../services/fruit_result_builder.dart';
import 'package:fruitripe/core/enums.dart';
import 'package:fruitripe/models/analysis_result.dart';
import 'package:fruitripe/services/shelf_life_predictor.dart';

enum BatchSessionStatus {
  idle,
  imageSelected,
  processing,
  success,
  noFruitDetected,
  error,
}

class BatchAnalysisProvider extends ChangeNotifier {
  final BatchAnalysisService _batchService;
  final ImagePicker _picker;
  final Map<int, RipenessStage> _originalStages = {};
  final ShelfLifePredictor _shelfLifePredictor = ShelfLifePredictor();
  final Set<int> _savedIndices = {};
  String _userId;

  BatchAnalysisProvider({
    BatchAnalysisService? batchService,
    ImagePicker? imagePicker,
    String userId = '',
  })  : _batchService = batchService ?? BatchAnalysisService(),
        _picker = imagePicker ?? ImagePicker(),
        _userId = userId;

  void updateUserId(String userId) => _userId = userId;

  BatchSessionStatus _status = BatchSessionStatus.idle;
  File? _capturedImage;
  Scan? _scan;
  List<FruitResult> _results = [];
  int? _selectedIndex; // UC401: which fruit is open in detail view
  String? _errorMessage;
  bool isSavedAt(int index) => _savedIndices.contains(index);

  BatchSessionStatus get status => _status;
  File? get capturedImage => _capturedImage;
  Scan? get scan => _scan;
  List<FruitResult> get results => _results;
  int? get selectedIndex => _selectedIndex;
  FruitResult? get selectedResult =>
      _selectedIndex != null ? _results[_selectedIndex!] : null;
  RipenessStage? originalStageAt(int index) => _originalStages[index];
  List<RipenessStage?> get originalStages =>
      List.generate(_results.length, (i) => _originalStages[i]);
  bool wasCorrectedAt(int index) => _originalStages.containsKey(index);
  String? get errorMessage => _errorMessage;

  Iterable<int> get _addableIndices sync* {
    for (var i = 0; i < _results.length; i++) {
      if (_results[i].analysisResult.ripenessStage != RipenessStage.rotten) {
        yield i;
      }
    }
  }

  bool get savedToHarvest {
    final addable = _addableIndices.toList();
    if (addable.isEmpty) return false;
    return addable.every(_savedIndices.contains);
  }

  /// UC400 basic flow: capture a photo for batch analysis.
  Future<void> captureFromCamera() => _pickImage(ImageSource.camera);

  /// UC400 alt: upload an existing image from the gallery.
  Future<void> pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    _capturedImage = File(picked.path);
    _status = BatchSessionStatus.imageSelected;
    notifyListeners();

    await _runBatchAnalysis();
  }

  Future<void> _runBatchAnalysis() async {
    final image = _capturedImage;
    if (image == null) return;

    _status = BatchSessionStatus.processing;
    notifyListeners();

    final outcome = await _batchService.processBatchImage(
      image: image,
      userId: _userId,
    );

    switch (outcome) {
      case BatchSuccess(:final scan, :final results):
        _scan = scan;
        _results = results;
        _status = BatchSessionStatus.success;
        break;
      case BatchNoFruitDetected():
        _status = BatchSessionStatus.noFruitDetected;
        break;
      case BatchFailed(:final message):
        _errorMessage = message;
        _status = BatchSessionStatus.error;
        break;
    }

    notifyListeners();
  }

  /// UC401: user taps a fruit in the batch list to view its detail.
  void selectFruit(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// UC401: return from detail view back to the batch list.
  void clearSelection() {
    _selectedIndex = null;
    notifyListeners();
  }

  void markSavedAt(int index) {
    if (index < 0 || index >= _results.length) return;
    if (_savedIndices.add(index)) notifyListeners();
  }

  void markAllSavedToHarvest() {
    final before = _savedIndices.length;
    _savedIndices.addAll(_addableIndices);
    if (_savedIndices.length != before) notifyListeners();
  }

  void applyCorrection(int index, RipenessStage correctedStage) {
    if (index < 0 || index >= _results.length) return;

    final result = _results[index];
    final current = result.analysisResult;
    if (current.ripenessStage == correctedStage &&
        !_originalStages.containsKey(index)) {
      return;
    }

    _originalStages.putIfAbsent(index, () => current.ripenessStage);

    if (_originalStages[index] == correctedStage) {
      _originalStages.remove(index);
    }

    final corrected = _originalStages.containsKey(index);

    _results[index] = FruitResult(
      fruit: result.fruit,
      identificationConfidence: result.identificationConfidence,
      analysisResult: AnalysisResult(
        resultId: current.resultId,
        ripenessStage: correctedStage,
        confidenceScore: corrected ? 1.0 : current.confidenceScore,
        justification: corrected
            ? 'Corrected by you from '
            '${_label(_originalStages[index]!)} '
            'to ${_label(correctedStage)}.'
            : current.justification,
        fruitId: current.fruitId,
      ),
      prediction: _shelfLifePredictor.predict(
        predictId: result.prediction.predictId,
        fruitType: result.fruit.type,
        ripenessStage: correctedStage,
        resultId: current.resultId,
      ),
    );

    notifyListeners();
  }

  String _label(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 'Unripe',
    RipenessStage.ripe => 'Ripe',
    RipenessStage.overripe => 'Overripe',
    RipenessStage.rotten => 'Rotten',
  };

  void reset() {
    _status = BatchSessionStatus.idle;
    _capturedImage = null;
    _scan = null;
    _results = [];
    _originalStages.clear();
    _savedIndices.clear();
    _selectedIndex = null;
    _errorMessage = null;
    notifyListeners();
  }
}