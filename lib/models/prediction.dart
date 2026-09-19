class Prediction {
  final String predictId;
  final int daysUntilSpoil;
  final DateTime bestConsumeDate;
  final String resultId;

  const Prediction({
    required this.predictId,
    required this.daysUntilSpoil,
    required this.bestConsumeDate,
    required this.resultId,
  });

  factory Prediction.fromMap(Map<String, dynamic> map) => Prediction(
    predictId: map['predictId'] as String,
    daysUntilSpoil: map['daysUntilSpoil'] as int,
    bestConsumeDate: DateTime.parse(map['bestConsumeDate'] as String),
    resultId: map['resultId'] as String,
  );

  Map<String, dynamic> toMap() => {
    'predictId': predictId,
    'daysUntilSpoil': daysUntilSpoil,
    'bestConsumeDate': bestConsumeDate.toIso8601String(),
    'resultId': resultId,
  };
}