// Normalized bounding box
class BoundingBox {
  final double x; // left edge
  final double y; // top edge
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromMap(Map<String, dynamic> map) => BoundingBox(
    x: (map['x'] as num).toDouble(),
    y: (map['y'] as num).toDouble(),
    width: (map['width'] as num).toDouble(),
    height: (map['height'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };
}

class Fruit {
  final String fruitId;
  final String type;
  final BoundingBox boundingBox;
  final String scanId;

  const Fruit({
    required this.fruitId,
    required this.type,
    required this.boundingBox,
    required this.scanId,
  });

  factory Fruit.fromMap(Map<String, dynamic> map) => Fruit(
    fruitId: map['fruitId'] as String,
    type: map['type'] as String,
    boundingBox:
    BoundingBox.fromMap(map['boundingBox'] as Map<String, dynamic>),
    scanId: map['scanId'] as String,
  );

  Map<String, dynamic> toMap() => {
    'fruitId': fruitId,
    'type': type,
    'boundingBox': boundingBox.toMap(),
    'scanId': scanId,
  };
}