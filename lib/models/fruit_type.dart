class FruitType {
  const FruitType({
    required this.fruitTypeId,
    required this.name,
    required this.defaultShelfLifeDays,
    required this.averageWeightG,
    required this.isSupported,
    this.scientificName,
  });

  final int fruitTypeId;
  final String name;
  final String? scientificName;

  final int defaultShelfLifeDays;

  final double averageWeightG;

  final bool isSupported;

  factory FruitType.fromMap(Map<String, dynamic> map) => FruitType(
    fruitTypeId: map['fruit_type_id'] as int,
    name: map['name'] as String,
    scientificName: map['scientific_name'] as String?,
    defaultShelfLifeDays: (map['default_shelf_life_days'] as num).toInt(),
    averageWeightG: (map['average_weight_g'] as num).toDouble(),
    isSupported: map['is_supported'] as bool? ?? true,
  );

  Map<String, dynamic> toInsertMap() => {
    'name': name,
    'scientific_name': scientificName,
    'default_shelf_life_days': defaultShelfLifeDays,
    'average_weight_g': averageWeightG,
    'is_supported': isSupported,
  };

  @override
  String toString() => 'FruitType($fruitTypeId, $name)';
}