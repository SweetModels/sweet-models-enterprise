import 'package:intl/intl.dart';

class ModelHomeStats {
  final double todayEarningsCop;
  final double weekEarningsCop;
  final double monthEarningsCop;
  final double activePoints;

  const ModelHomeStats({
    required this.todayEarningsCop,
    required this.weekEarningsCop,
    required this.monthEarningsCop,
    required this.activePoints,
  });

  factory ModelHomeStats.fromJson(Map<String, dynamic> json) {
    return ModelHomeStats(
      todayEarningsCop: (json['today_earnings_cop'] as num?)?.toDouble() ?? 0,
      weekEarningsCop: (json['week_earnings_cop'] as num?)?.toDouble() ?? 0,
      monthEarningsCop: (json['month_earnings_cop'] as num?)?.toDouble() ?? 0,
      activePoints: (json['active_points'] as num?)?.toDouble() ?? 0,
    );
  }

  String formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);
    return format.format(value);
  }
}
