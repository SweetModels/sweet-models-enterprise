class FinancialCandle {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  FinancialCandle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory FinancialCandle.fromJson(Map<String, dynamic> json) {
    return FinancialCandle(
      date: json['date'] as String,
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
  };

  @override
  String toString() =>
      'FinancialCandle(date: $date, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
}
