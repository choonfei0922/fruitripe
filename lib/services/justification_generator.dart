import '../core/enums.dart';

class JustificationGenerator {
  static const double lowConfidenceThreshold = 0.60;

  static const Set<String> _knownWeakClasses = {
    'Orange|overripe',
    'Mango|ripe',
    'Melon|unripe',
    'Pear|overripe',
    'Grape|ripe',
    'Banana|rotten',
  };

  static bool isKnownWeak(String fruitType, RipenessStage stage) =>
      _knownWeakClasses.contains('$fruitType|${stage.name}');

  static bool isLowConfidence(double confidence) =>
      confidence < lowConfidenceThreshold;

  /// The main explanation sentence.
  static String generate({
    required String fruitType,
    required RipenessStage stage,
    required double confidence,
  }) {
    final cues = _visualCues(fruitType, stage);
    return 'This $fruitType was classified as ${_stageWord(stage)} because '
        'its external characteristics, including $cues, match the '
        '${_stageWord(stage)} profiles the model was trained on.';
  }

  /// FR 5.3: disclaimer text, or null when none is warranted.
  static String? disclaimer({
    required String fruitType,
    required RipenessStage stage,
    required double confidence,
  }) {
    if (isLowConfidence(confidence)) {
      return 'Confidence is low for this scan. Lighting, angle, or partial '
          'occlusion can affect accuracy — consider rescanning with the '
          'fruit fully in frame under even lighting.';
    }
    if (isKnownWeak(fruitType, stage)) {
      return 'The model is less reliable for $fruitType at the '
          '${_stageWord(stage)} stage than for other combinations. Treat '
          'this result as indicative rather than definitive.';
    }
    return null;
  }

  static String _visualCues(String fruitType, RipenessStage stage) {
    final byFruit = _cues[fruitType];
    if (byFruit != null && byFruit[stage] != null) return byFruit[stage]!;
    return _genericCues[stage]!;
  }

  static String _stageWord(RipenessStage stage) => switch (stage) {
    RipenessStage.unripe => 'unripe',
    RipenessStage.ripe => 'ripe',
    RipenessStage.overripe => 'overripe',
    RipenessStage.rotten => 'rotten',
  };

  static const Map<RipenessStage, String> _genericCues = {
    RipenessStage.unripe:
    'firm surface texture and colouring that has not yet developed',
    RipenessStage.ripe:
    'even colour distribution and smooth, unblemished surface texture',
    RipenessStage.overripe:
    'darkened colouring and softened surface texture',
    RipenessStage.rotten:
    'extensive discolouration, surface breakdown and visible decay',
  };

  static const Map<String, Map<RipenessStage, String>> _cues = {
    'Banana': {
      RipenessStage.unripe: 'green skin colouring and firm, angular edges',
      RipenessStage.ripe: 'uniform yellow colouring with minimal spotting',
      RipenessStage.overripe:
      'widespread brown speckling across a deepening yellow skin',
      RipenessStage.rotten: 'blackened skin and collapsed, sunken areas',
    },
    'Apple': {
      RipenessStage.unripe: 'pale or green-tinged skin and firm surface',
      RipenessStage.ripe: 'deep saturated colouring and a glossy, taut skin',
      RipenessStage.overripe: 'dulled colouring and wrinkling around the skin',
      RipenessStage.rotten: 'brown bruised patches and soft, broken skin',
    },
    'Orange': {
      RipenessStage.unripe: 'green patches and a tight, firm rind',
      RipenessStage.ripe: 'even orange colouring across a smooth rind',
      RipenessStage.overripe: 'softening rind with dulled, uneven colouring',
      RipenessStage.rotten: 'mould growth and collapsed, discoloured rind',
    },
    'Grape': {
      RipenessStage.unripe: 'pale colouring and firm, tightly attached berries',
      RipenessStage.ripe: 'deep even colouring with a light surface bloom',
      RipenessStage.overripe: 'wrinkling berries and browning at the stems',
      RipenessStage.rotten: 'shrivelled berries and visible mould',
    },
    'Mango': {
      RipenessStage.unripe: 'green skin and a firm, unyielding surface',
      RipenessStage.ripe: 'yellow-red blushing and slight give in the skin',
      RipenessStage.overripe: 'darkened patches and heavily wrinkled skin',
      RipenessStage.rotten: 'blackened areas and seeping surface breakdown',
    },
    'Melon': {
      RipenessStage.unripe: 'pale rind colouring and a firm, smooth surface',
      RipenessStage.ripe: 'developed netting or colouring across the rind',
      RipenessStage.overripe: 'soft patches and yellowing of the rind',
      RipenessStage.rotten: 'sunken, discoloured areas and surface mould',
    },
    'Peach': {
      RipenessStage.unripe: 'firm surface and underdeveloped red blushing',
      RipenessStage.ripe: 'deep red-orange blushing over a yielding surface',
      RipenessStage.overripe: 'browning patches and heavily softened skin',
      RipenessStage.rotten: 'extensive brown rot and broken skin',
    },
    'Pear': {
      RipenessStage.unripe: 'green colouring and a hard, firm surface',
      RipenessStage.ripe: 'lightened colouring with slight give near the stem',
      RipenessStage.overripe: 'browning patches and softening across the body',
      RipenessStage.rotten: 'dark sunken areas and surface breakdown',
    },
  };
}