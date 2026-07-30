class WasteSummaryRow {
  const WasteSummaryRow({
    required this.fruitName,
    required this.period,
    required this.consumedCount,
    required this.discardedCount,
    required this.weightSavedG,
    required this.weightWastedG,
  });

  final String fruitName;

  final DateTime period;

  final int consumedCount;
  final int discardedCount;
  final double weightSavedG;
  final double weightWastedG;

  int get totalCount => consumedCount + discardedCount;

  factory WasteSummaryRow.fromMap(Map<String, dynamic> map) => WasteSummaryRow(
    fruitName: map['fruit_name'] as String? ?? 'Unknown',
    period: DateTime.parse(map['period'] as String),
    consumedCount: (map['consumed_count'] as num?)?.toInt() ?? 0,
    discardedCount: (map['discarded_count'] as num?)?.toInt() ?? 0,
    weightSavedG: (map['weight_saved_g'] as num?)?.toDouble() ?? 0,
    weightWastedG: (map['weight_wasted_g'] as num?)?.toDouble() ?? 0,
  );
}

class FruitTally {
  const FruitTally({
    required this.fruitName,
    required this.consumedCount,
    required this.discardedCount,
    required this.weightSavedG,
    required this.weightWastedG,
  });

  final String fruitName;
  final int consumedCount;
  final int discardedCount;
  final double weightSavedG;
  final double weightWastedG;

  int get totalCount => consumedCount + discardedCount;

  double? get efficiency =>
      totalCount == 0 ? null : consumedCount / totalCount;
}

class MonthTally {
  const MonthTally({
    required this.period,
    required this.consumedCount,
    required this.discardedCount,
  });

  final DateTime period;
  final int consumedCount;
  final int discardedCount;

  int get totalCount => consumedCount + discardedCount;

  String get shortLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[period.month - 1];
  }

  String get fullLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[period.month - 1]} ${period.year}';
  }
}

class WasteSummary {
  const WasteSummary({
    required this.rows,
    required this.byFruit,
    required this.byMonth,
    required this.totalConsumed,
    required this.totalDiscarded,
    required this.weightSavedG,
    required this.weightWastedG,
    required this.batchScanCount,
    required this.totalScanCount,
  });

  final List<WasteSummaryRow> rows;
  final List<FruitTally> byFruit;
  final List<MonthTally> byMonth;

  final int totalConsumed;
  final int totalDiscarded;
  final double weightSavedG;
  final double weightWastedG;

  final int batchScanCount;
  final int totalScanCount;

  bool get isEmpty => rows.isEmpty;
  int get totalResolved => totalConsumed + totalDiscarded;

  double get weightSavedKg => weightSavedG / 1000;
  double get weightWastedKg => weightWastedG / 1000;

  double? get efficiency =>
      totalResolved == 0 ? null : totalConsumed / totalResolved;

  List<FruitTally> get mostWasted {
    final list = byFruit.where((f) => f.discardedCount > 0).toList()
      ..sort((a, b) => b.discardedCount.compareTo(a.discardedCount));
    return list;
  }

  List<FruitTally> get mostConsumed {
    final list = byFruit.where((f) => f.consumedCount > 0).toList()
      ..sort((a, b) => b.consumedCount.compareTo(a.consumedCount));
    return list;
  }

  factory WasteSummary.fromRows(
      List<WasteSummaryRow> rows, {
        int batchScanCount = 0,
        int totalScanCount = 0,
      }) {
    var consumed = 0;
    var discarded = 0;
    var saved = 0.0;
    var wasted = 0.0;

    final fruitMap = <String, List<WasteSummaryRow>>{};
    final monthMap = <DateTime, List<WasteSummaryRow>>{};

    for (final r in rows) {
      consumed += r.consumedCount;
      discarded += r.discardedCount;
      saved += r.weightSavedG;
      wasted += r.weightWastedG;

      fruitMap.putIfAbsent(r.fruitName, () => []).add(r);
      // Normalise to the first of the month so buckets group.
      final key = DateTime(r.period.year, r.period.month);
      monthMap.putIfAbsent(key, () => []).add(r);
    }

    final byFruit = fruitMap.entries.map((e) {
      var c = 0, d = 0;
      var ws = 0.0, ww = 0.0;
      for (final r in e.value) {
        c += r.consumedCount;
        d += r.discardedCount;
        ws += r.weightSavedG;
        ww += r.weightWastedG;
      }
      return FruitTally(
        fruitName: e.key,
        consumedCount: c,
        discardedCount: d,
        weightSavedG: ws,
        weightWastedG: ww,
      );
    }).toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));

    final byMonth = monthMap.entries.map((e) {
      var c = 0, d = 0;
      for (final r in e.value) {
        c += r.consumedCount;
        d += r.discardedCount;
      }
      return MonthTally(period: e.key, consumedCount: c, discardedCount: d);
    }).toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    return WasteSummary(
      rows: rows,
      byFruit: byFruit,
      byMonth: byMonth,
      totalConsumed: consumed,
      totalDiscarded: discarded,
      weightSavedG: saved,
      weightWastedG: wasted,
      batchScanCount: batchScanCount,
      totalScanCount: totalScanCount,
    );
  }

  static WasteSummary get empty => WasteSummary.fromRows(const []);
}