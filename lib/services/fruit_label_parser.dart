import '../core/enums.dart';

class ParsedFruitLabel {
  final String fruitType;
  final RipenessStage? ripenessStage;

  const ParsedFruitLabel({required this.fruitType, this.ripenessStage});
}

ParsedFruitLabel parseFruitLabel(String rawLabel) {
  final normalized = rawLabel.trim();

  for (final stage in RipenessStage.values) {
    final suffix = ' ${_stageWord(stage)}';
    if (normalized.toLowerCase().endsWith(suffix.toLowerCase())) {
      final species =
      normalized.substring(0, normalized.length - suffix.length).trim();
      return ParsedFruitLabel(fruitType: species, ripenessStage: stage);
    }
  }

  return ParsedFruitLabel(fruitType: normalized, ripenessStage: null);
}

String _stageWord(RipenessStage stage) => switch (stage) {
  RipenessStage.unripe => 'Unripe',
  RipenessStage.ripe => 'Ripe',
  RipenessStage.overripe => 'Overripe',
  RipenessStage.rotten => 'Rotten',
};