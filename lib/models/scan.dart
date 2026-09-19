class Scan {
  final String scanId;
  final String imageUrl;
  final DateTime timestamp;
  final String userId;

  const Scan({
    required this.scanId,
    required this.imageUrl,
    required this.timestamp,
    required this.userId,
  });

  factory Scan.fromMap(Map<String, dynamic> map) => Scan(
    scanId: map['scanId'] as String,
    imageUrl: map['imageUrl'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    userId: map['userId'] as String,
  );

  Map<String, dynamic> toMap() => {
    'scanId': scanId,
    'imageUrl': imageUrl,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
  };
}